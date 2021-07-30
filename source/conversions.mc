import Toybox.Weather;
import Toybox.System;
import Toybox.Graphics;

function windSpeedToBeaufort(metersPerSecond) {
  if (metersPerSecond == null || metersPerSecond <= 0.2) {
    return 0;
  }
  if (metersPerSecond <= 1.5) {
    return 1;
  }
  if (metersPerSecond <= 3.3) {
    return 2;
  }
  if (metersPerSecond <= 5.4) {
    return 3;
  }
  if (metersPerSecond <= 7.9) {
    return 4;
  }
  if (metersPerSecond <= 10.7) {
    return 5;
  }
  if (metersPerSecond <= 13.8) {
    return 6;
  }
  if (metersPerSecond <= 17.1) {
    return 7;
  }
  if (metersPerSecond <= 20.7) {
    return 8;
  }
  if (metersPerSecond <= 24.4) {
    return 9;
  }
  if (metersPerSecond <= 28.4) {
    return 10;
  }
  if (metersPerSecond <= 32.6) {
    return 11;
  }
  return 12;
}

function windSpeedToKmPerHour(metersPerSecond) {
  if (metersPerSecond == null) {
    return 0;
  }
  return (metersPerSecond * 60 * 60) / 1000.0;
}

function uviToColor(uvi) {
  if (uvi == null) {
    return Graphics.COLOR_GREEN;
  }
  if (uvi > 10) {
    return Graphics.COLOR_PURPLE;
  } else if (uvi >= 8) {
    return Graphics.COLOR_RED;
  } else if (uvi >= 6) {
    return Graphics.COLOR_ORANGE;
  } else if (uvi >= 3) {
    return Graphics.COLOR_YELLOW;
  } else {
    return Graphics.COLOR_GREEN;
  }
}

function getConditionColor(condition, def) {
  if (condition == null) {
    return def;  // Graphics.COLOR_BLUE;
  }
  switch (condition) {
    case Weather.CONDITION_THUNDERSTORMS:
    case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
    case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
      return Graphics.COLOR_RED;
      break;
    case Weather.CONDITION_FREEZING_RAIN:
    case Weather.CONDITION_HAIL:
    case Weather.CONDITION_HEAVY_RAIN:
    case Weather.CONDITION_HEAVY_RAIN_SNOW:
    case Weather.CONDITION_HEAVY_SHOWERS:
    case Weather.CONDITION_HEAVY_SNOW:
      return Graphics.COLOR_DK_BLUE;
    case Weather.CONDITION_HURRICANE:
    case Weather.CONDITION_TORNADO:
    case Weather.CONDITION_SANDSTORM:
    case Weather.CONDITION_TROPICAL_STORM:
    case Weather.CONDITION_VOLCANIC_ASH:
      return Graphics.COLOR_PURPLE;
    default:
      return def;
  }
}