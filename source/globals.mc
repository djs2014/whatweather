import Toybox.Lang;

const DEBUG_DETAILS = false;
const SHOW_WIND_NOTHING = 0;
const SHOW_WIND_METERS = 1;
const SHOW_WIND_KILOMETERS = 2;
const SHOW_WIND_BEAUFORT = 3;

const SHOW_INFO_NOTHING = 0;
const SHOW_INFO_TIME_Of_DAY = 1;
const SHOW_INFO_ALTITUDE = 2;
const SHOW_INFO_HEADING = 3;
const SHOW_INFO_TEMPERATURE = 4;
const SHOW_INFO_HEARTRATE = 5;
const SHOW_INFO_AMBIENT_PRESSURE = 6;
const SHOW_INFO_DISTANCE = 7;

const COLOR_LT_BLUE = 0x00FFFF;

const COLOR_WHITE_GREEN = 0x8DDA8D;
const COLOR_WHITE_YELLOW = 0xFFFFAA;
const COLOR_WHITE_ORANGE = 0xF1AC4A;

var _showCurrentForecast = true;
var _maxHoursForecast = 8;
var _maxMinuteForecast = 60;
var _alertLevelPrecipitationChance = 70;
var _showAlertLevel = false;
var _showMaxPrecipitationChance = true;
var _dashesUnderColumnHeight = 2;
var _showColumnBorder = false;
var _showObservationTime = true;
var _showObservationLocationName = true;
var _observationTimeDelayedMinutesThreshold = 30;
var _showClouds = true;
var _showUVIndexFactor = 2;
var _hideUVIndexLowerThan = 4;
var _showInfo = SHOW_INFO_TIME_Of_DAY;
var _showPrecipitationChanceAxis = true;

var _alertLevelWindSpeed = 5;
var _showWind = SHOW_WIND_BEAUFORT;
var _showTemperature = true;
var _showRelativeHumidity = true;
var _showWeatherCondition = true;
var _showComfort = true;

var _alertLevelUVi = 6;
var _alertLevelRainMMfirstHour = 5;

const COMFORT_NO = 0;
const COMFORT_BELOW = 1;
const COMFORT_NORMAL = 2;
const COMFORT_HIGH = 3;

var _comfortTemperature = [22,27];
var _comfortHumidity = [40,60];
var _comfortPrecipitationChance = [0, 40];

var _alertHandler = new AlertHandler();

function getValue(value, def) {
  if (value == null) {
    return def;
  }
  return value;
}