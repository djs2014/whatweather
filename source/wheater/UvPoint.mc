import Toybox.Lang;
import Toybox.System;

class UvPoint {
  var x as Lang.Number = 0;
  var y as Lang.Number = 0;
  var isHidden as Lang.Boolean;
  var uvi as Lang.Float?;

  function initialize(x as Lang.Number, uvi as Lang.Float?) {
    self.x = x;
    self.uvi = uvi;
    if (uvi != null) {
      y = uvi.toNumber();
    }
    self.isHidden = false;
  }
  function calculateVisible(precipitationChance as Lang.Number?) as Void  {
    if (precipitationChance == null || uvi == null) {
      self.isHidden = true;
    } else {
      self.isHidden = (uvi as Float <= $._hideUVIndexLowerThan) && (precipitationChance > 0);
    }
  }

  function info() as Lang.String {
    return Lang.format("UvPoint: x[$1$] y[$2$] isHidden[$3$]", [ x, y, isHidden ]);
  }
}