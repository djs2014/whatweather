import Toybox.Lang;
import Toybox.System;

const DEBUG_DETAILS = false;
const SHOW_WIND_NOTHING = 0;
const SHOW_WIND_METERS = 1;
const SHOW_WIND_KILOMETERS = 2;
const SHOW_WIND_BEAUFORT = 3;

const SHOW_INFO_NOTHING = 0;
const SHOW_INFO_TIME_Of_DAY = 1;
const SHOW_INFO_AMBIENT_PRESSURE = 2;
const SHOW_INFO_SEALEVEL_PRESSURE = 3;
const SHOW_INFO_DISTANCE = 4;
const SHOW_INFO_RELATIVE_WIND = 5;

const COLOR_CLOUDS = 0xCCD1D1; 
const COLOR_CLOUDS_NIGHT = 0xBFC9CA; 
const COLOR_WHITE_BLUE = 0xE1E5F8;
const COLOR_WHITE_GREEN = 0xE6ffE5;   // 0x8DDA8D;
const COLOR_WHITE_YELLOW = 0xFFFFE1;  // 0xFFFFAA;
const COLOR_WHITE_ORANGE = 0xFFE9E1;  // 0xF1AC4A;
const COLOR_MM_RAIN =  0x154360; // DARK_BLUE_10

var _showCurrentForecast as Lang.Boolean = true;
var _maxHoursForecast as Lang.Number = 8;
var _showMinuteForecast as Lang.Boolean = true;
var _alertLevelPrecipitationChance as Lang.Number = 70;
var _showCurrentWind as Lang.Boolean = true;
var _showRelativeWindFirst as Lang.Boolean = true;
var _observationTimeDelayedMinutesThreshold as Lang.Number = 30;
var _showClouds as Lang.Boolean = true;

var _showUVIndex as Lang.Boolean = true;
var _maxUVIndex as Lang.Number = 20;

var _showInfoOneField as Lang.Number = SHOW_INFO_NOTHING;
var _showInfoLargeField as Lang.Number = SHOW_INFO_NOTHING;
var _showInfoWideField as Lang.Number = SHOW_INFO_NOTHING;
var _showInfoSmallField as Lang.Number = SHOW_INFO_TIME_Of_DAY;

var _showWind as Lang.Number = SHOW_WIND_BEAUFORT;
var _showTemperature as Lang.Boolean = true;
var _showRelativeHumidity as Lang.Boolean = true;
var _showWeatherCondition as Lang.Boolean = true;
var _showComfortZone as Lang.Boolean = true;
var _showPressure as Lang.Boolean = true;
var _showDewpoint as Lang.Boolean = true;

var _maxTemperature as Lang.Number = 50; // celcius
var _maxPressure as Lang.Number = 1080;
var _minPressure as Lang.Number = 870;
var _maxMMRainPerHour as Lang.Number = 10;


var _alertLevelUVi as Lang.Number = 6;
var _alertLevelRainMMfirstHour as Lang.Float = 0.2f;
var _alertLevelRainMMHour as Lang.Float = 0.2f;
var _alertLevelDewpoint as Lang.Number = 19;
var _alertWindIn as Lang.Number = SHOW_WIND_BEAUFORT;
var _alertLevelWindSpeed as Lang.Float = 5.0f;    
var _alertLevelWindGust as Lang.Number = 2;
var _weatherDataSource as WeatherSource = wsOWMFirst;
var _soundMode as Number = 1;

 (:typecheck(disableBackgroundCheck))
function getWeatherConditionText(condition as Lang.Number?) as Lang.String? {
  if (condition == null) {
    return null;
  }
  var key = (condition as Lang.Number);

  if (key < $._weatherDescriptions.size()) {
    return $._weatherDescriptions[key] as Lang.String;
  }
  return null;
}