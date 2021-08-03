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

  hidden var yHumTop = 0;
  hidden var yHumBottom = 0;
  hidden var yTempTop = 0;
  hidden var yTempBottom = 0;

  hidden const NO_BEARING_SPEED = 0.3;

  function initialize(dc as Dc, ds as DisplaySettings) {
    self.dc = dc;
    self.ds = ds;
    topAdditionalInfo2 = dc.getFontHeight(ds.fontSmall);
    self.devSettings = System.getDeviceSettings();
    initComfortZones();
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
    if (ds.smallField) {
      return;
    }
    try {
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i];

        var x = p.x;
        var y = ds.getYpostion(p.y * factor);

        // if ($._showWind && p.y < $._hideTemperatureLowerThan) {
        //   dc.setColor(ds.COLOR_TEXT_ADDITIONAL2, Graphics.COLOR_TRANSPARENT);
        //   dc.drawCircle(x, y, 3);
        //   dc.setColor(ds.COLOR_TEXT_I, Graphics.COLOR_TRANSPARENT);
        //   dc.fillCircle(x, y, 2);
        // } else {
        dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 1);
        dc.drawCircle(x, y, 3);
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 2);
        // }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawHumidityGraph(points as Lang.Array, factor as Lang.Number) {
    if (ds.smallField) {
      return;
    }
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

  // top is max (temp/humid), low is min(temp/humid)
  function drawComfortColumn(x, temperature, relativeHumidity,
                             precipitationChance) {
    var idx =
        convertToComfort(temperature, relativeHumidity, precipitationChance);
    // System.println("Comfort x[" + x + "] comfort: " + idx);
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
    if (ds.smallField) {
      var yTop =
          ds.getYpostion(max($._comfortTemperature[1], $._comfortHumidity[1]));
      var yBottom =
          ds.getYpostion(min($._comfortTemperature[0], $._comfortHumidity[0]));
      var height = yBottom - yTop;
      dc.fillRectangle(x - ds.space / 2, yTop, ds.columnWidth + ds.space,
                       height);
      return;
    }

    dc.fillRectangle(x - ds.space / 2, self.yHumTop, ds.columnWidth + ds.space,
                     self.yHumBottom - self.yHumTop);
    dc.fillRectangle(x - ds.space / 2, self.yTempTop, ds.columnWidth + ds.space,
                     self.yTempBottom - self.yTempTop);
  }

  function drawComfortZones() {
    if (ds.smallField) {
      return;
    }
    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
    drawWobblyLine(self.yHumTop);
    drawWobblyLine(self.yHumBottom);

    dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
    drawWobblyLine(self.yTempTop);
    drawWobblyLine(self.yTempBottom);
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

  function drawWindInfo(windPoints) {
    if (ds.smallField) {
      return;
    }
    var max = windPoints.size();
    for (var idx = 0; idx < max; idx++) {
      var wp = windPoints[idx];
      drawWindInfoInColumn(wp.x, wp.bearing, wp.speed);
    }
  }

  function drawWindInfoInColumn(x, windBearingInDegrees, windSpeed) {
    if (ds.smallField) {
      return;
    }
    var radius = 8;
    // var center =
    //     new Point(x + ds.columnWidth / 2,
    //               ds.columnY + ds.columnHeight - radius - (radius / 2));
    var center = new Point(
        x + ds.columnWidth / 2,
        ds.columnY + ds.columnHeight + ds.heightWind - ds.heightWind / 2);

    drawWind(center, radius, windBearingInDegrees, windSpeed);
  }

  function drawAlertMessages(activeAlerts) {
    if (ds.smallField) {
      return;
    }

    if (activeAlerts == null || activeAlerts.length() <= 0) {
      return;
    }

    dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(ds.width / 2, 10, ds.fontSmall, activeAlerts,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
  }

  function drawWeatherCondition(x, condition) {
    if (condition == null || ds.smallField) {
      return;
    }
    var center =
        new Point(x + ds.columnWidth / 2, ds.columnY + ds.columnHeight +
                                              ds.heightWind + ds.heightWc / 2);
    // clear                                    
    if (condition == Weather.CONDITION_FAIR) {
      drawConditionClear(center, 3, 6, 0);
      return;
    }        
    if (condition == Weather.CONDITION_MOSTLY_CLEAR || condition == Weather.CONDITION_PARTLY_CLEAR) {
      drawConditionClear(center, 3, 6, 30);
      return;
    }                                      
    if (condition == Weather.CONDITION_CLEAR) {
      drawConditionClear(center, 3, 6, 30);
      return;
    }
    // clouds
    if (condition ==Weather.CONDITION_THIN_CLOUDS || condition == Weather.CONDITION_PARTLY_CLOUDY) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 4));
      return;
    }
    if (condition ==Weather.CONDITION_MOSTLY_CLOUDY) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 6));
      return;
    }
    if (condition == Weather.CONDITION_CLOUDY) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 8));
      return;
    }
      
  }

  hidden function drawConditionClear(center as Point, radius, radiusOuter,
                                     increment) {
    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
    dc.drawCircle(center.x, center.y, radius);
    if (increment <= 0) {
      increment = 30;
    }
    var angle = 0;
    while (angle < 360) {
      var p1 = pointOnCircle(radius, angle, center);
      var p2 = pointOnCircle(radiusOuter, angle, center);
      dc.drawLine(p1.x, p1.y, p2.x, p2.y);
      angle = angle + increment;
    }
  }

  // --
  hidden function drawWind(center as Point, radius, windBearingInDegrees,
                           windSpeedMs) {
    var hasAlert = false;
    var text = "";
    if (windSpeedMs != null) {
      var beaufort = windSpeedToBeaufort(windSpeedMs);
      hasAlert =
          ($._alertLevelWindSpeed > 0 && beaufort >= $._alertLevelWindSpeed);
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
        } else {
          text = value.format("%d");
        }
      }
      radius =
          min(radius, dc.getTextWidthInPixels(text, Graphics.FONT_XTINY)) + 1;
    }

    // The circle
    dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
    if (hasAlert) {
      dc.fillCircle(center.x, center.y, radius);
    } else {
      dc.drawCircle(center.x, center.y, radius);
    }
    // Bearing arrow
    if (windBearingInDegrees != null && ( windSpeedMs != null && windSpeedMs > NO_BEARING_SPEED)) {
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
    // Windspeed
    if (hasAlert) {
      dc.setColor(ds.COLOR_TEXT_I_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
    }
    dc.drawText(center.x, center.y, Graphics.FONT_XTINY, text,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
  }

  hidden function pointOnCircle(radius, angleInDegrees,
                                center as Point) as Point {
    // Convert from degrees to radians
    var x = (radius * Math.cos(angleInDegrees * Math.PI / 180)) + center.x;
    var y = (radius * Math.sin(angleInDegrees * Math.PI / 180)) + center.y;

    return new Point(x, y);
  }

  hidden function drawWobblyLine(y as Lang.Number) {
    var max = ds.width;
    for (var x = 0; x < max; x++) {
      var y1 = y + Math.sin(x);
      dc.drawPoint(x, y1);
    }
  }

  hidden function initComfortZones() {
    self.yHumTop = ds.getYpostion($._comfortHumidity[1]);
    self.yHumBottom = ds.getYpostion($._comfortHumidity[0]);
    self.yTempTop = ds.getYpostion($._comfortTemperature[1]);
    self.yTempBottom = ds.getYpostion($._comfortTemperature[0]);
  }

  hidden function getCloudPoints(center as Point, radius) {
    var pts = [];
    var p;
    var cLeft = center.move(-radius * 0.9, 0);
    var d = -180;
    while (d <= -90) {
      p = pointOnCircle(radius * 0.3, d, cLeft);
      pts.add([ p.x, p.y ]);
      d = d + 10;
    }

    d = -180;
    while (d <= 0) {
      p = pointOnCircle(radius, d, center);
      pts.add([ p.x, p.y ]);
      d = d + 10;
    }

    var cRight = center.move(radius * 0.9, 0);
    d = -90;
    while (d <= 0) {
      p = pointOnCircle(radius * 0.6, d, cRight);
      pts.add([ p.x, p.y ]);
      d = d + 10;
    }

    return pts;
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
  function move(x, y) { return new Point(self.x + x, self.y + y); }
}