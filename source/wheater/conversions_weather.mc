import Toybox.Weather;
import Toybox.System;
import Toybox.Graphics;
import Toybox.Lang;
using WhatAppBase.Utils as Utils;

function offsetValue(value as Lang.Numeric, factor as Lang.Numeric) as Lang.Numeric {
   return value - (value * factor);
}

function calculateComfortIdx(levelLow as Lang.Numeric, levelHigh as Lang.Numeric) as Lang.Number {
  if (levelLow >= 0 && levelHigh <= 0) {
    return COMFORT_NORMAL;
  }
  if (levelLow < 0) {
    return COMFORT_BELOW;
  }
  if (levelHigh > 0) {
    return COMFORT_HIGH;
  }
  return COMFORT_BELOW;
}

function calculateComfortIdxInverted(levelLow as Lang.Numeric, levelHigh as Lang.Numeric) as Lang.Number {
  if (levelLow >= 0 && levelHigh <= 0) {
    return COMFORT_NORMAL;
  }
  if (levelLow < 0) {
    return COMFORT_HIGH;
  }
  if (levelHigh > 0) {
    return COMFORT_BELOW;
  }
  return COMFORT_BELOW;
}

function uviToColor(uvi as Lang.Float?) as Lang.Number {
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

function uviToRadius(uvi as Lang.Float?) as Lang.Number {
  if (uvi == null) {
    return 0;
  }
  if (uvi > 10) {
    return 6;
  } else if (uvi >= 8) {
    return 5;
  } else if (uvi >= 6) {
    return 4;
  } else if (uvi >= 3) {
    return 3;
  } else {
    return 3;
  }
}

function getConditionColor(condition as Lang.Number?, def as Lang.Number) as Lang.Number {
  if (condition == null) {
    return def;  // Graphics.COLOR_BLUE;
  }
  switch (condition) {
    case Weather.CONDITION_THUNDERSTORMS:
    case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
    case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
      return Graphics.COLOR_RED;
      
    case Weather.CONDITION_HEAVY_SHOWERS:
    case Weather.CONDITION_HEAVY_RAIN:
    case Weather.CONDITION_FREEZING_RAIN:
    case Weather.CONDITION_HAIL:
    case Weather.CONDITION_HEAVY_RAIN_SNOW:
    case Weather.CONDITION_HEAVY_SNOW:
      return Graphics.COLOR_DK_BLUE;

    case Weather.CONDITION_WINTRY_MIX:
    case Weather.CONDITION_RAIN_SNOW:
    case Weather.CONDITION_SNOW:
      return Graphics.COLOR_DK_GRAY;

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
