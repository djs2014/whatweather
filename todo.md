check start hour weather
icon thunder -> bigger?
(:extendedCode) 

dissable moon icon when evening start -> other indication
test met 1 uur 1040
test hailstone draw

monkeyc compilerOptions = -O1

sync bgservicehandler

use logInfo
check null checks etc.

thunder icon higher
text alternate row 

memory check background
test onbg data -> set data to null, still crash?

show hours garmin
7 | 7 | 8| 9 .. 
-> waarom 2x 7? --> observatie tijd kolommen met garmin weather?
ook met owm? gelukkig niet :-)

Egde 1040 (start activity) na eerste background req -> crash, activity paused.
restart edge dan gaat alles ok.

Math.rand() % 0 is invalid operation

In Monkey C, the / operator between a Number and a Number (like width / 2) can sometimes result in a Float depending on the SDK version and compiler settings.

----
hide stats after x seconds if active only show time to next
optimize drawWindArrow
 darkblue color -> make it icy color on dark background
ok TEST: weather alert show details on alert
- wind / icon / text?
migrate to azure functions
- poi / weather
alert wind -> font white


curl https://ishetglad.nl/includes/render.php?address_from=madrid&geocoor=52.3528505%2C4.8534054

{"lat_start":0,"lon_start":0,"temp":27,"temp_min":27,"temp_max":27,"weather":null,"humidity":77,"warning":"","final":"Nee! Het is niet glad"}

52.3516012130595, 4.859189163397057

https://ishetglad.nl/includes/render.php?geolocation=1&geocoor=52.3516012130595%2C4.859189163397057

post form test


https://ishetglad.nl/includes/render.php?address_from=madrid&geocoor=52.3528505%2C4.8534054

{"lat_start":0,"lon_start":0,"temp":27,"temp_min":27,"temp_max":27,"weather":null,"humidity":77,"warning":"","final":"Nee! Het is niet glad"}
no api key check
kan al meteen als owm / owmfirst / garminfirst gekozen is, hoeft niet in background
font comfort toon uren -> indien < dewpoint maak kleur iets donkerder, > dewpoint  text iets lichter
TODO fix 1030 -> mmrain current
TODO readme update menu settings etc.

Note: garmin weather -> when update date shift 1 day previous bug in simulator (linux)
sync locations / numericinput --> to other projects  
- show weather icons
- show weather text
  - check y pos calculation its same as wind icon now
---------
info1/ weathercolumn
info2
..
wind / dashes under weathercolumn
condition 
text
hours

---------

 - mShowComfortBorders 
- onlayout --> get the right number of columns
- set dash underline height -> indicatie alert aanwezig 
==> dan column hoogte kleiner ..
- alleen wanneer alert aanwezig?

- alert wind icon licht rood.


- when on change weather
  - check alarm + build weather data to show
  - text / font / values
  - indicate alerts
  - if show details when alert then build all
  - rewrite loop drawing current and forecast
    - one loop
    [0] is current
    [1] .. forecast
      - draw everything per column (also temp/wind/dewpoint/etc)
      - one function to draw one column (current and forecastitem same properties)

  - cache wobble line      
  - use profiler to optimize 
  - cache weather icons on first use -> only if displayed

- wind icons
  - minimal -> small arrow 

- First rain -> status info verbergd regen op 59 min etc..

- add windfeel temp?  (temperature / wind feel temperature)
- underline bigger when has alert / rain mm in weather column
- option to hide status info?
- memory should be < 100
- rain first hour -> current condition color

-----------
openmeteo -> counter save to txt / per month

http://localhost:7071/api/weather and testscenario 1
https://owm.castlephoto.info/owm_one

test with wind speed 13.8888888889 m/s == 50 mk/h

??
slippery road alert
 - temp -10 -- 2
 - humidity > 80%
 - rainy/snowy perc 
 - prev hour wet and <2, current 2> 
 - prev day wet 

historical data: https://openweathermap.org/api/one-call-3#history

historical data: https://open-meteo.com/
curl "https://api.open-meteo.com/v1/forecast?latitude=52.3221&longitude=4.89532&past_days=1&forecase_days=0&hourly=temperature_2m,relative_humidity_2m,rain"

Check for ijzel
https://open-meteo.com/en/docs#hourly=dew_point_2m,soil_temperature_0cm,soil_moisture_0_to_1cm,freezing_level_height&daily=&timezone=Europe%2FBerlin&forecast_days=1

https://www.weeronline.nl/nieuws/hoe-ontstaat-ijzel-en-wanneer-kunnen-we-dit-verwachten
1: IJzel kan voorkomen bij intredende dooi na een vorstperiode.Vaak valt er eerst sneeuw, maar wanneer de lucht zachter wordt gaat de sneeuw over in regen. 
Zolang het wegdek bevroren is kan regen ijzel veroorzaken. 
--> past days: cold below zero + current above zero and rain
2: Regen kouder dan het vriespunt  
De zachtere lucht arriveert meestal als eerste hoger in de lucht. En als de lucht daaronder nog onder nul is kan regen afkoelen tot beneden het vriespunt. Zodra dit gebeurt zal de druppel niet meteen bevriezen, maar nog een tijd vloeibaar blijven. We spreken dan van onderkoelde regen. Wanneer deze ijskoude druppels iets raken vormt meteen ijs.

----------------
counter 10000 per dag
open-meteo -> convert naar Garmin data (geen api key nodig dan.)



x wide field -> regen per uur -> underline oid indicatie
toaste
or display
or both
clear alert mem after x minutes
option disable alerts -> not in json
-- hidden function drawWind( radius parameter refact

mm 1st hour
---|..

wind alert
in beauf, mps, kmh, mph
circle width wind icon
after update showwindin -> update other item -> sublabeltext update units

check mm/h in minutely => sum of it
0.1 ==> correct or

optimize calculations 
cache weather... 
https://www.htmlcsscolor.com/hex/8E7CC3

"o" -> 'o' ??
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
 52.35424867721783, 4.832538735395953
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

BUG - one column + weather alarm -> continue beep