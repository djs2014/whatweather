import Toybox.Lang;
import Toybox.System;

class UvPoint {
  var x;
  var y;
  var isHidden;
  var uvi;

  function initialize(x as Number, uvi as Number) {
    self.x = x;
    self.uvi = uvi;
    y = uvi;
    self.isHidden = false;
  }
  function calculateVisible(precipitationChance) {
    self.isHidden =
        (uvi <= $._hideUVIndexLowerThan) && (precipitationChance > 0);
  }

  function info() {
    return Lang.format("UvPoint: x[$1$] y[$2$] isHidden[$3$]",
                       [ x, y, isHidden ]);
  }
}