import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Math;

class WindPoint {
  var x as Lang.Number = 0;
  var bearing as Lang.Number = 0;
  // meter per second
  var speed as Lang.Float = 0.0f;
  var convertedSpeed as Lang.Float = 0.0f;
  var speedAlert as Boolean = false;
  var gust as Lang.Float = 0.0f;
  var gustLevel as Lang.Number = 0;
  var gustAlert as Boolean = false;

  function initialize(
    bearing as Lang.Number?,
    speed as Lang.Float?,
    speedAlert as Boolean,
    gust as Lang.Float?,
    gustAlert as Boolean
  ) {
    if (bearing != null) {
      self.bearing = bearing;
    }
    if (speed != null) {
      self.speed = speed;
    }
    self.speedAlert = speedAlert;
    if (gust != null) {
      self.gust = gust;
    }

    self.gustLevel = Wind.calculateOptimalGustLevel(self.speed, self.gust, false);  
    self.gustAlert = gustAlert;
  }

  function hasAlert() as Boolean {
    //debug();
    return speedAlert || gustAlert;
  }

  function debug() as Void {
    System.println([
      "wp",
      x,
      bearing,
      speed,
      convertedSpeed,
      speedAlert,
      gust,
      gustLevel,
      gustAlert,
    ]);
  }
  // Display text
  var text as String = "";

  function setXposition(x as Number) as Void {
    self.x = x;
  }

  function setConvertedSpeed(windUnit as Number) as Void {
    if (speed == null) {
      convertedSpeed = 0.0f;
      return;
    }
    if (windUnit == SHOW_WIND_KILOMETERS) {
      convertedSpeed = $.mpsToKmPerHour(speed);
    } else if ($._alertWindIn == SHOW_WIND_METERS) {
      convertedSpeed = speed;
    } else {
      convertedSpeed = $.windSpeedToBeaufort(speed).toFloat() as Float;
    }
  }

  function setUIelements(windUnit as Number) as Void {
    if (speed == null) {
      convertedSpeed = 0.0f;
      return;
    }

    // Show 1.1 m/s or 1 Beaufort or 10 m/s
    // TODO 10.0 remove the 0
    if (windUnit == SHOW_WIND_KILOMETERS) {
      convertedSpeed = $.mpsToKmPerHour(speed);
      if (convertedSpeed >= 10) {
        text = Math.round(convertedSpeed).format("%d");
      } else {
        text = convertedSpeed.format("%.1f");
      }
    } else if (windUnit == SHOW_WIND_METERS) {
      convertedSpeed = speed;
      if (convertedSpeed >= 10) {
        text = Math.round(convertedSpeed).format("%d");
      } else {
        text = convertedSpeed.format("%.1f");
      }
    } else {
      convertedSpeed = $.windSpeedToBeaufort(speed).toFloat() as Float;
      text = convertedSpeed.format("%d");
    }
    var decimal = $.stringRight(text, ".", "");
    if (decimal == "0") {
      text = $.stringLeft(text, ".", text);
    }
  }
}