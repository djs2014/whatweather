import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

class DisplaySettings {
  var font as Graphics.FontType = Graphics.FONT_LARGE;
  var fontSmall as Graphics.FontType = Graphics.FONT_XTINY;

  var COLOR_TEXT as Lang.Number = Graphics.COLOR_BLACK;
  var COLOR_BACKGROUND as Lang.Number = Graphics.COLOR_WHITE;
  var COLOR_TEXT_ADDITIONAL as Lang.Number = Graphics.COLOR_BLACK;
  var COLOR_TEXT_ADDITIONAL2 as Lang.Number = Graphics.COLOR_DK_GRAY;
  var COLOR_TEXT_ALERT as Lang.Number = Graphics.COLOR_RED;
  var COLOR_TEXT_ALERT2 as Lang.Number = Graphics.COLOR_PINK;
  var COLOR_TEXT_ALERT3 as Lang.Number = Graphics.COLOR_PURPLE;
  var COLOR_BACKGROUND_ALERT as Lang.Number = Graphics.COLOR_YELLOW;
  var COLOR_TEXT_DASHES as Lang.Number = Graphics.COLOR_DK_GRAY;
  var COLOR_TEXT_DETAILS as Lang.Number = Graphics.COLOR_WHITE;
  var COLOR_DEWPOINT_DETAILS as Lang.Number = Graphics.COLOR_DK_GRAY;
  var COLOR_HUMIDITY_DETAILS as Lang.Number = Graphics.COLOR_DK_BLUE;
  var COLOR_HUMIDITY as Lang.Number = Graphics.COLOR_DK_BLUE;
  var COLOR_WIND_ICON as Lang.Number = Graphics.COLOR_BLACK;
  var COLOR_CLOUDS as Lang.Number = 0xccd1d1; // rgb(204, 209, 209)
  var COLOR_MM_RAIN = 0x154360; // DARK_BLUE_10
  var COLOR_MM_DIVIDER = 0xccccff; // Lavender BLUE
  var COLOR_MM_DETAILS = Graphics.COLOR_BLACK;
  var COLOR_0_TEMPERATURE = 0xa0a0ff; // Light Blue

  var COLOR_WHITE_BLUE = 0xe1e5f8;
  var COLOR_WHITE_GREEN = 0xe6ffe5; // 0x8DDA8D;
  var COLOR_WHITE_YELLOW = 0xffffe1; // 0xFFFFAA;
  var COLOR_WHITE_ORANGE = 0xffe9e1; // 0xF1AC4A;

  var width as Lang.Number = 0;
  var height as Lang.Number = 0;
  var nrOfColumns as Lang.Number = 0;

  var margin as Lang.Number = 5;
  var marginBottom as Lang.Number = 5;
  var space as Lang.Number = 2;

  var offsetX as Lang.Number = 0;
  var columnWidth as Lang.Number = 10;
  var columnHeight as Lang.Number = 0;

  var dashesPosY as Lang.Number = 0;
  var heightWind as Lang.Number = 0;
  var heightWc as Lang.Number = 0;
  var heightWt as Lang.Number = 0;
  var columnY as Lang.Number = 0;
  var columnX as Lang.Number = 0;

  var dashesUnderColumnHeight as Lang.Number = 2;

  var alertFonts as Array = [
    Graphics.FONT_XTINY,
    Graphics.FONT_TINY,
    Graphics.FONT_SYSTEM_SMALL,    
    Graphics.FONT_NUMBER_MILD,
    Graphics.FONT_NUMBER_MEDIUM,
    Graphics.FONT_SYSTEM_NUMBER_HOT,    
  ];

  hidden var colorCloudsNight as Lang.Number = 0;

  function initialize() {
    colorCloudsNight = $.shadeColor(255, 104, 109, 109, -20);
  }

  function calculate(
    dc as Dc,
    nrOfColumns as Lang.Number,
    heightWind as Lang.Number,
    heightWc as Lang.Number,
    heightWt as Lang.Number
  ) as Void {
    self.width = dc.getWidth();
    self.height = dc.getHeight();
    self.nrOfColumns = nrOfColumns;
    self.heightWind = heightWind;
    self.heightWc = heightWc;
    self.heightWt = heightWt;
    calculateColumns(0, self.nrOfColumns);

    if (self.heightWind > 0 || self.heightWc > 0) {
      self.dashesUnderColumnHeight = 0;
    }

  }

