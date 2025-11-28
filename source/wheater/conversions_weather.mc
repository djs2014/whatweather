import Toybox.Weather;
import Toybox.System;
import Toybox.Graphics;
import Toybox.Lang;

// https://rgbcolorcode.com/color/converter/
// https://rgbcolorcode.com/color/43487e
// https://encycolorpedia.com/43487e
var gDewpointColorsDay as Array<ColorType> = [] as Array<ColorType>;
var gDewpointColorsNight as Array<ColorType> = [] as Array<ColorType>;

// https://rgbcolorcode.com/color/converter/
const DEWPOINT_COLORS_SCHEME =
  [
    [0, 229, 232, 232], // COLOR_WHITE_GRAY_2 = 0xE5E8E8;
    [4, 153, 170, 187], // COLOR_WHITE_GRAY_3 = 0xCCD1D1;
    [6, 232, 248, 245], // COLOR_WHITE_LT_GREEN_1 = 0xE8F8F5;
    [8, 212, 239, 223], //  COLOR_WHITE_GREEN_2 = 0xD4EFDF;
    [10, 163, 228, 215], // COLOR_WHITE_LT_GREEN_3;
    [12, 169, 223, 191], // COLOR_WHITE_GREEN_3; ok
    [16, 249, 231, 159], // COLOR_WHITE_YELLOW_3 ok
    [18, 250, 215, 160], // COLOR_WHITE_ORANGE_3 ok
    [21, 245, 183, 177], // COLOR_WHITE_RED_3 ok
    [24, 230, 176, 170], // COLOR_WHITE_DK_RED_3 ok
    [26, 215, 189, 226], // COLOR_WHITE_PURPLE_3 ok
    [30, 210, 180, 222], // COLOR_WHITE_DK_PURPLE_3
    [40, 56, 42, 61], // COLOR_WHITE_DK_PURPLE_4 = 0xBB8FCE;
    [50, 215, 189, 226], // COLOR_WHITE_DK_PURPLE_5 382A3D
  ] as Array<Array<Number> >;

function initDewpointColors(maxDewpoint as Number) {
  var max = maxDewpoint;
  if (max <= 0) {
    max = 30;
  }
  var colorScheme = $.DEWPOINT_COLORS_SCHEME;
  for (var i = 0; i < max; i++) {
    var colorDay = $.idxToColor(i, 255, colorScheme, 0);
    $.gDewpointColorsDay.add(colorDay);
    var colorNight = $.idxToColor(i, 255, colorScheme, -30);
    $.gDewpointColorsNight.add(colorNight);
  }
}
function dewpointToColor(dewpoint as Lang.Number, darkBackground as Boolean) as ColorType {
  if (dewpoint < 0) {
    // Below zero, do not show dewpoint
    return Graphics.COLOR_TRANSPARENT;
  }
  var colors = $.gDewpointColorsDay;
  if (darkBackground) {
    colors = $.gDewpointColorsNight;
  }
  var maxDewpoint = colors.size() - 1;
  if (dewpoint > maxDewpoint) {
    dewpoint = maxDewpoint;
  }
  return colors[dewpoint] as ColorType;
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

function getConditionColor(condition as Lang.Number?, def as Lang.Number, darkBackground as Boolean) as Lang.Number {
  if (condition == null) {
    return def; // Graphics.COLOR_BLUE;
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
      if (darkBackground) {
        return Graphics.createColor(255, 0,77,230); //rgb(0,77,230) 
      }
      return Graphics.COLOR_DK_BLUE;

    case Weather.CONDITION_WINTRY_MIX:
    case Weather.CONDITION_RAIN_SNOW:
    case Weather.CONDITION_SNOW:
    case Weather.CONDITION_ICE:
    case Weather.CONDITION_ICE_SNOW:
      if (darkBackground) {
        return Graphics.createColor(255, 153,238,255); //rgb(153,238,255)
      }
      return Graphics.COLOR_DK_GRAY;

    case Weather.CONDITION_HURRICANE:
    case Weather.CONDITION_TORNADO:
    case Weather.CONDITION_SANDSTORM:
    case Weather.CONDITION_TROPICAL_STORM:
    case Weather.CONDITION_VOLCANIC_ASH:
      // if (darkBackground) {
      //    return Graphics.createColor(255, 229,102,255); // rgb(229,102,255)
      // }
      return Graphics.COLOR_PURPLE; // AA00FF

    default:
      return def;
  }
}
