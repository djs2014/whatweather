import Toybox.Lang;
import Toybox.System;

const DEBUG_DETAILS = false;
const SHOW_WIND_COUNT = 3;
const SHOW_WIND_METERS = 0;
const SHOW_WIND_KILOMETERS = 1;
const SHOW_WIND_BEAUFORT = 2;

const SHOW_INFO_NOTHING = 0;
const SHOW_INFO_TIME_Of_DAY = 1;
const SHOW_INFO_AMBIENT_PRESSURE = 2;
const SHOW_INFO_SEALEVEL_PRESSURE = 3;
const SHOW_INFO_DISTANCE = 4;
const SHOW_INFO_RELATIVE_WIND = 5;

// TODO ..
const COLOR_WHITE_BLUE = 0xe1e5f8;
const COLOR_WHITE_GREEN = 0xe6ffe5; // 0x8DDA8D;
const COLOR_WHITE_YELLOW = 0xffffe1; // 0xFFFFAA;
const COLOR_WHITE_ORANGE = 0xffe9e1; // 0xF1AC4A;

var _weatherDataSource as WeatherSource = wsOWMFirst;
var _soundMode as Number = 1;

var _maxUVIndex as Lang.Number = 20;
var _minTemperature as Lang.Number = 0; // celcius
var _maxTemperature as Lang.Number = 50; // celcius
var _maxPressure as Lang.Number = 1080;
var _minPressure as Lang.Number = 870;
var _maxMMRainPerHour as Lang.Number = 10;
var _percHideDetails as Lang.Number = 5;

var _observationTimeDelayedMinutesThreshold as Lang.Number = 30;

var _alertLevelPrecipitationChance as Lang.Number = 70;
var _alertLevelUVi as Lang.Number = 6;
var _alertLevelRainMMfirstHour as Lang.Float = 0.2f;
var _alertLevelRainMMHour as Lang.Float = 0.2f;
var _alertLevelDewpoint as Lang.Number = 19;
var _alertWindIn as Lang.Number = SHOW_WIND_KILOMETERS;
var _alertLevelWindSpeed as Lang.Float = 5.0f;
var _alertLevelWindGust as Lang.Number = 2;
var _alertBacklight as Boolean = false;

(:typecheck(disableBackgroundCheck))
function getWeatherConditionText(condition as Lang.Number?) as Lang.String? {
  if (condition == null) {
    return null;
  }
  var key = condition as Lang.Number;

  if (key < $._weatherDescriptions.size()) {
    return $._weatherDescriptions[key] as Lang.String;
  }
  return null;
}
