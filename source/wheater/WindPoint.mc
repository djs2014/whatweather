import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Math;

class WindPoint {
  var x as Lang.Number = 0;
  var bearing as Lang.Number = 0;
  var speed as Lang.Float = 0.0;
  var convertedSpeed as Lang.Float = 0.0;
  var speedAlert as Boolean = false;
  var gust as Lang.Float = 0.0;
  var gustLevel as Lang.Number = 0;
  var gustAlert as Boolean = false;

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
  }

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
    if (speed == null) {
      return;
    }
    self.speed = speed; // meter per second
    self.speedAlert = speedAlert;
    if (gust == null) {
      return;
    }
    self.gust = gust;
    gustLevel = $.getWindGustLevel(self.speed, self.gust);
    self.gustAlert = gustAlert;
  }
}

function getWindGustLevel(windSpeedMs as Lang.Float, windGustMs as Lang.Float) as Number {
  var windGustDiff = 0;
  var level = 0;
  if (windGustMs > 0) {
    windGustDiff = windGustMs - windSpeedMs;
    if (windGustDiff > 12.8) {
      level = 3;
    } else if (windGustDiff > 7.7) {
      level = 2;
    } else if (windGustDiff > 5.1) {
      level = 1;
    }
  }
  // System.println("gust: " + level)
  return level;
}
