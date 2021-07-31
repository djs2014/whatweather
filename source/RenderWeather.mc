import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Math;
using Toybox.Time.Gregorian as Calendar;

class RenderWeather {
  hidden var dc as Dc;
  hidden var ds as DisplaySettings;
  hidden var devSettings as DeviceSettings;

  hidden const TOP_ADDITIONAL_INFO = 1;
  hidden var topAdditionalInfo2;

  function initialize(dc as Dc, ds as DisplaySettings) {
    self.dc = dc;
    self.ds = ds;
    topAdditionalInfo2 = dc.getFontHeight(ds.fontSmall);
    self.devSettings = System.getDeviceSettings();
  }

  function drawUvIndexGraph(uvPoints as Lang.Array, factor as Lang.Number) {
    try {
      var max = uvPoints.size();
      for (var i = 0; i < max; i += 1) {
        var uvp = uvPoints[i];
        // System.println(uvp.info());
        if (!uvp.isHidden) {
          var x = uvp.x;
          var y = ds.getYpostion(uvp.y * factor);
          dc.setColor(uviToColor(uvp.uvi), Graphics.COLOR_TRANSPARENT);
          dc.fillCircle(x, y, 3);
        }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawTemperatureGraph(points as Lang.Array, factor as Lang.Number) {
    try {
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i];
        var x = p.x;
        var y = ds.getYpostion(p.y * factor);
        dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 1);
        dc.drawCircle(x, y, 3);
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 2);
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawHumidityGraph(points as Lang.Array, factor as Lang.Number) {
    try {
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i];
        var x = p.x;
        var y = ds.getYpostion(p.y * factor);
        
        dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 2);
        dc.drawCircle(x, y, 3);
        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 2);

      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawComfortColumn(x, temperature, relativeHumidity,
                             precipitationChance) {
    var idx =
        convertToComfort(temperature, relativeHumidity, precipitationChance);
    System.println("Comfort " + idx);
    if (idx == COMFORT_NO) {
      return;
    }
    var color = COLOR_WHITE_GREEN;
    if (idx == COMFORT_NORMAL) {
      color = COLOR_WHITE_YELLOW;
    } else if (idx == COMFORT_HIGH) {
      color = COLOR_WHITE_ORANGE;
    }

    dc.setColor(color, color);
    dc.fillRectangle(x - + ds.space / 2, ds.columnY, ds.columnWidth + ds.space, ds.columnHeight);
  }

  function drawObservationLocation(name as Lang.String) {
    if (name == null || name.length() == 0) {
      return;
    }
    dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
    dc.drawText(ds.margin, TOP_ADDITIONAL_INFO, ds.fontSmall, name,
                Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawObservationLocation2(name as Lang.String) {
    // Hide on small screen
    if (name == null || name.length() == 0 || ds.smallField) {
      return;
    }
    dc.setColor(ds.COLOR_TEXT_ADDITIONAL2, Graphics.COLOR_TRANSPARENT);
    dc.drawText(ds.margin, topAdditionalInfo2, ds.fontSmall, name,
                Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawObservationTime(observationTime as Time.Moment) {
    if (observationTime == null) {
      return;
    }

    var observationTimeString = getShortTimeString(observationTime);

    var color = ds.COLOR_TEXT_ADDITIONAL;
    if (isDelayedFor(observationTime,
                     $._observationTimeDelayedMinutesThreshold)) {
      color = Graphics.COLOR_RED;
    }
    var textW = dc.getTextWidthInPixels(observationTimeString, ds.fontSmall);
    var textX = ds.width - textW - ds.margin;

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(textX, TOP_ADDITIONAL_INFO, ds.fontSmall, observationTimeString,
                Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawWindInfoInColumn(x, windBearingInDegrees, windSpeed) {
    if (ds.smallField) {
      return;
    }
    var radius = 8;
    var center =
        new Point(x + ds.columnWidth / 2,
                  ds.columnY + ds.columnHeight - radius - (radius / 2));
    drawWind(center, radius, windBearingInDegrees, windSpeed);
  }

  // --
  hidden function drawWind(center as Point, radius, windBearingInDegrees,
                           windSpeedMs) {
    var hasAlert = false;
    if (windSpeedMs != null) {
      var beaufort = windSpeedToBeaufort(windSpeedMs);
      hasAlert =
          ($._alertLevelWindSpeed > 0 && beaufort >= $._alertLevelWindSpeed);
      var text = "";
      if ($._showWind == SHOW_WIND_BEAUFORT) {
        text = beaufort.format("%d");
      } else {
        var value = windSpeedMs;
        if ($._showWind == SHOW_WIND_KILOMETERS) {
          value = windSpeedToKmPerHour(windSpeedMs);
          if (devSettings.distanceUnits == System.UNIT_STATUTE) {
            value = kilometerToMile(value);
          }
        }
        value = Math.round(value);
        if (value < 10) {
          text = value.format("%.1f");
          radius = radius + 2;
        } else {
          text = value.format("%d");
        }
      }

      dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
      if (hasAlert) {
        dc.fillCircle(center.x, center.y, radius);
        dc.setColor(ds.COLOR_TEXT_I_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
      }
      dc.drawText(center.x, center.y, Graphics.FONT_XTINY, text,
                  Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    if (!hasAlert) {
      dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
      dc.drawCircle(center.x, center.y, radius);
    }
    // Bearing
    if (windBearingInDegrees != null) {
      // Correction 0 is horizontal, should be North so -90 degrees
      // Wind comes from x but goes to y (opposite) direction so +160 degrees
      windBearingInDegrees = windBearingInDegrees + 90;

      var pTop = (radius / 2);
      if (hasAlert) {
        pTop = radius - 2;
      }
      var pA = pointOnCircle(radius, windBearingInDegrees - 30, center);
      var pB = pointOnCircle(radius + pTop, windBearingInDegrees, center);
      var pC = pointOnCircle(radius, windBearingInDegrees + 30, center);
      var pts = [ pA.asArray(), pB.asArray(), pC.asArray() ];
      dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(pts);
    }
  }

  hidden function pointOnCircle(radius, angleInDegrees,
                                center as Point) as Point {
    // Convert from degrees to radians
    var x = (radius * Math.cos(angleInDegrees * Math.PI / 180)) + center.x;
    var y = (radius * Math.sin(angleInDegrees * Math.PI / 180)) + center.y;

    return new Point(x, y);
  }
}

class Point {
  var x;
  var y;
  function initialize(x, y) {
    self.x = x;
    self.y = y;
  }
  function asArray() { return [ x, y ]; }
}