  function calculateColumns(offset as Lang.Number, nrOfColumns as Number) as Void {
    offsetX = offset;
    columnWidth = 0;
    var columns = nrOfColumns;
    if (columns < 0) {
      columns = self.nrOfColumns;
    }
    if (columns > 0) {
      columnWidth = ((width - offsetX - 2 * margin - (columns - 1) * space) / columns).toNumber();
    }
    columnY = margin;
    var correction = ((width - offsetX - 2 * margin - columns * columnWidth - (columns - 1) * space) / 2).toNumber();
    columnX = (margin + correction).toNumber();

    // Height of the weather column, 2 lines for weather condition text
    columnHeight = (height - (2 * margin) - heightWind - heightWc - (heightWt * 2)).toNumber();

    // Position of dashes under columns
    dashesPosY = (columnY + columnHeight).toNumber();
    System.println(["#columns",nrOfColumns, "height column", columnHeight, "wind", heightWind, "weather icon", heightWc, "text", heightWt]);
  }

  function setColors(darkBackground as Boolean) as Void {
    if (darkBackground) {
      COLOR_TEXT = Graphics.COLOR_WHITE;
      COLOR_BACKGROUND = Graphics.COLOR_BLACK;
      COLOR_TEXT_ADDITIONAL = Graphics.COLOR_WHITE;
      COLOR_TEXT_ADDITIONAL2 = Graphics.COLOR_WHITE;
      COLOR_BACKGROUND_ALERT = Graphics.COLOR_YELLOW;
      COLOR_TEXT_ALERT = Graphics.COLOR_RED;
      COLOR_TEXT_ALERT2 = Graphics.COLOR_PINK;
      COLOR_TEXT_ALERT3 = Graphics.COLOR_PURPLE;
      COLOR_TEXT_DASHES = Graphics.COLOR_DK_GRAY;
      COLOR_TEXT_DETAILS = Graphics.COLOR_LT_GRAY;
      COLOR_HUMIDITY = Graphics.COLOR_DK_BLUE;
      COLOR_HUMIDITY_DETAILS = Graphics.COLOR_BLUE;
      COLOR_WIND_ICON = Graphics.COLOR_WHITE;
      COLOR_CLOUDS = colorCloudsNight;
      COLOR_MM_RAIN = Graphics.createColor(255, 0, 213, 255); // rgb(0,213,255)
      COLOR_MM_DIVIDER = Graphics.COLOR_WHITE;
      COLOR_MM_DETAILS = Graphics.COLOR_WHITE;
      COLOR_DEWPOINT_DETAILS = Graphics.COLOR_WHITE;
    } else {
      COLOR_TEXT = Graphics.COLOR_BLACK;
      COLOR_BACKGROUND = Graphics.COLOR_WHITE;
      COLOR_TEXT_ADDITIONAL = Graphics.COLOR_BLACK;
      COLOR_TEXT_ADDITIONAL2 = Graphics.COLOR_DK_GRAY;
      COLOR_BACKGROUND_ALERT = Graphics.COLOR_YELLOW;
      COLOR_TEXT_ALERT = Graphics.COLOR_RED;
      COLOR_TEXT_ALERT2 = Graphics.COLOR_PINK;
      COLOR_TEXT_ALERT3 = Graphics.COLOR_PURPLE;
      COLOR_TEXT_DASHES = Graphics.COLOR_DK_GRAY;
      COLOR_TEXT_DETAILS = Graphics.COLOR_WHITE;
      COLOR_HUMIDITY = Graphics.COLOR_DK_BLUE;
      COLOR_HUMIDITY_DETAILS = Graphics.COLOR_DK_BLUE;
      COLOR_WIND_ICON = Graphics.COLOR_BLACK;
      COLOR_CLOUDS = 0xccd1d1; // rgb(204, 209, 209)
      COLOR_MM_RAIN = 0x154360; // DARK_BLUE_10
      COLOR_MM_DIVIDER = 0xccccff; // Lavender BLUE
      COLOR_MM_DETAILS = Graphics.COLOR_BLACK;
      COLOR_DEWPOINT_DETAILS = Graphics.COLOR_DK_GRAY;
    }
  }
  function info() as Lang.String {
    return Lang.format("w[$1$] h[$2$] #c[$3$] offset[$4$] cw[$5$] ch[$6$]", [
      width,
      height,
      nrOfColumns,
      offsetX,
      columnWidth,
      columnHeight,
    ]);
  }

  //! Get correct y position based on a percentage
  function getYpostion(percentage as Lang.Number) as Lang.Number {
    return (margin + columnHeight - (columnHeight * (percentage / 100.0))).toNumber();
  }
}
