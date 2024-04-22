import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Math;
import Toybox.Time.Gregorian;

class RenderWeather {
  hidden var ds as DisplaySettings = new DisplaySettings();

  hidden const TOP_ADDITIONAL_INFO = 1;
  hidden var topAdditionalInfo2 as Lang.Number = 0;

  hidden var yHumTop as Lang.Number = 0;
  hidden var yHumBottom as Lang.Number = 0;
  hidden var yTempTop as Lang.Number = 0;
  hidden var yTempBottom as Lang.Number = 0;

  hidden const NO_BEARING_SPEED = 0.3;
  hidden const COLOR_TEXT_ALERT = Graphics.COLOR_ORANGE;

  // humidity is already percentage
  hidden var maxTemperature as Lang.Number = 50; // celcius
  hidden var maxPressure as Lang.Number = 1080;
  hidden var minPressure as Lang.Number = 870;

  function initialize() {}

  function initValues(dc as Dc, ds as DisplaySettings) as Void {
    self.ds = ds;
    topAdditionalInfo2 = dc.getFontHeight(ds.fontSmall);

    self.maxTemperature = $._maxTemperature;
    self.maxPressure = $._maxPressure;
    self.minPressure = $._minPressure;
    initComfortZones();
    Math.srand(System.getTimer());
  }

  hidden function initComfortZones() as Void {
    var comfort = getComfort();
    self.yHumTop = ds.getYpostion(comfort.humidityMax);
    self.yHumBottom = ds.getYpostion(comfort.humidityMin);
    var perc = $.percentageOf(comfort.temperatureMax, self.maxTemperature).toNumber();
    self.yTempTop = ds.getYpostion(perc);
    perc = $.percentageOf(comfort.temperatureMin, self.maxTemperature).toNumber();
    self.yTempBottom = ds.getYpostion(perc);
  }

