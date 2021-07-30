import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

class DisplaySettings {
  hidden var dc;
  var font = Graphics.FONT_LARGE;
  var fontSmall = Graphics.FONT_XTINY;

  var COLOR_TEXT = Graphics.COLOR_BLACK;
  var COLOR_TEXT_ADDITIONAL = Graphics.COLOR_BLACK;
  var COLOR_TEXT_ADDITIONAL2 = Graphics.COLOR_DK_GRAY;
  var COLOR_TEXT_I = Graphics.COLOR_WHITE;
  var COLOR_TEXT_I_ADDITIONAL = Graphics.COLOR_WHITE;
  var COLOR_TEXT_I_ADDITIONAL2 = Graphics.COLOR_LT_GRAY;

  var nightMode = false;
  var width = 0;
  var height = 0;
  var nrOfColumns = 0;

  var margin = 5;
  var space = 2;

  var offsetX = 0;
  var columnWidth = 10;
  var columnHeight = 0;

  var columnY = 0;
  var columnX = 0;

  var smallField = false;
  hidden var backgroundColor;

  function initialize() {}

  function calculateLayout(dc as Dc) {
    self.dc = dc;
    self.width = dc.getWidth();
    self.height = dc.getHeight();
    self.smallField = self.height < 80;
    // 1 large field: w[246] h[322]
    // 2 fields: w[246] h[160]
    // 3 fields: w[246] h[106]
  }

  function setDc(dc as Dc, backgroundColor) {
    self.dc = dc;
    self.width = dc.getWidth();
    self.height = dc.getHeight();
    self.smallField = self.height < 80;
    self.backgroundColor = backgroundColor;
    nightMode = (backgroundColor == Graphics.COLOR_BLACK);
    setColors();
  }

  hidden function setColors() {
    if (nightMode) {
      COLOR_TEXT = Graphics.COLOR_WHITE;
      COLOR_TEXT_ADDITIONAL = Graphics.COLOR_WHITE;
      COLOR_TEXT_ADDITIONAL2 = Graphics.COLOR_WHITE;
      COLOR_TEXT_I = Graphics.COLOR_BLACK;
      COLOR_TEXT_I_ADDITIONAL = Graphics.COLOR_BLACK;
      COLOR_TEXT_I_ADDITIONAL2 = Graphics.COLOR_DK_GRAY;
    }
  }

  function clearScreen() {
    dc.setColor(backgroundColor, backgroundColor);
    dc.clear();
  }

  function calculate(columns) {
    nrOfColumns = columns;
    calculateColumnWidth(0);
  }

  function calculateColumnWidth(offset) {
    offsetX = offset;
    columnWidth = 0;
    if (nrOfColumns > 0) {
      columnWidth =
          (width - offsetX - (2 * margin) - (nrOfColumns - 1) * space) /
          nrOfColumns;
    }
    columnHeight = height - 2 * margin;

    columnY = margin;
    var correction = (width - offsetX - (2 * margin) -
                      (nrOfColumns * columnWidth) - (nrOfColumns - 1) * space) /
                     2;
    columnX = margin + correction;
  }

  function info() {
    return Lang.format(
        "w[$1$] h[$2$] #c[$3$] offset[$4$] cw[$5$] ch[$6$]",
        [ width, height, nrOfColumns, offsetX, columnWidth, columnHeight ]);
  }

  //! Get correct y position based on a percentage
  function getYpostion(percentage) {
    return margin + columnHeight - (columnHeight * (percentage / 100.0));
  }
}