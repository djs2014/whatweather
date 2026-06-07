import Toybox.Lang;
import Toybox.System;
import Toybox.Weather;

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
var _alertWindIn as Lang.Number = SHOW_WIND_KILOMETERS;
var _alertLevelWindGust as Lang.Number = 2;
var _alertBacklight as Boolean = false;
var _loopWeatherCondition as Boolean = false;

(:typecheck(disableBackgroundCheck))
function getWeatherConditionText(conditionCode as Number) {
  var text = "Unknown";
  if (conditionCode == null) {
    return text;
  }
  switch (conditionCode) {
    case Weather.CONDITION_CLEAR:
      text = "clear";
      break;
    case Weather.CONDITION_PARTLY_CLOUDY:
      text = "p cloudy";
      break;
    case Weather.CONDITION_MOSTLY_CLOUDY:
      text = "m cloudy";
      break;
    case Weather.CONDITION_RAIN:
      text = "rain";
      break;
    case Weather.CONDITION_SNOW:
      text = "snow";
      break;
    case Weather.CONDITION_WINDY:
      text = "windy";
      break;
    case Weather.CONDITION_THUNDERSTORMS:
      text = "thunder";
      break;
    case Weather.CONDITION_WINTRY_MIX:
      text = "wintry";
      break;
    case Weather.CONDITION_FOG:
      text = "fog";
      break;
    case Weather.CONDITION_HAZY:
      text = "hazy";
      break;
    case Weather.CONDITION_HAIL:
      text = "hail";
      break;
    case Weather.CONDITION_SCATTERED_SHOWERS:
      text = "s showers";
      break;
    case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
      text = "s thunder";
      break; 
    case Weather.CONDITION_UNKNOWN_PRECIPITATION:
      text = "unknown";
      break;
    case Weather.CONDITION_LIGHT_RAIN:
      text = "l rain";
      break;
    case Weather.CONDITION_HEAVY_RAIN:
      text = "h rain";
      break;
    case Weather.CONDITION_LIGHT_SNOW:
      text = "l snow";
      break;
    case Weather.CONDITION_HEAVY_SNOW:
      text = "h snow";
      break;
    case Weather.CONDITION_LIGHT_RAIN_SNOW:
      text = "l rain/snow";
      break;
    case Weather.CONDITION_HEAVY_RAIN_SNOW:
      text = "h rain/snow";
      break;
    case Weather.CONDITION_CLOUDY:
      text = "cloudy";
      break;
    case Weather.CONDITION_RAIN_SNOW:
      text = "rain/snow";
      break;
    case Weather.CONDITION_PARTLY_CLEAR:
      text = "p clear";
      break;
    case Weather.CONDITION_MOSTLY_CLEAR:
      text = "m clear";
      break;
    case Weather.CONDITION_LIGHT_SHOWERS:
      text = "l showers";
      break;
    case Weather.CONDITION_SHOWERS:
      text = "showers";
      break;
    case Weather.CONDITION_HEAVY_SHOWERS:
      text = "h showers";
      break;
    case Weather.CONDITION_CHANCE_OF_SHOWERS:
      text = "? showers";
      break;
    case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
      text = "? thunder";
      break;
    case Weather.CONDITION_MIST:
      text = "mist";
      break;
    case Weather.CONDITION_DUST:
      text = "dust";
      break;
    case Weather.CONDITION_DRIZZLE:
      text = "drizzle";
      break;
    case Weather.CONDITION_TORNADO:
      text = "tornado";
      break;
    case Weather.CONDITION_SMOKE:
      text = "smoke";
      break;
    case Weather.CONDITION_ICE:
      text = "ice";
      break;
    case Weather.CONDITION_SAND:
      text = "sand";
      break;
    case Weather.CONDITION_SQUALL:
      text = "squall";
      break;
    case Weather.CONDITION_SANDSTORM:
      text = "sandstorm";
      break;
    case Weather.CONDITION_VOLCANIC_ASH:
      text = "volcano";
      break;
    case Weather.CONDITION_FAIR:
      text = "fair";
      break;
    case Weather.CONDITION_HURRICANE:
      text = "hurricane";
      break;
    case Weather.CONDITION_TROPICAL_STORM:
      text = "tropical";
      break;
    case Weather.CONDITION_CHANCE_OF_SNOW:
      text = "? snow";
      break;
    case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
      text = "? wintry";
      break;
    case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
      text = "? rain";
      break;
    case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
      text = "? snow";
      break;
    case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
      text = "? wintry";
      break;
    case Weather.CONDITION_FLURRIES:
      text = "flurries";
      break;
    case Weather.CONDITION_FREEZING_RAIN:
      text = "freezing";
      break;
    case Weather.CONDITION_SLEET:
      text = "sleet";
      break;
    case Weather.CONDITION_ICE_SNOW:
      text = "ice/snow";
      break;
    case Weather.CONDITION_THIN_CLOUDS:
      text = "- clouds";
      break;
  }

  return text;
}
