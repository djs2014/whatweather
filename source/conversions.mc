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
      relativeHumidity < offsetValue($._comfortHumidity[0], 0.3)) {
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

function getConditionCategorie(condition) as WeatherCondition {
  switch (condition) {
    case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
      return new WeatherCondition(WeatherCondition.THUNDERSTORMS,
                                  WeatherCondition.CHANCE);
    case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
      return new WeatherCondition(WeatherCondition.THUNDERSTORMS,
                                  WeatherCondition.LIGHT);
    case Weather.CONDITION_THUNDERSTORMS:
      return new WeatherCondition(WeatherCondition.THUNDERSTORMS,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_TROPICAL_STORM:
      return new WeatherCondition(WeatherCondition.THUNDERSTORMS,
                                  WeatherCondition.HEAVY);

    case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
    case Weather.CONDITION_CHANCE_OF_SHOWERS:
      return new WeatherCondition(WeatherCondition.RAIN,
                                  WeatherCondition.CHANCE);

    case Weather.CONDITION_LIGHT_RAIN:
    case Weather.CONDITION_LIGHT_SHOWERS:
    case Weather.CONDITION_SCATTERED_SHOWERS:
      return new WeatherCondition(WeatherCondition.RAIN,
                                  WeatherCondition.LIGHT);

    case Weather.CONDITION_RAIN:
    case Weather.CONDITION_SHOWERS:
      return new WeatherCondition(WeatherCondition.RAIN,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_FREEZING_RAIN:
    case Weather.CONDITION_HEAVY_RAIN:
    case Weather.CONDITION_HEAVY_RAIN_SNOW:
    case Weather.CONDITION_HEAVY_SHOWERS:
      return new WeatherCondition(WeatherCondition.RAIN,
                                  WeatherCondition.HEAVY);
    case Weather.CONDITION_HAIL:
    case Weather.CONDITION_WINTRY_MIX:
      return new WeatherCondition(WeatherCondition.HAIL,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_CHANCE_OF_SNOW:
    case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
    case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
    case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.CHANCE);

    case Weather.CONDITION_FLURRIES:
    case Weather.CONDITION_LIGHT_SNOW:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.LIGHT);

    case Weather.CONDITION_SNOW:
    case Weather.CONDITION_RAIN_SNOW:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_SLEET:
    case Weather.CONDITION_ICE_SNOW:
    case Weather.CONDITION_ICE:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.HEAVY);

    case Weather.CONDITION_HEAVY_SNOW:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.HEAVY);

    case Weather.CONDITION_HURRICANE:
    case Weather.CONDITION_TORNADO:
      return new WeatherCondition(WeatherCondition.TORNADO,
                                  WeatherCondition.HEAVY);

    case Weather.CONDITION_DUST:
    case Weather.CONDITION_SAND:
      return new WeatherCondition(WeatherCondition.SAND,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_SANDSTORM:
      return new WeatherCondition(WeatherCondition.SAND,
                                  WeatherCondition.HEAVY);

    case Weather.CONDITION_VOLCANIC_ASH:
      return new WeatherCondition(WeatherCondition.ASH,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_SMOKE:
      return new WeatherCondition(WeatherCondition.SMOKE,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_FAIR:
      return new WeatherCondition(WeatherCondition.CLEAR,
                                  WeatherCondition.LIGHT);
    case Weather.CONDITION_CLEAR:
      return new WeatherCondition(WeatherCondition.CLEAR,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_THIN_CLOUDS:
    case Weather.CONDITION_MOSTLY_CLEAR:
    case Weather.CONDITION_PARTLY_CLEAR:
      return new WeatherCondition(WeatherCondition.CLEAR,
                                  WeatherCondition.LIGHT);
    case Weather.CONDITION_PARTLY_CLOUDY:
      return new WeatherCondition(WeatherCondition.CLOUDS,
                                  WeatherCondition.LIGHT);
    case Weather.CONDITION_MOSTLY_CLOUDY:
    case Weather.CONDITION_CLOUDY:
      return new WeatherCondition(WeatherCondition.CLOUDS,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_FOG:
      return new WeatherCondition(WeatherCondition.FOG,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_MIST:
      return new WeatherCondition(WeatherCondition.MIST,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_WINDY:
      return new WeatherCondition(WeatherCondition.WINDY,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_HAZY:
      return new WeatherCondition(WeatherCondition.HAZE,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_DRIZZLE:
      return new WeatherCondition(WeatherCondition.DRIZZLE,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_SQUALL:  // sudden windspeed
      return new WeatherCondition(WeatherCondition.SQUALL,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_UNKNOWN_PRECIPITATION:
    case Weather.CONDITION_UNKNOWN:
    default:
      return new WeatherCondition(WeatherCondition.UNKNOWN,
                                  WeatherCondition.NORMAL);
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