import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Math;
import Toybox.Time.Gregorian;
using WhatAppBase.Utils as Utils;

class RenderWeather {
  hidden var dc as Dc;
  hidden var ds as DisplaySettings;
  hidden var devSettings as DeviceSettings;

  hidden const TOP_ADDITIONAL_INFO = 1;
  hidden var topAdditionalInfo2 as Lang.Number = 0;

  hidden var yHumTop as Lang.Number = 0;
  hidden var yHumBottom as Lang.Number = 0;
  hidden var yTempTop as Lang.Number = 0;
  hidden var yTempBottom as Lang.Number = 0;

  hidden const NO_BEARING_SPEED = 0.3;
  hidden const COLOR_TEXT_ALERT = Graphics.COLOR_ORANGE;
  
  // humidity is already percentage
  // @@ TODO properties etc global settings object
  hidden var maxTemperature as Lang.Number = 50; // celcius
  //hidden var maxUvIndex as Lang.Number = 20;
  hidden var maxPressure as Lang.Number = 1080;
  hidden var minPressure as Lang.Number = 870;

  function initialize(dc as Dc, ds as DisplaySettings) {
    self.dc = dc;
    self.ds = ds;
    topAdditionalInfo2 = dc.getFontHeight(ds.fontSmall);
    self.devSettings = System.getDeviceSettings();
    initComfortZones();
    Math.srand(System.getTimer());
  }

  hidden function initComfortZones() as Void {
    var comfort = Comfort.getComfort();    
    self.yHumTop = ds.getYpostion(comfort.humidityMax);
    self.yHumBottom = ds.getYpostion(comfort.humidityMin);
    var perc = Utils.percentageOf(comfort.temperatureMax, self.maxTemperature).toNumber();
    self.yTempTop = ds.getYpostion(perc);
    perc = Utils.percentageOf(comfort.temperatureMin, self.maxTemperature).toNumber();
    self.yTempBottom = ds.getYpostion(perc);
  }

