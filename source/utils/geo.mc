import Toybox.System;
import Toybox.Math;
import Toybox.Lang;
import Toybox.Activity;

public class Geo {  
  public static function getHeadingDegrees(
    info as Activity.Info?,
    previousHeading as Number?    
  ) as Number? {
    if (info == null) {
      return previousHeading;
    }

    // Preferred: GPS Track (Course Over Ground)
    var headingRad = info.track;
    // Fallback: Magnetic/IMU heading (orientation of the bike frame)
    if (headingRad == null || headingRad == 0.0f) {
      headingRad = info.currentHeading;
    }

    // Convert radians [-PI, PI] to degrees [0, 360)
    if (headingRad != null && headingRad != 0.0f) {
      var deg = Math.toDegrees(headingRad);
      if (deg < 0) {
        deg += 360.0f;
      }
      return deg.toNumber();
    }

    // Final fallback: previous heading
    return previousHeading;
  }
}
