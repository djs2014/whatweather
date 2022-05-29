import Toybox.Weather;
import Toybox.System;
import Toybox.Graphics;
import Toybox.Lang;
using WhatAppBase.Utils as Utils;

// Somewhere from the internet.. Humans generally feel comfortable between
// temperatures of 22 °C to 27 °C and a relative humidity of 40% to 60%.
function convertToComfort(temperature as Lang.Number?, relativeHumidity as Lang.Number?, precipitationChance as Lang.Number?) as Lang.Number {
  if (temperature == null || relativeHumidity == null || precipitationChance == null) {
    return COMFORT_NO;
  }

  var cTemp0 = $._comfortTemperature[0] as Lang.Number;
  var cTemp1 = $._comfortTemperature[1] as Lang.Number;
  var cHum0 = $._comfortHumidity[0] as Lang.Number;
  var cHum1 = $._comfortHumidity[1] as Lang.Number;
  var cPrec0 = $._comfortPrecipitationChance[0] as Lang.Number;
  var cPrec1 = $._comfortPrecipitationChance[1] as Lang.Number;

  if (temperature < offsetValue(cTemp0, 0.3) ||
      relativeHumidity < offsetValue(cHum0, 0.3)) {
    return COMFORT_NO;
  }


  var tempLow = Utils.compareTo(temperature, cTemp0);
  var tempHigh = Utils.compareTo(temperature, cTemp1);

  var humLow = Utils.compareTo(relativeHumidity, cHum0);
  var humHigh = Utils.compareTo(relativeHumidity, cHum1);

  var popLow = Utils.compareTo(precipitationChance, cPrec0);
  var popHigh = Utils.compareTo(precipitationChance, cPrec1);

  var popIdx = calculateComfortIdxInverted(popLow, popHigh);
  if (popIdx < COMFORT_NORMAL) {
    return COMFORT_NO;
  }

  var tempIdx = calculateComfortIdx(tempLow, tempHigh);
  var humIdx = calculateComfortIdx(humLow, humHigh);
  // System.println("Comfort tempIdx:" + tempIdx + " humIdx:" + humIdx);

  if (tempIdx <= COMFORT_BELOW) {
    return COMFORT_BELOW;
  } else if (tempIdx == COMFORT_NORMAL) {
    if (humIdx <= COMFORT_NORMAL) {
      return COMFORT_NORMAL;
    } else {
      return COMFORT_HIGH;
    }
  } else {
    if (humIdx <= COMFORT_NORMAL) {
      return COMFORT_NORMAL;
    } else {
      return COMFORT_HIGH;
    }
  }
  // return COMFORT_NO;
}

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
