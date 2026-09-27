NodeProxy for What Weather


node  app.js
with debug
node --inspect app.js

VS Code: Open the command palette (Ctrl+Shift+P / Cmd+Shift+P), choose Debug: Attach to Node Process, and select your running app.js process.




keys/apikeys.json
```
{
    "keys" : [
        "326159126593186539165392651263"
    ]
}
```


parseOWMdata

if slippery
- get historyData => cache per lat.lon 1 dec
- get season
- loop for hours
  -  calc slippery level + reason-code

```
const axios = require('axios');

// Simple in-memory cache (replace with Redis in production)
const cache = new Map();

/**
 * Rounds coordinate to 2 decimal places (~1.1 km grid precision)
 */
function normalizeCoord(coord) {
  return Number(Math.round(coord + 'e2') + 'e-2').toFixed(2);
}

/**
 * Generates a standard cache key for a specific day and location
 */
function getCacheKey(lat, lon, dateStr) {
  return `weather:history:${normalizeCoord(lat)}:${normalizeCoord(lon)}:${dateStr}`;
}

/**
 * Fetches historical data for a past day, serving from cache if available.
 */
async function getHistoricalDayWeather(lat, lon, date, apiKey) {
  const dateStr = date.toISOString().split('T')[0]; // YYYY-MM-DD
  const cacheKey = getCacheKey(lat, lon, dateStr);

  // 1. Check Cache
  if (cache.has(cacheKey)) {
    return cache.get(cacheKey);
  }

  // 2. Fetch from OWM Time Machine API if not cached
  const timestamp = Math.floor(date.getTime() / 1000);
  const url = `https://api.openweathermap.org/data/3.0/onecall/timemachine?lat=${lat}&lon=${lon}&dt=${timestamp}&appid=${apiKey}&units=metric`;

  try {
    const response = await axios.get(url);
    const dayData = response.data.hourly || [];

    // Extract minimal required fields to save memory
    const trimmedData = dayData.map(entry => ({
      dt: entry.dt,
      temp: entry.temp,
      humidity: entry.humidity,
      dew_point: entry.dew_point,
      rain: entry.rain ? entry.rain['1h'] || 0 : 0,
      snow: entry.snow ? entry.snow['1h'] || 0 : 0
    }));

    // 3. Save to Cache (Immutable past days get infinite/long TTL)
    cache.set(cacheKey, trimmedData);
    return trimmedData;
  } catch (error) {
    console.error(`Cache fetch failed for ${cacheKey}:`, error.message);
    throw error;
  }
}
```


Base Parameters
Calls per execution cycle: 5 API calls (1 forecast/current call + 4 historical calls)

Frequency: Every 5 minutes = 12 calls per hour per endpoint

Execution window: 8 hours per day

Calculation Metric,Formula,Total API Calls
Calls per hour,5 calls×12 executions/hr,60 calls
Calls per day (8 hours),60 calls/hr×8 hours,480 calls
Calls per month (30 days),480 calls/day×30 days,"14,400 calls"
Calls per month (31 days),480 calls/day×31 days,"14,880 calls"

Key Optimization Note
OpenWeatherMap's standard One Call 3.0 subscription includes 1,000 free calls per day.

At 480 calls/day, your usage sits well under the free tier limit if you run this routine for a single location.

Tip to cut usage by up to 80%: Past historical days never change. Instead of re-fetching all 4 historical days every 5 minutes, fetch them once when your app boots, store them in your local cache, and only make the 1 current/forecast call every 5 minutes. That reduces your volume to just 96 calls/day (2,880/month).

```
/**
 * Normalizes coordinates to a ~1.1km grid cell key.
 */
function getGridKey(lat, lon, dateStr) {
  const roundedLat = Number(Math.round(lat + 'e2') + 'e-2').toFixed(2);
  const roundedLon = Number(Math.round(lon + 'e2') + 'e-2').toFixed(2);
  return `history:${roundedLat}:${roundedLon}:${dateStr}`;
}