  function drawUvIndexGraph(uvPoints as Lang.Array, maxUvIndex as Lang.Number, showDetails as Lang.Boolean, blueBarPercentage as Array) as Void {
    try {
      var max = uvPoints.size();
      for (var i = 0; i < max; i += 1) {
        var uvp = uvPoints[i] as UvPoint;
        if (!uvp.isHidden) {
          var x = uvp.x;
          var perc = Utils.percentageOf(uvp.uvi, maxUvIndex).toNumber();
          var y = ds.getYpostion(perc);
          var r = uviToRadius(uvp.uvi);
        
          drawUvPoint(x,y,r,uvp.uvi as Float, showDetails);          
        }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawUvPoint(x as Lang.Number, y as Lang.Number, r as Lang.Number, uvi as Lang.Float, showDetails as Lang.Boolean) as Void {    
    var color = uviToColor(uvi);
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    if (showDetails) {
      var h = dc.getFontHeight(Graphics.FONT_TINY);        
      dc.drawText(x, y + h/2, Graphics.FONT_TINY, uvi.format("%.1f"),  Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER);
    }
    dc.fillCircle(x, y, r);
    var rh = (r + 2)/2;
    dc.drawLine(x-r-rh, y-r-rh, x+r+rh, y+r+rh);
    dc.drawLine(x+r+rh, y-r-rh, x-r-rh, y+r+rh);
  }

  // @@ factor -> maxTemperature
  function drawTemperatureGraph(points as Lang.Array, factor as Lang.Number, showDetails as Lang.Boolean, blueBarPercentage as Array) as Void {
    try {
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i] as WeatherPoint;
        if (!p.isHidden) {
          var x = p.x;
          var perc = Utils.percentageOf(p.value, self.maxTemperature).toNumber();
          var y = ds.getYpostion(perc);
          
          if (showDetails && p.value > 10) { // @@ config 
            var yBlueBar = ds.getYpostion((blueBarPercentage[i] as Number).toNumber());
            var h = dc.getFontHeight(Graphics.FONT_TINY);
            if (yBlueBar < y) {
              dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);   
            } else {
              dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);   
            }     
            // dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y - h/2, Graphics.FONT_TINY, p.value.format("%d"), Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER);
          }

          dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
          dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 1);

          dc.drawRectangle(x-1, y-6, 3, 8);
          dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
          dc.drawLine(x, y, x, y-4);
          dc.fillCircle(x, y+2, 2);
        }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawDewpointGraph(points as Lang.Array, factor as Lang.Number, showDetails as Lang.Boolean, blueBarPercentage as Array) as Void {
    try {
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i] as WeatherPoint;
        if (!p.isHidden) {
          var x = p.x;
          var perc = Utils.percentageOf(p.value, self.maxTemperature).toNumber();
          var y = ds.getYpostion(perc);
          var r = 3;
          var color = dewpointToColor(y.toFloat());

          if (showDetails && p.value > 7) { // @@ config 
            // var yBlueBar = ds.getYpostion((blueBarPercentage[i] as Number).toNumber());
            var h = dc.getFontHeight(Graphics.FONT_TINY);
            // if (yBlueBar < y) {
            //   dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);   
            // } else {
            //   dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);   
            // }     
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y + h/2, Graphics.FONT_TINY, p.value.format("%d"), Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER);
          }

          dc.setColor(color, Graphics.COLOR_TRANSPARENT);
          dc.fillCircle(x, y+r-1, 2);

          dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
          dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 1);        
          dc.drawLine(x-r, y, x, y-5);
          dc.drawLine(x, y-5, x+r, y);
          dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, 0, 180);     
        }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }
  
  function drawPressureGraph(points as Lang.Array, factor as Lang.Number, showDetails as Lang.Boolean, blueBarPercentage as Array) as Void {
    try {
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i] as WeatherPoint;

        var x = p.x as Number;
        var perc = Utils.percentageOf(p.value - self.minPressure, self.maxPressure - self.minPressure).toNumber();
        var y = ds.getYpostion(perc).toNumber();
        
        if (showDetails) {
          var yBlueBar = ds.getYpostion((blueBarPercentage[i] as Number).toNumber());
          var h = dc.getFontHeight(Graphics.FONT_TINY);       
          if (yBlueBar < (y - h)) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);   
          } else {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);   
          }          
          dc.drawText(x, y - h/2, Graphics.FONT_XTINY, p.value.format("%d"), Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 1);
        var pts = [ [x-3, y], [x, y+5], [x+3, y]];
        dc.fillPolygon(pts as Polygone);        
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  // @@ factor always 1 remove it
  function drawHumidityGraph(points as Lang.Array, factor as Lang.Number, showDetails as Lang.Boolean, blueBarPercentage as Array) as Void {
    try {
      var max = points.size();
      for (var i = 0; i < max; i += 1) {
        var p = points[i] as WeatherPoint;
        var x = p.x;
        var y = ds.getYpostion(p.value.toNumber()); // value is percentage
        var r = 3;

        if (showDetails) {
          // var yBlueBar = ds.getYpostion((blueBarPercentage[i] as Number).toNumber());
          var h = dc.getFontHeight(Graphics.FONT_TINY);       
          // background pop is taller + text is above y (0,0 is upper left coord)
          // if (yBlueBar < (y - h)) {
          //   dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);   
          // } else {
          //   dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);   
          // }
          dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);   
          dc.drawText(x, y - h/2, Graphics.FONT_TINY, p.value.format("%d"), Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - ds.columnWidth / 2, y, ds.columnWidth, 2);

        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
        var pts = [ [x-r, y], [x, y-5], [x+r, y]];        
        dc.fillPolygon(pts as Polygone);   
        dc.setPenWidth(r);  
        dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, 0, 180);
        dc.setPenWidth(1.0);          
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  // top is max (temp/humid), low is min(temp/humid)
  function drawComfortColumn(x as Lang.Number, temperature as Lang.Number?, relativeHumidity as Lang.Number?, precipitationChance as Lang.Number?) as Void {
    var comfort = Comfort.getComfort();
    var idx = comfort.convertToComfort(temperature, relativeHumidity, precipitationChance);
    // System.println("Comfort x[" + x + "] comfort: " + idx);
    if (idx == COMFORT_NO) {
      return;
    }

    // var color = COLOR_WHITE_GREEN;
    // if (idx == COMFORT_NORMAL) {
    //   color = COLOR_WHITE_YELLOW;
    // } else if (idx == COMFORT_HIGH) {
    //   color = COLOR_WHITE_ORANGE;
    // }

    var color = comfortToColor(idx);
    //  WhatAppBase.Colors.COLOR_WHITE_GREEN_2;
    // if (idx == COMFORT_NORMAL) {
    //   color = WhatAppBase.Colors.COLOR_WHITE_YELLOW_2;
    // } else if (idx == COMFORT_HIGH) {
    //   color = WhatAppBase.Colors.COLOR_WHITE_ORANGERED2_2;
    // }

    dc.setColor(color, color);
    if (ds.smallField) {      

      var percTemperature = Utils.percentageOf(comfort.temperatureMax, self.maxTemperature).toNumber();
      var yTop = ds.getYpostion(Utils.max(percTemperature, comfort.humidityMax) as Lang.Number);
      percTemperature = Utils.percentageOf(comfort.temperatureMin, self.maxTemperature).toNumber();
      var yBottom = ds.getYpostion(Utils.min(percTemperature, comfort.humidityMin) as Lang.Number);
      var height = yBottom - yTop;
      dc.fillRectangle(x - ds.space / 2, yTop, ds.columnWidth + ds.space, height);
      return;
    }

    dc.fillRectangle(x - ds.space / 2, self.yHumTop, ds.columnWidth + ds.space,
                     self.yHumBottom - self.yHumTop);
    dc.fillRectangle(x - ds.space / 2, self.yTempTop, ds.columnWidth + ds.space,
                     self.yTempBottom - self.yTempTop);
  }

  function drawComfortZones() as Void {
    // if (ds.smallField) { return; }
    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
    drawWobblyLine(0, ds.width, self.yHumTop, 3);
    drawWobblyLine(0, ds.width, self.yHumBottom, 3);

    dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
    drawWobblyLine(0, ds.width, self.yTempTop, 3);
    drawWobblyLine(0, ds.width, self.yTempBottom, 3);
  }

  function drawObservationLocation(name as Lang.String?) as Void {
    if (name == null || (name as String).length() == 0) { return; }
    dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
    dc.drawText(ds.margin, TOP_ADDITIONAL_INFO, ds.fontSmall, name, Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawObservationLocationLine2(name as Lang.String?) as Void {
    // Hide on small screen || ds.smallField
    if (name == null || (name as String).length() == 0) { return; }
    dc.setColor(ds.COLOR_TEXT_ADDITIONAL2, Graphics.COLOR_TRANSPARENT);
    dc.drawText(ds.margin, topAdditionalInfo2, ds.fontSmall, name,
                Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawObservationTime(observationTime as Time.Moment?) as Void {
    if (observationTime == null) { return; }

    var observationTimeString = Utils.getShortTimeString(observationTime);

    var color = ds.COLOR_TEXT_ADDITIONAL;
    if (Utils.isDelayedFor(observationTime, $._observationTimeDelayedMinutesThreshold)) { color = Graphics.COLOR_RED; }
    var textW = dc.getTextWidthInPixels(observationTimeString, ds.fontSmall);
    var textX = ds.width - textW - ds.margin;

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(textX, TOP_ADDITIONAL_INFO, ds.fontSmall, observationTimeString,
                Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawWindInfo(windPoints as Array) as Void {
    // if (ds.smallField) { return; }
    var max = windPoints.size();
    for (var idx = 0; idx < max; idx++) {
      var wp = windPoints[idx] as WindPoint;
      drawWindInfoInColumn(wp.x, wp.bearing, wp.speed);
    }
  }

  function drawWindInfoInColumn(x as Lang.Number, windBearingInDegrees as Lang.Number, windSpeed as Lang.Float) as Void {
    // if (ds.smallField) { return; }
    var radius = 8;
    var center = new Point(x + ds.columnWidth / 2,        ds.columnY + ds.columnHeight + ds.heightWind - ds.heightWind / 2);
    drawWind(center, radius, windBearingInDegrees, windSpeed);
  }

  function drawAlertMessages(activeAlerts as Lang.String?) as Void{  
    if (activeAlerts == null || (activeAlerts as Lang.String).length() <= 0) { return; }

    dc.setColor(COLOR_TEXT_ALERT, Graphics.COLOR_TRANSPARENT);    
    dc.drawText(ds.width / 2, TOP_ADDITIONAL_INFO, ds.fontSmall, activeAlerts, Graphics.TEXT_JUSTIFY_CENTER);
  }

  function drawAlertMessagesVert(activeAlerts as Array<String>) as Void {
    var max = activeAlerts.size();
    if (max == 0) { return; }

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

  // function drawActiveAlert(activeAlerts as Array) as Void{
  //   // if (ds.smallField) { return; } // @@TODO

  //   var max = activeAlerts.size();
  //   if (max == 0) { return; }

  //   // every alert 20 px width
  //   var alertW = 20;
  //   var xStart = (ds.width - alertW * max)/ 2;
  //   var x = xStart;
  //   var y = 20;    
  //   for (var idx = 0; idx < max; idx += 1) {
  //     var aa = activeAlerts[idx] as ActiveAlert;
  //     // TODO? get alerted condition/value
  //     if (aa == aaUvi) {
  //       drawUvPoint(x, y, 4, 6.0);
  //     } else if (aa == aaPrecChance) {
  //       // max % rain chance

  //     } else if (aa == aaRain1stHour) {
        

  //     } else if (aa == aaWeather) {
  //       // @@ current condition

  //     } else if (aa == aaWind) {    
  //       // @@ current windspeed/bearing            
  //       drawWind(new Point(x,y), 8, 45, 20.0);
  //     }
  //     x = x + alertW;
  //   }    
  // }

  function drawGlossary() as Void {
    dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
    var fontHeight = dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY);

    var conditionNr = 0;
    var conditionNrMax = 53;
    var y = ds.margin;
    var x = ds.margin;
    var currentX = x;
    var columnMaxWidth = ds.columnWidth + ds.space;
    var maxHeight = ds.height - ds.margin;
    var iHeight = 10;

    while (y <= ds.height && conditionNr <= conditionNrMax) {
      y = y + iHeight;

      var text = getWeatherConditionText(conditionNr);
      var tw = columnMaxWidth;
      if (text != null) {
        tw = dc.getTextWidthInPixels(text, Graphics.FONT_SYSTEM_XTINY);
        columnMaxWidth = Utils.max(columnMaxWidth, tw);
      }
      
      if (y + iHeight > maxHeight) {
        // next column
        currentX = currentX + columnMaxWidth + ds.space;
        x = currentX;
        y = ds.margin + iHeight;
        columnMaxWidth = Utils.max(ds.columnWidth + ds.space, tw);
      }

      // draw icon
      var center = new Point((x + ds.columnWidth / 2) as Number, y);
      _drawWeatherCondition(center, conditionNr);

      // draw description
      y = y + 5;
      if (text != null) {
        dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_SYSTEM_XTINY, text,
                    Graphics.TEXT_JUSTIFY_LEFT);
        y = y + fontHeight;
      }

      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawLine(x, y, x + tw, y);
      conditionNr++;
    }
  }

  function drawWeatherConditionText(x as Lang.Number, condition as Lang.Number, yLine as Lang.Number) as Void {
    if (ds.oneField) {
      var text = getWeatherConditionText(condition);
      if (text != null) {
        var yOffset = (yLine == null) ? 0 : yLine * ds.heightWt;
        dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, ds.columnY + ds.columnHeight + ds.heightWind + ds.heightWc + yOffset, Graphics.FONT_SYSTEM_XTINY, text as String, Graphics.TEXT_JUSTIFY_LEFT);
      }
    }
  }

  function drawWeatherCondition(x as Lang.Number, condition as Lang.Number) as Void{
    _drawWeatherCondition( new Point( x + ds.columnWidth / 2, ds.columnY + ds.columnHeight + ds.heightWind + ds.heightWc / 2 + 2), condition);
  }

  function _drawWeatherCondition(center as Point, condition as Lang.Number) as Void {
    if (condition == null) { return; }
    // if (condition == null || ds.smallField) { return; }

    // clear
    if (condition == Weather.CONDITION_FAIR) {
      drawConditionClear(center, 3, 6, 0);
      return;
    }
    if (condition == Weather.CONDITION_PARTLY_CLEAR) {
      drawConditionClear(center.move(3, -2), 2, 4, 60);
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.move(0, 3), 4));
      return;
    }

    if (condition == Weather.CONDITION_MOSTLY_CLEAR) {
      drawConditionClear(center.move(3, -2), 2, 4, 30);
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center.move(0, 3), 4));
      return;
    }
    if (condition == Weather.CONDITION_CLEAR) {
      drawConditionClear(center, 3, 6, 30);
      return;
    }
    // clouds
    if (condition == Weather.CONDITION_PARTLY_CLOUDY) {
      drawConditionClear(center.move(3, -3), 2, 4, 60);    
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 4));
      return;
    }
    if (condition == Weather.CONDITION_THIN_CLOUDS) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 4));
      return;
    }
    if (condition == Weather.CONDITION_MOSTLY_CLOUDY) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 6));
      return;
    }
    if (condition == Weather.CONDITION_CLOUDY) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 8));
      return;
    }
    // rain
    if (condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN ||
        condition == Weather.CONDITION_CHANCE_OF_SHOWERS) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(center, 5, 3);
      dc.fillPolygon(getCloudPoints(center, 6));
    }

    if (condition == Weather.CONDITION_DRIZZLE) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(center, 5, 3);
    }

    if (condition == Weather.CONDITION_LIGHT_RAIN ||
        condition == Weather.CONDITION_LIGHT_SHOWERS ||
        condition == Weather.CONDITION_SCATTERED_SHOWERS) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(center, 8, 2);
      dc.fillPolygon(getCloudPoints(center, 6));
      return;
    }

    if (condition == Weather.CONDITION_RAIN ||
        condition == Weather.CONDITION_SHOWERS) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(center, 8, 2);
      dc.fillPolygon(getCloudPoints(center, 8));
      return;
    }

    if (condition == Weather.CONDITION_HEAVY_SHOWERS ||
        condition == Weather.CONDITION_HEAVY_RAIN) {
      dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(center, 8, 2);
      dc.fillPolygon(getCloudPoints(center, 8));
      return;
    }

    if (condition == Weather.CONDITION_FREEZING_RAIN) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(center, 8, 2);
      dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 8));
      return;
    }

    // hail
    if (condition == Weather.CONDITION_HAIL) {
      // dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      // dc.fillPolygon(getHailPoints(center, 8));
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(center, 8, 3);
      return;
    }

    if (condition == Weather.CONDITION_WINTRY_MIX ||
        condition == Weather.CONDITION_RAIN_SNOW) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(center.move(-4, 0), 6);
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawRainDrops(center.move(4, 0), 8, 3);
      return;
    }

    if (condition == Weather.CONDITION_CHANCE_OF_RAIN_SNOW ||
        condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW ||
        condition == Weather.CONDITION_LIGHT_RAIN_SNOW) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(center.move(-4, 0), 6);
      drawRainDrops(center.move(4, 0), 8, 3);
      return;
    }

    // snow
    if (condition == Weather.CONDITION_CHANCE_OF_SNOW) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(center, 6);
      return;
    }

    if (condition == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(center.move(0, 2), 6);
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 7));
      return;
    }

    if (condition == Weather.CONDITION_FLURRIES ||
        condition == Weather.CONDITION_LIGHT_SNOW) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(center, 6);
      return;
    }

    if (condition == Weather.CONDITION_SNOW) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(center, 8);
      return;
    }

    if (condition == Weather.CONDITION_SLEET ||
        condition == Weather.CONDITION_ICE_SNOW ||
        condition == Weather.CONDITION_ICE) {
      dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getHailPoints(center, 4));
      dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(center, 8);
      return;
    }

    if (condition == Weather.CONDITION_HEAVY_SNOW ||
        condition == Weather.CONDITION_HEAVY_RAIN_SNOW) {
      dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
      drawSnowFlake(center.move(-4, 2), 8);
      drawSnowFlake(center.move(4, -3), 8);
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
      dc.fillPolygon(getCloudPoints(center, 8));
      return;
    }

    // windy
    if (condition == Weather.CONDITION_WINDY) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawWindIcon(center, 6);
      return;
    }
    // sudden windspeed
    if (condition == Weather.CONDITION_SQUALL) {
      dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
      drawWindIcon(center, 6);
      return;
    }

    // dust
    if (condition == Weather.CONDITION_DUST ||
        condition == Weather.CONDITION_SAND) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawDustIcon(center, 8, 1, 6);
      return;
    }
    // dust, difficult to see
    if (condition == Weather.CONDITION_HAZY ||
        condition == Weather.CONDITION_HAZE) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawMistIcon(center, 10);
      drawDustIcon(center, 8, 1, 8);
      return;
    }

    // sandstorm
    if (condition == Weather.CONDITION_SANDSTORM) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawWindIcon(center, 6);
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      drawDustIcon(center, 8, 1, 8);
      dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getLightningPts(center, 6));
      return;
    }

    // ash
    if (condition == Weather.CONDITION_VOLCANIC_ASH) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getVulcanoPts(center, 9));
      dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
      drawDustIcon(center, 8, 1, 10);
      return;
    }

    // hurricane
    if (condition == Weather.CONDITION_HURRICANE ||
        condition == Weather.CONDITION_TORNADO) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 9));
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawTornado(center);
      return;
    }

    // smoke
    if (condition == Weather.CONDITION_SMOKE) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(getCloudPoints(center, 9));
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawDustIcon(center, 4, 2, 3);
      return;
    }

    // fog
    if (condition == Weather.CONDITION_FOG ||
        condition == Weather.CONDITION_MIST) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      drawMistIcon(center, 10);
      return;
    }

    // unknown
    if (condition == Weather.CONDITION_UNKNOWN_PRECIPITATION ||
        condition == Weather.CONDITION_UNKNOWN) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawText(center.x, center.y, Graphics.FONT_XTINY, "?", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
      return;
    }

    return;
  }

  hidden function drawTornado(center as Point) as Void {
    dc.drawRectangle(center.x - 3, center.y, 6, 2);
    dc.drawRectangle(center.x, center.y + 2, 4, 2);
    dc.drawRectangle(center.x + 1, center.y + 4, 3, 2);
    dc.drawRectangle(center.x + 1, center.y + 6, 1, 3);
  }

  hidden function getVulcanoPts(center as Point, range as Number) as Polygone {
    var pts = [];

    pts.add([ center.x - 2, center.y - range * 0.5 ]);
    pts.add([ center.x, center.y - range * 0.5 + 1 ]);
    pts.add([ center.x + 2, center.y - range * 0.5 ]);

    pts.add([ center.x + range * 0.2, center.y ]);

    pts.add([ center.x + range * 0.7, center.y + range ]);
    pts.add([ center.x - range * 0.7, center.y + range ]);

    pts.add([ center.x - range * 0.2, center.y ]);

    return pts as Polygone;
  }

  hidden function drawDustIcon(center as Point, range as Number, size as Number, particles as Number) as Void {
    var x, y;
    for (var i = 0; i < particles; i++) {
      if (i % 2 == 0) {
        x = center.x + Math.rand() % range;
        y = center.y + Math.rand() % range;
      } else {
        x = center.x - Math.rand() % range;
        y = center.y - Math.rand() % range;
      }
      dc.fillCircle(x, y, size);
    }
  }

  hidden function drawWindIcon(center as Point, range as Number) as Void {
    drawWindLineUp(center.move(0, -2), (range * 0.8).toNumber(), 2, Graphics.ARC_COUNTER_CLOCKWISE);
    drawWindLineUp(center, range, 4, Graphics.ARC_COUNTER_CLOCKWISE);
    drawWindLineDown(center.move(1, 2), (range * 0.7).toNumber(), 2, Graphics.ARC_COUNTER_CLOCKWISE);
  }

  hidden function drawWindLineUp(center as Point, range as Number, radius as Numeric, direction as Graphics.ArcDirection) as Void {
    var p1 = center.move(-range, 0);
    var p2 = center.move(range, 0);
    dc.drawLine(p1.x, p1.y, p2.x, p2.y);
    dc.drawArc(p2.x, p2.y - radius, radius, direction, -90, 160);
  }

  hidden function drawWindLineDown(center as Point, range as Number, radius as Numeric, direction as Graphics.ArcDirection) as Void {
    var p1 = center.move(-range, 0);
    var p2 = center.move(range, 0);
    dc.drawLine(p1.x, p1.y, p2.x, p2.y);
    dc.drawArc(p2.x, p2.y + radius, radius, Graphics.ARC_COUNTER_CLOCKWISE,
               -160, 90);
  }

  hidden function drawMistIcon(center as Point, range as Number) as Void {
    var x1 = center.x - range / 2;
    var x2 = center.x + range / 2;
    var max = center.y + range / 2;
    for (var y = center.y - range / 2; y < max; y = y + 3) {
      drawWobblyLine(x1, x2, y, 2);
    }
  }

  hidden function getLightningPts(center as Point, range as Number) as Polygone {
    var pts = [];

    pts.add([ center.x, center.y - range ]);
    pts.add([ (center.x + range * 0.5).toNumber(), center.y - range ]);

    pts.add([ center.x + 2, (center.y - range * 0.5).toNumber() ]);
    pts.add([ center.x + 5, (center.y - range * 0.5).toNumber() ]);

    pts.add([ center.x - 4, center.y + range ]);

    pts.add([ center.x, (center.y - range * 0.2).toNumber() ]);
    pts.add([ center.x - 3, (center.y - range * 0.2).toNumber() ]);

    pts.add([ center.x - 2, center.y - range ]);

    return pts as Polygone;
  }

  hidden function drawSnowFlake(center as Point, radius as Number) as Void {
    var angle = 0;
    while (angle < 360) {
      var p1 = pointOnCircle(radius, angle, center);
      dc.drawLine(center.x, center.y, p1.x, p1.y);
      angle = angle + 45;
    }
  }

  hidden function getHailPoints(center as Point, radius as Number) as Polygone {
    var pts = [];

    var angle = 0;
    while (angle < 360) {
      var p1 = pointOnCircle(radius, angle, center);
      pts.add([ p1.x, p1.y ]);
      angle = angle + 60;
    }

    return pts as Polygone;
  }

  hidden function drawRainDrops(center as Point, range as Number, density as Number) as Void {
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

  hidden function drawConditionClear(center as Point, radius as Number, radiusOuter as Number, increment as Number) as Void{
    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
    dc.drawCircle(center.x, center.y, radius);
    if (increment <= 0) {
      return;
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
  hidden function drawWind(center as Point, radius as Number, windBearingInDegrees as Number, windSpeedMs as Float) as Void {
    var hasAlert = false;
    var text = "";
    if (windSpeedMs != null) {
      var beaufort = Utils.windSpeedToBeaufort(windSpeedMs);
      hasAlert = ($._alertLevelWindSpeed > 0 && beaufort >= $._alertLevelWindSpeed);
      if ($._showWind == SHOW_WIND_BEAUFORT) {
        text = beaufort.format("%d");
      } else {
        var value = windSpeedMs;
        if ($._showWind == SHOW_WIND_KILOMETERS) {
          value = Utils.mpsToKmPerHour(windSpeedMs);
          if (devSettings.distanceUnits == System.UNIT_STATUTE) {
            value = Utils.kilometerToMile(value);
          }
        }
        value = Math.round(value);
        if (value < 10) {
          text = value.format("%.1f");
        } else {
          text = value.format("%d");
        }
      }
      radius = Utils.min(radius, dc.getTextWidthInPixels(text, Graphics.FONT_XTINY)) + 1;
    }

    dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
    // Bearing arrow
    if (windBearingInDegrees != null &&
        (windSpeedMs != null && windSpeedMs > NO_BEARING_SPEED)) {
      // Correction 0 is horizontal, should be North so -90 degrees
      // Wind comes from x but goes to y (opposite) direction so +160 degrees
      windBearingInDegrees = windBearingInDegrees + 90;

      var pA = pointOnCircle(radius + (radius * 0.5), windBearingInDegrees - 35 - 180, center);
      var pB = pointOnCircle(radius + (radius * 0.9), windBearingInDegrees, center);
      var pC = pointOnCircle(radius + (radius * 0.5), windBearingInDegrees + 35 - 180, center);
      
      var pts = [ pA.toCoordinate(), pB.toCoordinate(), pC.toCoordinate() ] as Polygone;
      
      if (hasAlert) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      } else {
        dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
      }
      dc.fillPolygon(pts);
    }
    // The circle
    dc.drawCircle(center.x, center.y, radius);
    if (hasAlert) {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    } else {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
    dc.fillCircle(center.x, center.y, radius - 1);

    // Windspeed
    var wsFont = Graphics.FONT_XTINY;
    if (hasAlert) {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      wsFont = Graphics.FONT_TINY;
    } else {
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    }
    var w = dc.getTextWidthInPixels(text, wsFont);
    dc.drawText(center.x - w / 2, center.y, wsFont, text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
  }

  hidden function pointOnCircle(radius as Lang.Numeric, angleInDegrees as Lang.Numeric, center as Point) as Point {
    // Convert from degrees to radians
    var x = (radius * Math.cos(angleInDegrees * Math.PI / 180)) + center.x;
    var y = (radius * Math.sin(angleInDegrees * Math.PI / 180)) + center.y;

    return new Point(x.toNumber(), y.toNumber());
  }

  hidden function drawWobblyLine(x1 as Number, x2 as Number, y as Number, increment as Number) as Void {
    var x = x1;
    while (x <= x2) {    
      var y1 = y + Math.sin(x);
      dc.drawPoint(x, y1);
      x = x + increment;
    }
  }

  hidden function getCloudPoints(center as Point, radius as Number) as Polygone { 
    var pts = [];
    var p;
    var cLeft = center.move((-radius * 0.9).toNumber(), 0);
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

    var cRight = center.move((radius * 0.9).toNumber(), 0);
    d = -90;
    while (d <= 0) {
      p = pointOnCircle(radius * 0.6, d, cRight);
      pts.add([ p.x, p.y ]);
      d = d + 10;
    }

    return pts as Polygone;
  }
}