  function drawUvIndexGraph(
    dc as Dc,
    uvPoints as Lang.Array,
    maxUvIndex as Lang.Number,
    showDetails as Lang.Boolean,
    blueBarPercentage as Array
  ) as Void {
    try {
      var max = uvPoints.size();
      for (var i = 0; i < max; i += 1) {
        var uvp = uvPoints[i] as UvPoint;
        if (!uvp.isHidden) {
          var x = uvp.x;
          var perc = $.percentageOf(uvp.uvi, maxUvIndex).toNumber();
          var y = ds.getYpostion(perc);
          var r = uviToRadius(uvp.uvi);

          drawUvPoint(dc, x, y, r, uvp.uvi as Float, showDetails);
        }
      }
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  function drawUvPoint(
    dc as Dc,
    x as Lang.Number,
    y as Lang.Number,
    r as Lang.Number,
    uvi as Lang.Float,
    showDetails as Lang.Boolean
  ) as Void {
    var color = uviToColor(uvi);
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    if (showDetails) {
      var h = dc.getFontHeight(Graphics.FONT_TINY);
      dc.drawText(
        x,
        y + h / 2,
        Graphics.FONT_TINY,
        uvi.format("%.1f"),
        Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
      );
    }
    dc.fillCircle(x, y, r);
    var rh = (r + 2) / 2;
    dc.drawLine(x - r - rh, y - r - rh, x + r + rh, y + r + rh);
    dc.drawLine(x + r + rh, y - r - rh, x - r - rh, y + r + rh);
  }

  function drawTemperatureGraph(
    dc as Dc,
    points as Lang.Array,
    showDetails as Lang.Boolean,
    blueBarPercentage as Array
  ) as Void {
    try {
      var devSettings = System.getDeviceSettings();
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i] as WeatherPoint;
        if (!p.isHidden) {
          var x = p.x;
          var perc = $.percentageOf(p.value, self.maxTemperature).toNumber();
          var y = ds.getYpostion(perc);

          if (showDetails && p.value > 10) {
            var yBlueBar = ds.getYpostion((blueBarPercentage[i] as Number).toNumber());
            var h = dc.getFontHeight(Graphics.FONT_TINY);
            if (yBlueBar < y) {
              dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            } else {
              dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
            }
            var temperature = p.value;
            if (devSettings.temperatureUnits == System.UNIT_STATUTE) {
              temperature = $.celciusToFarenheit(temperature);
            }
            dc.drawText(
              x,
              y - h / 2,
              Graphics.FONT_TINY,
              temperature.format("%d"),
              Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
            );
          }

          dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
          dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 1);

          dc.drawRectangle(x - 1, y - 6, 3, 8);
          dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
          dc.drawLine(x, y, x, y - 4);
          dc.fillCircle(x, y + 2, 2);
        }
      }
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  function drawDewpointGraph(
    dc as Dc,
    points as Lang.Array,
    showDetails as Lang.Boolean,
    blueBarPercentage as Array
  ) as Void {
    try {
      var devSettings = System.getDeviceSettings();
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i] as WeatherPoint;
        if (!p.isHidden) {
          var x = p.x;
          var perc = $.percentageOf(p.value, self.maxTemperature).toNumber();
          var y = ds.getYpostion(perc);
          var r = 3;
          var color = dewpointToColor(y.toFloat());

          if (showDetails && p.value > 7) {
            var h = dc.getFontHeight(Graphics.FONT_TINY);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            var dewpoint = p.value;
            if (devSettings.temperatureUnits == System.UNIT_STATUTE) {
              dewpoint = $.celciusToFarenheit(dewpoint);
            }
            dc.drawText(
              x,
              y + h / 2,
              Graphics.FONT_TINY,
              dewpoint.format("%d"),
              Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
            );
          }

          dc.setColor(color, Graphics.COLOR_TRANSPARENT);
          dc.fillCircle(x, y + r - 1, 2);

          dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
          dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 1);
          dc.drawLine(x - r, y, x, y - 5);
          dc.drawLine(x, y - 5, x + r, y);
          dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, 0, 180);
        }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawPressureGraph(
    dc as Dc,
    points as Lang.Array,
    showDetails as Lang.Boolean,
    blueBarPercentage as Array
  ) as Void {
    try {
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i] as WeatherPoint;

        var x = p.x as Number;
        var perc = $.percentageOf(p.value - self.minPressure, self.maxPressure - self.minPressure).toNumber();
        var y = ds.getYpostion(perc).toNumber();

        if (showDetails) {
          var yBlueBar = ds.getYpostion((blueBarPercentage[i] as Number).toNumber());
          var h = dc.getFontHeight(Graphics.FONT_TINY);
          if (yBlueBar < y - h) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
          } else {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
          }
          dc.drawText(
            x,
            y - h / 2,
            Graphics.FONT_XTINY,
            p.value.format("%d"),
            Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
          );
        }

        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 1);
        var pts = [
          [x - 3, y],
          [x, y + 5],
          [x + 3, y],
        ];
        dc.fillPolygon(pts as Polygon);
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawHumidityGraph(
    dc as Dc,
    points as Lang.Array,
    showDetails as Lang.Boolean,
    blueBarPercentage as Array
  ) as Void {
    try {
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i] as WeatherPoint;
        var x = p.x;
        var y = ds.getYpostion(p.value.toNumber()); // value is percentage
        var r = 3;

        if (showDetails) {
          var h = dc.getFontHeight(Graphics.FONT_TINY);
          dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
          dc.drawText(
            x,
            y - h / 2,
            Graphics.FONT_TINY,
            p.value.format("%d"),
            Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
          );
        }

        dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 2);

        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
        var pts = [
          [x - r, y],
          [x, y - 5],
          [x + r, y],
        ];
        dc.fillPolygon(pts as Polygon);
        dc.setPenWidth(r);
        dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, 0, 180);
        dc.setPenWidth(1.0);
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  // top is max (temp/humid), low is min(temp/humid)
  function drawComfortColumn(
    dc as Dc,
    x as Lang.Number,
    temperature as Lang.Numeric?,
    dewpoint as Lang.Float?
  ) as Void {
    var comfort = getComfort();

    var color = dewpointToColor(dewpoint);

    dc.setColor(color, color);
    if (ds.smallField) {
      var percTemperature = $.percentageOf(comfort.temperatureMax, self.maxTemperature).toNumber();
      var yTop = ds.getYpostion($.max(percTemperature, comfort.humidityMax) as Lang.Number);
      percTemperature = $.percentageOf(comfort.temperatureMin, self.maxTemperature).toNumber();
      var yBottom = ds.getYpostion($.min(percTemperature, comfort.humidityMin) as Lang.Number);
      var height = yBottom - yTop;
      dc.fillRectangle(x - ds.space / 2, yTop, ds.columnWidth + ds.space, height);
      return;
    }

    dc.fillRectangle(x - ds.space / 2, self.yHumTop, ds.columnWidth + ds.space, self.yHumBottom - self.yHumTop);
    dc.fillRectangle(x - ds.space / 2, self.yTempTop, ds.columnWidth + ds.space, self.yTempBottom - self.yTempTop);
  }

  function drawComfortBorders(dc as Dc) as Void {
    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
    drawWobblyLine(dc, 0, ds.width, self.yHumTop, 3);
    drawWobblyLine(dc, 0, ds.width, self.yHumBottom, 3);

    dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
    drawWobblyLine(dc, 0, ds.width, self.yTempTop, 3);
    drawWobblyLine(dc, 0, ds.width, self.yTempBottom, 3);
  }

  function drawObservationLocation(dc as Dc, name as Lang.String?) as Void {
    if (name == null || (name as String).length() == 0) {
      return;
    }
    dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
    dc.drawText(ds.margin, TOP_ADDITIONAL_INFO, ds.fontSmall, name, Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawObservationLocationLine2(dc as Dc, name as Lang.String?) as Void {
    if (name == null || (name as String).length() == 0) {
      return;
    }
    dc.setColor(ds.COLOR_TEXT_ADDITIONAL2, Graphics.COLOR_TRANSPARENT);
    dc.drawText(ds.margin, topAdditionalInfo2, ds.fontSmall, name, Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawObservationTime(dc as Dc, observationTime as Time.Moment?) as Void {
    if (observationTime == null) {
      return;
    }

    var observationTimeString = $.getShortTimeString(observationTime);

    var color = ds.COLOR_TEXT_ADDITIONAL;
    if ($.isDelayedFor(observationTime, $._observationTimeDelayedMinutesThreshold)) {
      color = Graphics.COLOR_RED;
    }
    var textW = dc.getTextWidthInPixels(observationTimeString, ds.fontSmall);
    var textX = ds.width - textW - ds.margin;

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(textX, TOP_ADDITIONAL_INFO, ds.fontSmall, observationTimeString, Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawWindInfoFirstColumn(
    dc as Dc,
    windPoints as Array,
    xOffset as Number,
    showLeft as Boolean,
    track as Number?
  ) as Void {
    var max = windPoints.size();
    if (max == 0) {
      return;
    }
    var wp = windPoints[0] as WindPoint;
    var radius = 10;
    var x = xOffset;
    if (showLeft) {
      x = wp.x + ds.columnWidth / 2 - xOffset;
    }
    var y = ds.columnY + ds.columnHeight / 2;

    if (track != null) {
      drawWind(dc, x, y, radius, wp.bearing - (track as Number), wp.speed, wp.gust, true);
    } else {
      drawWind(dc, x, y, radius, wp.bearing, wp.speed, wp.gust, false);
    }
  }

  function drawWindInfo(dc as Dc, windPoints as Array) as Void {
    // if (ds.smallField) { return; }
    var max = windPoints.size();
    for (var idx = 0; idx < max; idx++) {
      var wp = windPoints[idx] as WindPoint;
      // drawWindInfoInColumn(dc, wp.x, wp.bearing, wp.speed, wp.gust);
      // stack overflow in pointoncircle

      var radius = 8;
      var xW = wp.x + ds.columnWidth / 2;
      var yW = ds.columnY + ds.columnHeight + ds.heightWind - ds.heightWind / 2;
      drawWind(dc, xW, yW, radius, wp.bearing, wp.speed, wp.gust, false);
    }
  }

  function drawAlertMessages(dc as Dc, activeAlerts as Lang.String?, onSecondLine as Boolean) as Void {
    if (activeAlerts == null || (activeAlerts as Lang.String).length() <= 0) {
      return;
    }

    dc.setColor(COLOR_TEXT_ALERT, Graphics.COLOR_WHITE);
    var y = TOP_ADDITIONAL_INFO;
    if (onSecondLine) {
      y = topAdditionalInfo2;
    }    
    dc.drawText(ds.width / 2, y, ds.fontSmall, activeAlerts, Graphics.TEXT_JUSTIFY_CENTER);
  }

  function drawAlertMessagesVert(dc as Dc, activeAlerts as Array<String>) as Void {
    var max = activeAlerts.size();
    if (max == 0) {
      return;
    }

    var h = dc.getFontHeight(ds.fontSmall) - 4;
    var y = TOP_ADDITIONAL_INFO;
    dc.setColor(COLOR_TEXT_ALERT, Graphics.COLOR_TRANSPARENT);
    for (var idx = 0; idx < max; idx += 1) {
      var aa = activeAlerts[idx] as String;
      y = y + h;

      var textW = dc.getTextWidthInPixels(aa, ds.fontSmall);
      var textX = ds.width - textW - ds.margin;

      dc.drawText(textX, y, ds.fontSmall, aa, Graphics.TEXT_JUSTIFY_LEFT);
    }
  }

  function drawWeatherConditionText(
    dc as Dc,
    x as Lang.Number,
    condition as Lang.Number,
    yLine as Lang.Number
  ) as Void {
    if (ds.oneField) {
      var text = getWeatherConditionText(condition);
      if (text != null) {
        var yOffset = yLine == null ? 0 : yLine * ds.heightWt;
        dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
          x,
          ds.columnY + ds.columnHeight + ds.heightWind + ds.heightWc + yOffset,
          Graphics.FONT_SYSTEM_XTINY,
          text as String,
          Graphics.TEXT_JUSTIFY_LEFT
        );
      }
    }
  }

  function drawSunsetIndication(dc as Dc, x as Lang.Number) as Void {
    if (!ds.oneField) {
      return;
    }
    var yOffset = ds.heightWt;
    drawMoon(dc, x + ds.columnWidth / 2, ds.columnY + ds.columnHeight + ds.heightWind + ds.heightWc + yOffset, 3);
  }

  function drawWeatherCondition(
    dc as Dc,
    x as Lang.Number,
    condition as Lang.Number,
    nightTime as Lang.Boolean
  ) as Void {
    _drawWeatherCondition(
      dc,
      new Point(x + ds.columnWidth / 2, ds.columnY + ds.columnHeight + ds.heightWind + ds.heightWc / 2 + 2),
      condition,
      nightTime
    );
  }

  function _drawWeatherCondition(
    dc as Dc,
    center as Point,
    condition as Lang.Number,
    nightTime as Lang.Boolean
  ) as Void {
    if (condition == null) {
      return;
    }

    // clear
    if (condition == Weather.CONDITION_FAIR) {
      drawConditionClear(dc, center, 3, 6, 120, nightTime);
      return;
    }
    if (condition == Weather.CONDITION_PARTLY_CLEAR) {
      drawConditionClear(dc, center.move(3, -2), 2, 4, 60, nightTime);
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y + 3, 4));
      return;
    }

    if (condition == Weather.CONDITION_MOSTLY_CLEAR) {
      drawConditionClear(dc, center.move(3, -2), 2, 4, 30, nightTime);
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y + 3, 4));
      return;
    }
    if (condition == Weather.CONDITION_CLEAR) {
      drawConditionClear(dc, center, 3, 6, 30, nightTime);
      return;
    }
    // clouds
    if (condition == Weather.CONDITION_PARTLY_CLOUDY) {
      drawConditionClear(dc, center.move(3, -3), 2, 4, 60, nightTime);
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 4));
      return;
    }
    if (condition == Weather.CONDITION_THIN_CLOUDS) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 4));
      return;
    }
    if (condition == Weather.CONDITION_MOSTLY_CLOUDY) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 6));
      return;
    }
    if (condition == Weather.CONDITION_CLOUDY) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 8));
      return;
    }
    // rain
    if (condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN || condition == Weather.CONDITION_CHANCE_OF_SHOWERS) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(dc, center, 5, 3);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 6));
    }

    if (condition == Weather.CONDITION_DRIZZLE) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(dc, center, 5, 3);
    }

    if (
      condition == Weather.CONDITION_LIGHT_RAIN ||
      condition == Weather.CONDITION_LIGHT_SHOWERS ||
      condition == Weather.CONDITION_SCATTERED_SHOWERS
    ) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(dc, center, 8, 2);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 6));
      return;
    }

    if (condition == Weather.CONDITION_RAIN || condition == Weather.CONDITION_SHOWERS) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(dc, center, 8, 2);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 8));
      return;
    }

    if (condition == Weather.CONDITION_HEAVY_SHOWERS || condition == Weather.CONDITION_HEAVY_RAIN) {
      dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(dc, center, 8, 2);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 8));
      return;
    }

    if (condition == Weather.CONDITION_FREEZING_RAIN) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(dc, center, 8, 2);
      dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 8));
      return;
    }

    // hail
    if (condition == Weather.CONDITION_HAIL) {
      // dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      // dc.fillPolygon(getHailPoints(center, 8));
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(dc, center, 8, 3);
      return;
    }

    if (condition == Weather.CONDITION_WINTRY_MIX || condition == Weather.CONDITION_RAIN_SNOW) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(dc, center.move(-4, 0), 6);
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(dc, center.move(4, 0), 8, 3);
      return;
    }

    if (
      condition == Weather.CONDITION_CHANCE_OF_RAIN_SNOW ||
      condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW ||
      condition == Weather.CONDITION_LIGHT_RAIN_SNOW
    ) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(dc, center.move(-4, 0), 6);
      drawRainDrops(dc, center.move(4, 0), 8, 3);
      return;
    }

    // snow
    if (condition == Weather.CONDITION_CHANCE_OF_SNOW) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(dc, center, 6);
      return;
    }

    if (condition == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(dc, center.move(0, 2), 6);
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 7));
      return;
    }

    if (condition == Weather.CONDITION_FLURRIES || condition == Weather.CONDITION_LIGHT_SNOW) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(dc, center, 6);
      return;
    }

    if (condition == Weather.CONDITION_SNOW) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(dc, center, 8);
      return;
    }

    if (
      condition == Weather.CONDITION_SLEET ||
      condition == Weather.CONDITION_ICE_SNOW ||
      condition == Weather.CONDITION_ICE
    ) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getHailPoints(center, 4));
      dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(dc, center, 8);
      return;
    }

    if (condition == Weather.CONDITION_HEAVY_SNOW || condition == Weather.CONDITION_HEAVY_RAIN_SNOW) {
      dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(dc, center.move(-4, 2), 8);
      drawSnowFlake(dc, center.move(4, -3), 8);
      return;
    }

    // thunder
    if (condition == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS) {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getLightningPts(center, 4));
      return;
    }

    if (condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS) {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getLightningPts(center, 6));
      return;
    }

    if (condition == Weather.CONDITION_THUNDERSTORMS) {
      dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getLightningPts(center.move(-4, -2), 6));
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getLightningPts(center.move(2, 0), 8));
      return;
    }

    if (condition == Weather.CONDITION_TROPICAL_STORM) {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getLightningPts(center.move(-1, 1), 8));
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getLightningPts(center.move(4, 4), 6));
      dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 8));
      return;
    }

    // windy
    if (condition == Weather.CONDITION_WINDY) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawWindIcon(dc, center.x, center.y, 6);
      return;
    }
    // sudden windspeed
    if (condition == Weather.CONDITION_SQUALL) {
      dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
      drawWindIcon(dc, center.x, center.y, 6);
      return;
    }

    // dust
    if (condition == Weather.CONDITION_DUST || condition == Weather.CONDITION_SAND) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawDustIcon(dc, center, 8, 1, 6);
      return;
    }
    // dust, difficult to see
    if (condition == Weather.CONDITION_HAZY || condition == Weather.CONDITION_HAZE) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawMistIcon(dc, center, 10);
      drawDustIcon(dc, center, 8, 1, 8);
      return;
    }

    // sandstorm
    if (condition == Weather.CONDITION_SANDSTORM) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawWindIcon(dc, center.x, center.y, 6);
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawDustIcon(dc, center, 8, 1, 8);
      dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getLightningPts(center, 6));
      return;
    }

    // ash
    if (condition == Weather.CONDITION_VOLCANIC_ASH) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getVulcanoPts(center, 9));
      dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
      drawDustIcon(dc, center, 8, 1, 10);
      return;
    }

    // hurricane
    if (condition == Weather.CONDITION_HURRICANE || condition == Weather.CONDITION_TORNADO) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 9));
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawTornado(dc, center);
      return;
    }

    // smoke
    if (condition == Weather.CONDITION_SMOKE) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.x, center.y, 9));
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawDustIcon(dc, center, 4, 2, 3);
      return;
    }

    // fog
    if (condition == Weather.CONDITION_FOG || condition == Weather.CONDITION_MIST) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawMistIcon(dc, center, 10);
      return;
    }

    // unknown
    if (condition == Weather.CONDITION_UNKNOWN_PRECIPITATION || condition == Weather.CONDITION_UNKNOWN) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        center.x,
        center.y,
        Graphics.FONT_XTINY,
        "?",
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
      return;
    }

    return;
  }

  hidden function drawTornado(dc as Dc, center as Point) as Void {
    dc.drawRectangle(center.x - 3, center.y, 6, 2);
    dc.drawRectangle(center.x, center.y + 2, 4, 2);
    dc.drawRectangle(center.x + 1, center.y + 4, 3, 2);
    dc.drawRectangle(center.x + 1, center.y + 6, 1, 3);
  }

  hidden function getVulcanoPts(center as Point, range as Number) as Polygon {
    var pts = [];

    var halfRange = (range * 0.5).toNumber();
    var p2Range = (range * 0.2).toNumber();
    var p7Range = (range * 0.7).toNumber();

    pts.add([center.x - 2, center.y - halfRange]);
    pts.add([center.x, center.y - halfRange + 1]);
    pts.add([center.x + 2, center.y - halfRange]);

    pts.add([center.x + p2Range, center.y]);

    pts.add([center.x + p7Range, center.y + range]);
    pts.add([center.x - p7Range, center.y + range]);

    pts.add([center.x - p2Range, center.y]);

    return pts as Polygon;
  }

  hidden function drawDustIcon(
    dc as Dc,
    center as Point,
    range as Number,
    size as Number,
    particles as Number
  ) as Void {
    var x, y;
    for (var i = 0; i < particles; i++) {
      if (i % 2 == 0) {
        x = center.x + (Math.rand() % range);
        y = center.y + (Math.rand() % range);
      } else {
        x = center.x - (Math.rand() % range);
        y = center.y - (Math.rand() % range);
      }
      dc.fillCircle(x, y, size);
    }
  }

  hidden function drawWindIcon(dc as Dc, x as Number, y as Number, range as Number) as Void {
    drawWindLineUp(dc, x, y - 2, (range * 0.8).toNumber(), 2, Graphics.ARC_COUNTER_CLOCKWISE);
    drawWindLineUp(dc, x, y, range, 4, Graphics.ARC_COUNTER_CLOCKWISE);
    drawWindLineDown(dc, x + 1, y + 2, (range * 0.7).toNumber(), 2, Graphics.ARC_COUNTER_CLOCKWISE);
  }

  hidden function drawWindLineUp(
    dc as Dc,
    x as Number,
    y as Number,
    range as Number,
    radius as Numeric,
    direction as Graphics.ArcDirection
  ) as Void {
    dc.drawLine(x - range, y, x + range, y);
    dc.drawArc(x + range, y - radius, radius, direction, -90, 160);
  }

  hidden function drawWindLineDown(
    dc as Dc,
    x as Number,
    y as Number,
    range as Number,
    radius as Numeric,
    direction as Graphics.ArcDirection
  ) as Void {
    dc.drawLine(x - range, y, x + range, y);
    dc.drawLine(x - range, y, x + range, y);
    dc.drawArc(x + range, y + radius, radius, Graphics.ARC_COUNTER_CLOCKWISE, -160, 90);
  }

  hidden function drawMistIcon(dc as Dc, center as Point, range as Number) as Void {
    var x1 = center.x - range / 2;
    var x2 = center.x + range / 2;
    var max = center.y + range / 2;
    for (var y = center.y - range / 2; y < max; y = y + 3) {
      drawWobblyLine(dc, x1, x2, y, 2);
    }
  }

  hidden function getLightningPts(center as Point, range as Number) as Polygon {
    var pts = [];

    pts.add([center.x, center.y - range]);
    pts.add([(center.x + range * 0.5).toNumber(), center.y - range]);

    pts.add([center.x + 2, (center.y - range * 0.5).toNumber()]);
    pts.add([center.x + 5, (center.y - range * 0.5).toNumber()]);

    pts.add([center.x - 4, center.y + range]);

    pts.add([center.x, (center.y - range * 0.2).toNumber()]);
    pts.add([center.x - 3, (center.y - range * 0.2).toNumber()]);

    pts.add([center.x - 2, center.y - range]);

    return pts as Polygon;
  }

  hidden function drawSnowFlake(dc as Dc, center as Point, radius as Number) as Void {
    var angle = 0;
    while (angle < 360) {
      var p1 = pointOnCircle(center.x, center.y, radius, angle);
      dc.drawLine(center.x, center.y, p1.x, p1.y);
      angle = angle + 45;
    }
  }

  hidden function getHailPoints(center as Point, radius as Number) as Polygon {
    var pts = [];

    var angle = 0;
    while (angle < 360) {
      var p1 = pointOnCircle(center.x, center.y, radius, angle);
      pts.add([p1.x, p1.y]);
      angle = angle + 60;
    }

    return pts as Polygon;
  }

  hidden function drawRainDrops(dc as Dc, center as Point, range as Number, density as Number) as Void {
    var x1, x2, y1, y2;
    range = range / 2;
    var s = center.x - range;
    var e = center.x + range;
    var x = s;
    y1 = center.y + range;
    y2 = center.y - range;

    while (x < e) {
      x1 = x;
      x2 = x + 3;
      dc.drawLine(x1, y1, x2, y2);
      x = x + density;
    }
  }

  hidden function drawMoon(dc as Dc, x as Number, y as Number, radius as Number) as Void {
    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
    dc.setPenWidth(radius * 1.5);
    dc.drawArc(x, y, radius, Graphics.ARC_COUNTER_CLOCKWISE, 95, 275);
    dc.setPenWidth(1.0);
  }

  hidden function drawConditionClear(
    dc as Dc,
    center as Point,
    radius as Number,
    radiusOuter as Number,
    increment as Number,
    nightTime as Boolean
  ) as Void {
    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
    if (nightTime) {
      drawMoon(dc, center.x, center.y, radius);
      return;
    }
    dc.drawCircle(center.x, center.y, radius);
    if (increment <= 0) {
      return;
    }
    var angle = 0;
    while (angle < 360) {
      var p1 = pointOnCircle(center.x, center.y, radius, angle);
      var p2 = pointOnCircle(center.x, center.y, radiusOuter, angle);
      dc.drawLine(p1.x, p1.y, p2.x, p2.y);
      angle = angle + increment;
    }
  }

  // --
  hidden function drawWind(
    dc as Dc,
    x as Number,
    y as Number,
    radius as Number,
    windBearingInDegrees as Number,
    windSpeedMs as Float,
    windGustMs as Float,
    bigArrow as Boolean
  ) as Void {
    var hasAlert = false;
    var text = "";
    var wsFont = Graphics.FONT_XTINY;
    var wsFontAlert = Graphics.FONT_TINY;
    var windGustLevel = 0;
    var hasGustAlert = false;
    if (radius >= 10) {
      wsFont = Graphics.FONT_SMALL;
      wsFontAlert = Graphics.FONT_MEDIUM;
    }
    if (windSpeedMs != null) {
      var beaufort = $.windSpeedToBeaufort(windSpeedMs);
      hasAlert = $._alertLevelWindSpeed > 0 && beaufort >= $._alertLevelWindSpeed;
      if ($._showWind == SHOW_WIND_BEAUFORT) {
        text = beaufort.format("%d");
      } else {
        var value = windSpeedMs;
        if ($._showWind == SHOW_WIND_KILOMETERS) {
          value = $.mpsToKmPerHour(windSpeedMs);
          var devSettings = System.getDeviceSettings();
          if (devSettings.distanceUnits == System.UNIT_STATUTE) {
            value = $.kilometerToMile(value);
          }
        }
        value = Math.round(value);
        if (value < 10) {
          text = value.format("%.1f");
        } else {
          text = value.format("%d");
        }
      }
      radius = $.min(radius, dc.getTextWidthInPixels(text, wsFont)) + 1;
      //radius = $.max(radius, dc.getTextWidthInPixels(text, wsFont)) + 1;
      if (windGustMs > 0) {
        windGustLevel = $.getWindGustLevel(windSpeedMs, windGustMs);
        hasGustAlert = $._alertLevelWindGust > 0 && windGustLevel >= $._alertLevelWindGust;
      }
    }

    dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
    // Bearing arrow
    if (windBearingInDegrees != null && windSpeedMs != null && windSpeedMs > NO_BEARING_SPEED) {
      // Correction 0 is horizontal, should be North so -90 degrees
      // Wind comes from x but goes to y (opposite) direction so +160 degrees
      windBearingInDegrees = windBearingInDegrees + 90;

      if (hasAlert) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      } else {
        dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
      }
      var pA, pB, pC, pD;
      var gustOuter = 0;
      var gustInner = 0;
      var factor = 0;
      if (bigArrow) {
        factor = (windSpeedMs / 8.0) * 2.0; // 4 BF @@ only when showing in center of field
        // @@ max height / width based on screen
        pA = pointOnCircle(x, y, factor + radius * 2.4, windBearingInDegrees - 35 - 180);
        pB = pointOnCircle(x, y, factor + radius * 1.5, windBearingInDegrees - 180);
        pC = pointOnCircle(x, y, factor + radius * 2.4, windBearingInDegrees + 35 - 180);
        pD = pointOnCircle(x, y, factor + radius * 3.0, windBearingInDegrees);

        gustOuter = 2.4;
        gustInner = 1.8;
      } else {
        pA = pointOnCircle(x, y, radius * 1.5, windBearingInDegrees - 35 - 180);
        pB = pointOnCircle(x, y, radius * 1.0, windBearingInDegrees - 180);
        pC = pointOnCircle(x, y, radius * 1.5, windBearingInDegrees + 35 - 180);
        pD = pointOnCircle(x, y, radius * 1.9, windBearingInDegrees);

        gustOuter = 1.5;
        gustInner = 1.2;
      }
      dc.fillPolygon([pA.toPoint2D(), pB.toPoint2D(), pC.toPoint2D(), pD.toPoint2D()] as Polygon);

      if (windGustLevel >= 1) {
        if (hasGustAlert) {
          dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else {
          dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
        }

        factor = factor + 2;
        pA = pointOnCircle(x, y, factor + radius * gustOuter, windBearingInDegrees - 30 - 180);
        pB = pointOnCircle(x, y, factor + radius * gustInner, windBearingInDegrees - 180);
        pC = pointOnCircle(x, y, factor + radius * gustOuter, windBearingInDegrees + 30 - 180);
        dc.fillPolygon([pA.toPoint2D(), pB.toPoint2D(), pC.toPoint2D()] as Polygon);
        if (windGustLevel >= 2) {
          factor = factor + 3;
          pA = pointOnCircle(x, y, factor + radius * gustOuter, windBearingInDegrees - 30 - 180);
          pB = pointOnCircle(x, y, factor + radius * gustInner, windBearingInDegrees - 180);
          pC = pointOnCircle(x, y, factor + radius * gustOuter, windBearingInDegrees + 30 - 180);
          dc.fillPolygon([pA.toPoint2D(), pB.toPoint2D(), pC.toPoint2D()] as Polygon);
        }
        if (windGustLevel >= 3) {
          factor = factor + 3;
          pA = pointOnCircle(x, y, factor + radius * gustOuter, windBearingInDegrees - 30 - 180);
          pB = pointOnCircle(x, y, factor + radius * gustInner, windBearingInDegrees - 180);
          pC = pointOnCircle(x, y, factor + radius * gustOuter, windBearingInDegrees + 30 - 180);
          dc.fillPolygon([pA.toPoint2D(), pB.toPoint2D(), pC.toPoint2D()] as Polygon);
        }
      }
    }

    // The circle
    dc.drawCircle(x, y, radius);
    if (hasAlert) {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    } else {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
    dc.fillCircle(x, y, radius - 1);

    // Windspeed

    if (hasAlert) {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      wsFont = wsFontAlert;
    } else {
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    }
    dc.drawText(x, y, wsFont, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
  }

  // hidden function drawPolygon(dc, data as Array<Point2D>) {
  //   for (var i = 0; i < data.size(); i++) {
  //     var pA = data[i] as Point2D;
  //     var pB = data[(i + 1) % data.size()] as Point2D;
  //     dc.drawLine(pA[0], pA[1], pB[0], pB[1]);
  //   }
  // }

  hidden function pointOnCircle(
    x as Number,
    y as Number,
    radius as Lang.Numeric,
    angleInDegrees as Lang.Numeric
  ) as Point {
    // Convert from degrees to radians
    var xP = radius * Math.cos((angleInDegrees * Math.PI) / 180) + x;
    var yP = radius * Math.sin((angleInDegrees * Math.PI) / 180) + y;

    return new Point(xP.toNumber(), yP.toNumber());
  }

  // @@TODO onlayout -> get array of points
  hidden function drawWobblyLine(dc as Dc, x1 as Number, x2 as Number, y as Number, increment as Number) as Void {
    var x = x1;
    while (x <= x2) {
      //var y1 = y + Math.sin(x);
      var y1 = y + (Math.rand() % 2);
      dc.drawPoint(x, y1);
      x = x + increment;
    }
  }

  hidden function getCloudPoints(x as Number, y as Number, radius as Number) as Polygon {
    var pts = [];
    var p;
    var xLeft = x - (radius * 0.9).toNumber();
    var d = -180;
    while (d <= -90) {
      p = pointOnCircle(xLeft, y, radius * 0.3, d);
      pts.add([p.x, p.y]);
      d = d + 10;
    }

    d = -180;
    while (d <= 0) {
      p = pointOnCircle(x, y, radius, d);
      pts.add([p.x, p.y]);
      d = d + 10;
    }

    var xRight = x + (radius * 0.9).toNumber();
    d = -90;
    while (d <= 0) {
      p = pointOnCircle(xRight, y, radius * 0.6, d);
      pts.add([p.x, p.y]);
      d = d + 10;
    }

    return pts as Polygon;
  }
}
