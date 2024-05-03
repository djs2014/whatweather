optimize calculations 
cache weather... 
https://www.htmlcsscolor.com/hex/8E7CC3

Implement:
// o (one), l (large), w (wide), s (small)
// o (one), l (large), w (wide), s (small)
function getDisplaySize(width as Integer, height as Integer) as String {
  var display = "s";

  if (width >= 246) {
    display = "w";
    if (height >= 322) {
      display = "o";
    } else if (height >= 100) {
      display = "l";
    }
  }

  return display;
}



- deploy owm.js // @@ 
wind gust -> border around arrow
  https://en.wikipedia.org/wiki/Wind_gust
 When the maximum speed exceeds the average speed by 10 to 15 knots (5.1 - 7.7 m/s), the term gusts is used while strong gusts is used for departure of 15 to 25 knots (-12 m/s), and violent gusts when it exceeds 25 knots.[4]
ex:
  "wind_speed": 5.87,
  "wind_gust": 13.71,
    diff == 9 m/s ==> `normal` gust 
alert of wind_gust diff with wind_speed
    1 gusts/2 strong gusts/3 violent gusts

var mySettings = System.getDeviceSettings();
settings.tonesOn

compress ,0.0, -> ,, 

update documentation: 
- menu
- owm alerts
    large field -> show alert for x seconds
    swipe -> not large field is handled true
- relative wind
  - rel wind+ -> effective wind speed?

- point object -> kan weg?
- profile 
 
- show mem on screen? if debug -> crash
- on device settings
  - Proxy
    - x minimalGPSquality
    - x checkIntervalMinutes
    - openWeatherAPIVersion OWM api version
    - openWeatherAPIKey OWM api key -> property
    - openWeatherProxy Proxy url > property + default
    - openWeatherProxyAPIKey Proxy api key > property  + default

  - Show Weather
    - x weatherDataSource Weather source      
    - x showCurrentForecast current hour 
    - x showMinuteForecast Rain first hour
    - x maxHoursForecast hours of forecast
    - x showClouds Clouds
    - x showWind wind      
    - x showCurrentWind Current wind -> on small field
    - @@todo wind gust
    - x showUVIndex uv index
    - x showTemperature temperature
    - x showRelativeHumidity relative humidity
    - x showPressure Show pressure
    - x showDewpoint Show dewpoint
    - x showComfortZone comfort zone
    - x showWeatherCondition weather condition
    - 

  - Extra information
    - x showInfoLargeField Large field (enum)
    - x showInfoSmallField Small field (enum)
    - x showInfoWideField Small field (enum)
      - show wind relative
  - Alert levels
    - x alertLevelPrecipitationChance Precipitation chance
      - x add min/max to picker
    - x alertLevelUVi UV index
    - x alertLevelRainMMfirstHour
    - x alertLevelWindSpeed Wind beaufort
    - x alertLevelDewpoint dewpoint celcius    
    Advanced
    - -- minTemperature min temp C
    - x maxTemperature max temp C
    - x maxUVIndex max uv index
    - x maxPressure max pressure hPa
    - x minPressure min pressure hPa
  - Comfort region
    - x comfortHumidityMin min humidity %
    - x comfortHumidityMax max humidity %
    - x comfortTempMin min temperature C
    - x comfortTempMax max temperature C
  - Demo
    - Demo one time -> 
    - testScenario Scenarios
      - rainy
      - alert
      - rain first hour
      - comfort -> high humidity / dew point


- comfort: kleur groen is warmer maar is toch kouder 
  - 10 douw + 23 graden 1025  en 19 graden 1025
- toast message ??

- current hour == is for whole day ? default off..
  
x handle OWM error -> {json}
- OWM response error --> error code 200 met payload {error: {"cod":"400","message":"wrong latitude"} }
- code must be 200, else no data
- check lat lng valid in onbackground service before call

Added (:typecheck(false)) because of compiler bugs in strict mode.

- show alerts play sound?
- 
TL;DR;
 - don't use Toybox.Communications in import for foreground app (even if it is not used)

optimize	
    - radar -> offset to left x px

https://owm.castlephoto.info/owm_one
http://localhost:4000/owm_one
ams 52.188950, 4.549666
lasvegas 36.16373271614203, -115.1262537886411


	- BUG - one column + weather alarm -> continue beep
	



