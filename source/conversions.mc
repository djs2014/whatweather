import Toybox.Weather;
import Toybox.System;
import Toybox.Graphics;

const MILE = 1.609344;
const FEET = 3.281;

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

function celciusToFarenheit(celcius) { return ((celcius * 9 / 5) + 32); }

function meterToFeet(meter) { return meter * FEET; }

function kilometerToMile(km) { return km / MILE; }

// Somewhere from the internet.. Humans generally feel comfortable between
// temperatures of 22 °C to 27 °C and a relative humidity of 40% to 60%.
function convertToComfort(temperature, relativeHumidity, precipitationChance) {
  if (temperature == null || relativeHumidity == null ||
      precipitationChance == null) {
    return COMFORT_NO;
  }

  if (temperature < offsetValue($._comfortTemperature[0], 0.3) ||
      relativeHumidity < offsetValue($._comfortHumidity[0], 0.3) ) {
      return COMFORT_NO;
    }
  var tempLow = compareTo(temperature, $._comfortTemperature[0]);
  var tempHigh = compareTo(temperature, $._comfortTemperature[1]);

  var humLow = compareTo(relativeHumidity, $._comfortHumidity[0]);
  var humHigh = compareTo(relativeHumidity, $._comfortHumidity[1]);

  var popLow = compareTo(precipitationChance, $._comfortPrecipitationChance[0]);
  var popHigh =
      compareTo(precipitationChance, $._comfortPrecipitationChance[1]);

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
  return COMFORT_NO;
}

function offsetValue(value, factor) { return value - (value * factor); }

function calculateComfortIdx(levelLow, levelHigh) {
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

function calculateComfortIdxInverted(levelLow, levelHigh) {
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

function compareTo(numberA, numberB) {
  if (numberA > numberB) {
    return 1;
  } else if (numberA < numberB) {
    return -1;
  } else {
    return 0;
  }
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

function min(a as Lang.Number, b as Lang.Number) {
  if (a <= b) {
    return a;
  } else {
    return b;
  }
}

function max(a as Lang.Number, b as Lang.Number) {
  if (a >= b) {
    return a;
  } else {
    return b;
  }
}