show time perc > x + rain > 0

refactor
ow only -> not load garmin data
show alert
if not large field -> bar with alert (beep) for x seconds
large field -> show alert for x seconds
swipe -> not large field is handled true


  - relative wind
  - big array only
- less memory?
- less computation
- relative wind direction on small field
- point object -> kan weg?
- profile 
- 
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
    // - pressure sealevel
    
    - 
    - @@todo showWeatherAlerts

  - Extra information
    - showInfoLargeField Large field (enum)
    - showInfoSmallField Small field (enum)
    - showInfoWideField Small field (enum)
      - show wind
      - show wind relative
    - 
    - Tiny field (enum)
      - - winddirection relative (big image)
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


-------------------------
- onCompute - 
- onLayout - calc dimensions
- onBackgroundData - new / merge data check weather alerts 
- onPositionChanged - do relevant stuff related to position
- onMinutePassed 
- show time in bars when paused

- comfort: kleur groen is warmer maar is toch kouder 
  - 10 douw + 23 graden1025  en 19 graden 1025
- toast message ??

- toast for alerts + beep
- first call, ignore gps and use last location
  - make it a on device setting
- show if there is actual rain (per hour)
  - striped bar in blue bar?
  - test exceed mem proxy
- minutely
-> when rain first hour.
-> shift the mm graphic per minute
- auto adjust #bars with available hourly forecast
- 

- show owm weather alert
  - enable 
    - activity profiles - select profile - alerts - add connect iq - what weather
    - NB. what weather datafield should be in this profile

????
alerts:
minutely text color night mode

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

https://api.castlephoto.info/owm_one
http://localhost:4000/owm_one
ams 52.188950, 4.549666
lasvegas 36.16373271614203, -115.1262537886411


# Todo
	- Refactor the code, etc.	
	- BUG - one column + weather alarm -> continue beep
	- At initial start -> position is 0 (calc distance is then 5840km)? 			
	

vs code end of line --> LF
git -> CRLF settings
https://stackoverflow.com/questions/1967370/git-replacing-lf-with-crlf

  – git config --system core.autocrlf false            # per-system solution
  – git config --global core.autocrlf false            # per-user solution
  – git config --local core.autocrlf false              # per-project solution



// Removed:
  // function checkFeatures() as Void {
  //   mCreateColors = Graphics has :createColor;
  //   try {
  //     mUseSetFillStroke = Graphics.Dc has :setStroke;
  //     if (mUseSetFillStroke) {
  //       mUseSetFillStroke = Graphics.Dc has :setFill;
  //     }
  //   } catch (ex) {
  //     ex.printStackTrace();
  //   }
  // }
  background
  // !! Do not convert responseData to string (println etc..) --> gives out of memory
                //System.println(responseData);   --> gives out of memory
                // var data = responseData as String;  --> gives out of memory