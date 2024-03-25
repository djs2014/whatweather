import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

class DisplaySettings {
  var font as Graphics.FontType = Graphics.FONT_LARGE;
  var fontSmall as Graphics.FontType = Graphics.FONT_XTINY;

  var COLOR_TEXT as Lang.Number = Graphics.COLOR_BLACK;
  var COLOR_TEXT_ADDITIONAL as Lang.Number = Graphics.COLOR_BLACK;
  var COLOR_TEXT_ADDITIONAL2 as Lang.Number = Graphics.COLOR_DK_GRAY;
  var COLOR_TEXT_I as Lang.Number = Graphics.COLOR_WHITE;
  var COLOR_TEXT_I_ADDITIONAL as Lang.Number = Graphics.COLOR_WHITE;
  var COLOR_TEXT_I_ADDITIONAL2 as Lang.Number = Graphics.COLOR_LT_GRAY;

  // var nightMode as Lang.Boolean = false;
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

  var smallField as Lang.Boolean = false;
  var wideField as Lang.Boolean = false;
  var largeField as Lang.Boolean = false;
  var oneField as Lang.Boolean = false;

  var dashesUnderColumnHeight as Lang.Number = 2;

  function initialize() {
    COLOR_TEXT = Graphics.COLOR_BLACK;
    COLOR_TEXT_ADDITIONAL = Graphics.COLOR_BLACK;
    COLOR_TEXT_ADDITIONAL2 = Graphics.COLOR_DK_GRAY;
    COLOR_TEXT_I = Graphics.COLOR_WHITE;
    COLOR_TEXT_I_ADDITIONAL = Graphics.COLOR_WHITE;
    COLOR_TEXT_I_ADDITIONAL2 = Graphics.COLOR_WHITE;
  }

  function detectFieldType(dc as Dc) as Void {
    self.width = dc.getWidth();
    self.height = dc.getHeight();

    self.smallField = true;
    self.wideField = false;
    self.largeField = false;
    self.oneField = false;
    // 1 large field: w[246] h[322]
    // 2 fields: w[246] h[160]
    // 3 fields: w[246] h[106]

    if (width >= 246) {
      self.smallField = false;
      self.wideField = true;

      if (height >= 322) {
        self.wideField = false;
        self.oneField = true;
      } else if (height >= 100) {
        self.wideField = false;
        self.oneField = false;
        self.largeField = true;
      }
    }
  }

  // function setColorMode(nightMode as Boolean) as Void {
  //   self.nightMode = nightMode;
  //   if (self.nightMode) {
  //     COLOR_TEXT = Graphics.COLOR_WHITE;
  //     COLOR_TEXT_ADDITIONAL = Graphics.COLOR_WHITE;
  //     COLOR_TEXT_ADDITIONAL2 = Graphics.COLOR_WHITE;
  //     COLOR_TEXT_I = Graphics.COLOR_BLACK;
  //     COLOR_TEXT_I_ADDITIONAL = Graphics.COLOR_BLACK;
  //     COLOR_TEXT_I_ADDITIONAL2 = Graphics.COLOR_DK_GRAY;
  //   } else {
  //     COLOR_TEXT = Graphics.COLOR_BLACK;
  //     COLOR_TEXT_ADDITIONAL = Graphics.COLOR_BLACK;
  //     COLOR_TEXT_ADDITIONAL2 = Graphics.COLOR_DK_GRAY;
  //     COLOR_TEXT_I = Graphics.COLOR_WHITE;
  //     COLOR_TEXT_I_ADDITIONAL = Graphics.COLOR_WHITE;
  //     COLOR_TEXT_I_ADDITIONAL2 = Graphics.COLOR_WHITE;
  //   }
  // }

  function calculate(
    nrOfColumns as Lang.Number,
    heightWind as Lang.Number,
    heightWc as Lang.Number,
    heightWt as Lang.Number
  ) as Void {
    self.nrOfColumns = nrOfColumns;
    self.heightWind = heightWind;
    self.heightWc = heightWc;
    self.heightWt = heightWt;
    calculateColumnWidth(0);

    if (self.heightWind > 0 || self.heightWc > 0) {
      self.dashesUnderColumnHeight = 0;
    }
  }

  function calculateColumnWidth(offset as Lang.Number) as Void {
    offsetX = offset;
    columnWidth = 0;
    if (nrOfColumns > 0) {
      columnWidth = ((width - offsetX - 2 * margin - (nrOfColumns - 1) * space) / nrOfColumns).toNumber();
    }
    columnY = margin;
    var correction = (
      (width - offsetX - 2 * margin - nrOfColumns * columnWidth - (nrOfColumns - 1) * space) /
      2
    ).toNumber();
    columnX = (margin + correction).toNumber();

    // Height of the weather column, 2 lines for weather condition text
    columnHeight = (height - 2 * margin - heightWind - heightWc - heightWt * 2).toNumber();

    // Position of dashes under columns
    dashesPosY = (columnY + columnHeight).toNumber();
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
    return (margin + columnHeight - columnHeight * (percentage / 100.0)).toNumber();
  }
}
