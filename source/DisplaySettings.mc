import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

class DisplaySettings
{
  protected var dc;
  public var font = Graphics.FONT_LARGE;
  public var fontSmall = Graphics.FONT_XTINY;

  public var COLOR_TEXT = Graphics.COLOR_BLACK;
  public var COLOR_TEXT_ADDITIONAL = Graphics.COLOR_BLACK;
  public var COLOR_TEXT_ADDITIONAL2 = Graphics.COLOR_DK_GRAY;

  public var nightMode = false;
  public var width = 0;
  public var height = 0;
  public var nrOfColumns = 0;

  public var margin = 5;
  public var space = 2;

  public var offsetX = 0;
  public var columnWidth = 10;
  public var columnHeight = 0;

  public var columnY = 0;
  public var columnX = 0;

  public var smallField = false;
  private var backgroundColor;

  public function initialize() {}


  public function calculateLayout( dc as Dc) {
    self.dc = dc;
    self.width = dc.getWidth();
    self.height = dc.getHeight();
    self.smallField = self.height < 80;
    // 1 large field: w[246] h[322] 
    // 2 fields: w[246] h[160] 
    // 3 fields: w[246] h[106] 
  }

  public function setDc( dc as Dc, backgroundColor) {
    self.dc = dc;
    self.width = dc.getWidth();
    self.height = dc.getHeight();
    self.smallField = self.height < 80;
    self.backgroundColor = backgroundColor;
    nightMode = (backgroundColor == Graphics.COLOR_BLACK);
    setColors();
  }

  private function setColors() {
    if (nightMode) {
      COLOR_TEXT = Graphics.COLOR_WHITE;
      COLOR_TEXT_ADDITIONAL = Graphics.COLOR_WHITE;
      COLOR_TEXT_ADDITIONAL2 = Graphics.COLOR_WHITE;
    }
  }

  public function clearScreen() {
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
    if (nrOfColumns > 0) {columnWidth = (width - offsetX - (2 * margin) - (nrOfColumns - 1) * space) / nrOfColumns; }
    columnHeight = height - 2 * margin;

    columnY = margin;
    var correction = (width - offsetX - (2 * margin) - (nrOfColumns * columnWidth) - (nrOfColumns - 1) * space )/2;
    columnX = margin + correction;
  }

  public function info() {
    return Lang.format("w[$1$] h[$2$] #c[$3$] offset[$4$] cw[$5$] ch[$6$]",[width, height, nrOfColumns, offsetX, columnWidth, columnHeight]);
  }

  //! Get correct y position based on a percentage
  public function getYpostion(percentage) {
    return margin + columnHeight - (columnHeight * (percentage / 100.0));
  }
}