/**
 * Fetches history only if location has shifted to a new ~1km grid cell.
 */
async function getHistoryForLocation(currentLat, currentLon, historyDates, cache) {
  const historyResults = [];

  for (const dateStr of historyDates) {
    const key = getGridKey(currentLat, currentLon, dateStr);

    if (cache.has(key)) {
      // Use cached historical data for this 1km zone
      historyResults.push(cache.get(key));
    } else {
      // Fetch new location's historical data and store in cache
      const freshData = await fetchOWMHistory(currentLat, currentLon, dateStr);
      cache.set(key, freshData);
      historyResults.push(freshData);
    }
  }

  return historyResults;
}
```

Key Takeaway
While historical data for Location A remains static once recorded, moving to Location B requires historical data specific to Location B to accurately assess local road wetness and past dry spells.

1. Synchronize Grid Caching with Movement
Because a cyclist can cover 1.5–2.5 km in 5 minutes (at 18–30 km/h), your device will often cross into a new 1.1 km grid cell (0.01° rounding) between background wakeups.

To prevent your backend from slamming the OWM API for historical calls every time the rider moves into a new cell, handle spatial checks on your backend:
```
// Node.js Backend endpoint structure
app.get('/api/slipperiness', async (req, res) => {
  const { lat, lon } = req.query;

  // 1. Snap incoming GPS coordinates to 1.1 km grid
  const gridLat = (Math.round(lat * 100) / 100).toFixed(2);
  const gridLon = (Math.round(lon * 100) / 100).toFixed(2);

  // 2. Check if the past 3 days for this grid cell exist in memory/Redis
  let history = await getCachedHistory(gridLat, gridLon);

  if (!history) {
    // Only fetch from OWM TimeMachine if this grid cell hasn't been cached yet today
    history = await fetchAndCacheOWMHistory(gridLat, gridLon);
  }

  // 3. Always fetch current forecast (or serve from 5-min cache)
  const currentForecast = await getForecast(gridLat, gridLon);

  // 4. Run your slipperiness algorithm
  const slipperiness = EvaluateRoadSlippiness(history, currentForecast);

  res.json({ slipperiness });
});
```

```
import Toybox.Background;
import Toybox.System;
import Toybox.Application.Storage;

(:background)
class WeatherBackgroundDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        // Get current position from Activity
        var info = Activity.getActivityInfo();
        if (info != null && info.currentLocation != null) {
            var latLng = info.currentLocation.toDegrees();
            makeBackendRequest(latLng[0], latLng[1]);
        } else {
            Background.exit(null);
        }
    }

    function makeBackendRequest(lat, lon) {
        var url = "https://your-backend.com/api/slipperiness";
        var params = {
            "lat" => lat.toString(),
            "lon" => lon.toString()
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, method(:onReceive));
    }

    function onReceive(responseCode, data) {
        if (responseCode == 200 && data != null) {
            // Pass payload directly to foreground view via Background.exit()
            Background.exit(data);
        } else {
            Background.exit(null);
        }
    }
}
```


3. API Call Volume with 5-Min Intervals
With your Node.js backend acting as a grid-caching buffer, a typical 3-hour ride across different grid cells looks like this:

Current/Forecast calls: 36 calls per ride (1 call every 5 minutes).

Historical calls: Only triggered once when entering a new 1.1 km grid cell. Over a 60 km ride across 40 unique grid cells, this will be 40 fetches (cached indefinitely for the rest of the day).

Total OWM API calls per ride: ~76 calls total (well under your 1,000 free daily limit).


```
{
  "s": 65,       // Slippiness Score (0-100)
  "l": 2,        // Risk Level (0: Low, 1: Moderate, 2: High, 3: Critical)
  "r": [1, 4]    // Reason Codes (e.g., 1 = First Rain, 4 = Freezing)
}
```
