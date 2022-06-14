import Toybox.Lang;
// import Toybox.Graphics;
import Toybox.System;

const DEBUG_DETAILS = false;
const SHOW_WIND_NOTHING = 0;
const SHOW_WIND_METERS = 1;
const SHOW_WIND_KILOMETERS = 2;
const SHOW_WIND_BEAUFORT = 3;

const SHOW_INFO_NOTHING = 0;
const SHOW_INFO_TIME_Of_DAY = 1;
const SHOW_INFO_TEMPERATURE = 2;
const SHOW_INFO_AMBIENT_PRESSURE = 3;
const SHOW_INFO_SEALEVEL_PRESSURE = 4;

const COLOR_CLOUDS = 0xCCD1D1; 
const COLOR_CLOUDS_NIGHT = 0xBFC9CA; 
const COLOR_WHITE_BLUE = 0xE1E5F8;
const COLOR_WHITE_GREEN = 0xE6ffE5;   // 0x8DDA8D;
const COLOR_WHITE_YELLOW = 0xFFFFE1;  // 0xFFFFAA;
const COLOR_WHITE_ORANGE = 0xFFE9E1;  // 0xF1AC4A;

// @@ Make settings object -> + toString
var _showCurrentForecast as Lang.Boolean = true;
var _maxHoursForecast as Lang.Number = 8;
var _maxMinuteForecast as Lang.Number = 0;
var _alertLevelPrecipitationChance as Lang.Number = 70;
var _showAlertLevel as Lang.Boolean = false;
var _dashesUnderColumnHeight as Lang.Number = 2;
var _showColumnBorder as Lang.Boolean = false;
var _showObservationTime as Lang.Boolean = true;
var _showObservationLocationName as Lang.Boolean = true;
var _observationTimeDelayedMinutesThreshold as Lang.Number = 30;
var _showClouds as Lang.Boolean = true;

var _showUVIndex as Lang.Boolean = true;
var _maxUVIndex as Lang.Number = 20;
var _hideUVIndexLowerThan as Lang.Number = 4;

var _showInfo as Lang.Number = SHOW_INFO_TIME_Of_DAY;
var _showInfo2 as Lang.Number = SHOW_INFO_AMBIENT_PRESSURE;
var _showPrecipitationChanceAxis as Lang.Boolean= true;

var _alertLevelWindSpeed as Lang.Number = 5;
var _showWind as Lang.Number = SHOW_WIND_BEAUFORT;
var _showTemperature as Lang.Boolean = true;
var _showRelativeHumidity as Lang.Boolean = true;
var _showWeatherCondition as Lang.Boolean = true;
var _showComfort as Lang.Boolean = true;
var _showPressure as Lang.Boolean = true;
var _showDewpoint as Lang.Boolean = true;

var _showGlossary as Lang.Boolean = true;

var _alertLevelUVi as Lang.Number = 6;
var _alertLevelRainMMfirstHour as Lang.Number = 5;
var _alertLevelDewpoint as Lang.Number = 19;
var _weatherDataSource as WeatherSource = wsGarminFirst;

function getWeatherConditionText(condition as Lang.Number?) as Lang.String? {
  if (condition == null) {
    return null;
  }
  var key = (condition as Lang.Number).toString();

  if ($._weatherDescriptions != null && $._weatherDescriptions.hasKey(key)) {
    return $._weatherDescriptions[key] as Lang.String;
  }
  return null;
}

function split(strIn as Lang.String?, splitter as Lang.String) as Array {
  var array = [];
  if (strIn == null) {
    return array;
  }
  var index = 0;
  var location = strIn.find(splitter);
  
  while (location != null) {
    array.add(strIn.substring(0, location));
    strIn = strIn.substring(location + splitter.length(), strIn.length()) as Lang.String;
    location = strIn.find(splitter);
  }
  array.add(strIn);

  return array;
}