import Toybox.System;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Math;

var gCreateColors as Boolean = false;
var gUseSetFillStroke as Boolean = false;

function checkFeatures() as Void {
  $.gCreateColors = Graphics has :createColor;
  try {
    $.gUseSetFillStroke = Graphics.Dc has :setStroke;
    if ($.gUseSetFillStroke) {
      $.gUseSetFillStroke = Graphics.Dc has :setFill;
    }
  } catch (ex) {
    System.println("Error get features: " + ex.getErrorMessage());
    ex.printStackTrace();
  }
}

// alpha, 255 is solid, 0 is transparent
// percent > 0 lighten color, percent < 0 darken
function shadeColor(
  alpha as Number,
  red as Numeric,
  green as Numeric,
  blue as Numeric,
  percent as Number
) as ColorType {
  if (percent != 0) {
    // System.println(["shadeColor - 1", alpha, red, green, blue, percent]);
    red = (red * (100 + percent)) / 100.0;
    green = (green * (100 + percent)) / 100.0;
    blue = (blue * (100 + percent)) / 100.0;

    red = min(red, 255);
    green = min(green, 255);
    blue = min(blue, 255);
    // System.println(["shadeColor - 2", alpha, red, green, blue, percent]);
  }
  return Graphics.createColor(
    alpha,
    red.toNumber(),
    green.toNumber(),
    blue.toNumber()
  );
}

// alpha, 255 is solid, 0 is transparent
function idxToColor(
  index as Numeric?,
  alpha as Number,
  colorScheme as Array<Array<Number> >,
  shadePercentage as Number
) as ColorType {
  var pcolor = 0;
  var pColors = colorScheme;
  var idx = index;
  if (idx == null) {
    idx = 0;
  }

  var i = 1;
  while (i < pColors.size()) {
    pcolor = pColors[i] as Array<Number>;
    if (idx <= pcolor[0]) {
      break;
    }
    i++;
  }
  if (i >= pColors.size()) {
    i = pColors.size() - 1;
  }

  var lower = pColors[i - 1];
  var upper = pColors[i];
  var range = upper[0] - lower[0];
  var rangePct = 1;
  if (range != 0) {
    rangePct = (idx - lower[0]) / range;
  }
  var pctLower = 1 - rangePct;
  var pctUpper = rangePct;

  var red = Math.floor(lower[1] * pctLower + upper[1] * pctUpper);
  var green = Math.floor(lower[2] * pctLower + upper[2] * pctUpper);
  var blue = Math.floor(lower[3] * pctLower + upper[3] * pctUpper);

  if (shadePercentage == 0) {
    return Graphics.createColor(
      alpha,
      red.toNumber(),
      green.toNumber(),
      blue.toNumber()
    );
  }
  return $.shadeColor(alpha, red, green, blue, shadePercentage);
}

function getMatchingFont(
  dc as Dc,
  fontList as Array,
  maxwidth as Number,
  text as String,
  startIndex as Number
) as FontType {
  var index = startIndex;
  if (index < 0) {
    index = fontList.size() - 1;
    if (index < 0) {
      return Graphics.FONT_SMALL;
    }
  }
  var font = fontList[index] as FontType;
  var widthValue = dc.getTextWidthInPixels(text, font);

  while (widthValue > maxwidth && index > 0) {
    index = index - 1;
    font = fontList[index] as FontType;
    widthValue = dc.getTextWidthInPixels(text, font);
  }
  // System.println(["matching font: maxwidth", maxwidth, "text:", text, "->", index, "width:", widthValue, "font", font]);
  return font;
}

function logInfo(info) as Void {
  var clockTime = System.getClockTime();

  var timeString = Lang.format("$1$:$2$:$3$ - $4$", [
    clockTime.hour.format("%02d"),
    clockTime.min.format("%02d"),
    clockTime.sec.format("%02d"),
    info,
  ]);

  System.println(timeString);
}
