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

function comfortToColor(comfort as Lang.Number?) as Lang.Number {
  if (comfort == COMFORT_NO) {
    return Graphics.COLOR_TRANSPARENT;
  }
  var color = WhatAppBase.Colors.COLOR_WHITE_GREEN_2;
  if (comfort == COMFORT_NORMAL) {
    color = WhatAppBase.Colors.COLOR_WHITE_YELLOW_2;
  } else if (comfort == COMFORT_HIGH) {
    color = WhatAppBase.Colors.COLOR_WHITE_ORANGERED2_2;
  }
  return color;
}
function dewpointToColor(dp as Lang.Float?) as Lang.Number {
  if (dp == null) {
    return WhatAppBase.Colors.COLOR_WHITE_GRAY_2;
  }

  if (dp <= 4) {
    return WhatAppBase.Colors.COLOR_WHITE_GRAY_3;
  } else if (dp <= 6) {
    return WhatAppBase.Colors.COLOR_WHITE_LT_GREEN_1;
  } else if (dp <= 8) {
    return WhatAppBase.Colors.COLOR_WHITE_LT_GREEN_2;
  } else if (dp <= 10) {
    return WhatAppBase.Colors.COLOR_WHITE_LT_GREEN_3;
  } else if (dp <= 12) {
    return WhatAppBase.Colors.COLOR_WHITE_GREEN_3;
  } else if (dp <= 16) {
    return WhatAppBase.Colors.COLOR_WHITE_YELLOW_3;
  } else if (dp <= 18) {
    return WhatAppBase.Colors.COLOR_WHITE_ORANGE_3;
  } else if (dp <= 21) {
    return WhatAppBase.Colors.COLOR_WHITE_RED_3;
  } else if (dp <= 24) {
    return WhatAppBase.Colors.COLOR_WHITE_DK_RED_3;
  } else if (dp <= 26) {
    return WhatAppBase.Colors.COLOR_WHITE_PURPLE_3;
  } else {
    return WhatAppBase.Colors.COLOR_WHITE_DK_PURPLE_3;
  }
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
