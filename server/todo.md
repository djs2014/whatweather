- check if garmin weather changed
- get garmin data

- onbackground
- convert incoming data to weather data

- check data
    - same start hour
    - skip if hour is passed

- process alerts

- display based on prio /GarminFirst OWMFirst Garmin OWM
- first = 
- second (condition/rain only)


optimization
hourly => [[timestamp, val1, val2, ... x14], [timestamp, val1, ...], ...]

// Highly Optimized Structure containing the EXACT same data
var optimizedWeatherData = {
    :dt       => [1780941600, 1780945200, 1780948800, ...], // 9 items
    :humidity => [75, 79, 83, ...],                         // 9 items
    :rain     => [0.150000, 2.730000, 0.870000, ...],       // 9 items
    // ... repeat for the other metrics you use
};



Optimization 2: Use Symbols (:key) instead of Strings ("key")

In your log, your dictionary keys are strings:
"current" => {...}, "hourly" => [...]

In Monkey C, strings take up significant memory because they are treated as full objects. If you change your keys to Symbols (prefixed with a colon :), they are compiled as tiny 4-byte integers.

Change this:
Codefragment

var lat = current["lat"];

To this:
Codefragment

var lat = current[:lat];



How to implement this in your onBackgroundData

To keep your memory perfectly clean, do the optimization translation right as you pull it from storage, then immediately null out the raw data so the internal garbage collector can instantly reclaim that memory before the function ends.


function onBackgroundData(data as Application.PersistableType) as Void {
    if (data instanceof Lang.Number && data == 200) {
        
        // 1. Grab the raw, heavy data
        var rawData = Storage.getValue("latestOWMResponse");
        Storage.deleteValue("latestOWMResponse");
        
        if (rawData != null) {
            // 2. Initialize a flat structure using Symbols
            var flatData = {
                :lat => rawData["current"]["lat"],
                :lon => rawData["current"]["lon"],
                :tz_offset => rawData["current"]["tz_offset"],
                // Initialize empty arrays for your hourly metrics
                :hr_dt => [],
                :hr_humidity => [],
                :hr_rain => [] // Add an array for each of the 14 fields you need
            };
            
            // 3. Unpack the multi-dimensional array into flat parallel arrays
            var hourly = rawData["hourly"];
            if (hourly != null) {
                for (var i = 0; i < hourly.size(); i++) {
                    var hrRecord = hourly[i];
                    flatData[:hr_dt].add(hrRecord[0]);
                    flatData[:hr_humidity].add(hrRecord[1]);
                    flatData[:hr_rain].add(hrRecord[11]);
                    // ... fill out the rest of your 14 fields here
                }
            }
            
            // 4. Assign the optimized flat data to your global variable
            $.gIncomingWeatherData = flatData;
            
            // 5. Explicitly break references to the raw data so the OS cleans it up
            rawData = null;
            hourly = null;
        }
    }
    
    // WatchUi.requestUpdate(); // Leave this commented out until the crash stops!
} 

By flattening the arrays and switching your dictionary keys to symbols (:la instead of "lat"), you will likely clear up an extra 10KB to 15KB of RAM. When your function exits, your free memory will be closer to 30KB instead of 16KB, giving the Edge 1040 firmware the breathing room it needs to avoid freezing!


loop index i
var temp = $.gIncomingWeatherData[:hr_temp][i];