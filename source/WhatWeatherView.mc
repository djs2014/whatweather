import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.Attention;
import Toybox.Activity;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Position;
import Toybox.Application.Storage;
import Toybox.Background;
using WhatAppBase.Utils as Utils;

class WhatWeatherView extends WatchUi.DataField {
  var mBGServiceHandler as BGServiceHandler?;
  var mAlertHandler as AlertHandler?;
  var mCurrentLocation as Utils.CurrentLocation = new Utils.CurrentLocation();

  // @@ cleanup
  hidden var mFont as Graphics.FontType = Graphics.FONT_LARGE;
  hidden var mFontPostfix as Graphics.FontType = Graphics.FONT_TINY;
  hidden var mFontSmall as Graphics.FontType = Graphics.FONT_XTINY;
  hidden var mFontSmallH as Lang.Number = 0;

  hidden var ds as DisplaySettings = new DisplaySettings();
  hidden var _currentInfo as CurrentInfo = new CurrentInfo();


  var mShowTemperature as Boolean = false;
  var mShowRelativeHumidity as Boolean = false;
  var mShowComfort as Boolean = false;
  var mShowComfortZones as Boolean = false;
  var mShowObservationLocationName as Boolean = false;
  var mShowWind as Number = SHOW_WIND_NOTHING;
  var mShowWeatherCondition as Boolean = false;

  function initialize() {
    DataField.initialize();

    var handler = getBGServiceHandler();
    handler.setCurrentLocation(mCurrentLocation);  

    mFontSmallH = Graphics.getFontHeight(mFontSmall);        
  }

  hidden function getAlertHandler() as AlertHandler {
    if (mAlertHandler == null) {
      mAlertHandler = getApp().getAlertHandler();
    }
    return mAlertHandler;
  }

  hidden function getBGServiceHandler() as BGServiceHandler {
    if (mBGServiceHandler == null) {
      mBGServiceHandler = getApp().getBGServiceHandler();
    }
    return mBGServiceHandler;
  }
  
  function onLayout(dc as Dc) as Void {
   
  }

  function compute(info as Activity.Info) as Void {
    _currentInfo.getPosition(info);
    
    var bgHandler = getBGServiceHandler();
    bgHandler.onCompute(info);
    bgHandler.autoScheduleService();   
  }

  // Display the value you computed here. This will be called once a second when
  // the data field is visible.
  function onUpdate(dc as Dc) as Void {
    try {
      if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

      var backgroundColor = getBackgroundColor();
      var alertHandler = getAlertHandler();
      alertHandler.checkStatus();
      if (alertHandler.isAnyAlertTriggered()) {
        backgroundColor = Graphics.COLOR_YELLOW;
        playAlert();
        alertHandler.currentlyTriggeredHandled();
      }    

      var nrOfColumns = $._maxHoursForecast;
      ds.setDc(dc, backgroundColor);
      ds.clearScreen();
    
      // @@ settings object
      if (ds.smallField || ds.wideField) {
        mShowTemperature = false;
        mShowRelativeHumidity = false;
        mShowComfort = $._showComfort;
        mShowComfortZones = false;
        mShowObservationLocationName = false;
        mShowWind = SHOW_WIND_NOTHING;
        mShowWeatherCondition = false;
      } else {
        mShowTemperature = $._showTemperature;
        mShowRelativeHumidity = $._showRelativeHumidity;
        mShowComfort = $._showComfort;
        mShowComfortZones = $._showComfort;
        mShowObservationLocationName = $._showObservationLocationName;
        mShowWind = $._showWind;
        mShowWeatherCondition = $._showWeatherCondition;
      }
      
      var heightWind = (mShowWind == SHOW_WIND_NOTHING || ds.smallField || ds.wideField) ? 0 : 15;
      var heightWc = (!mShowWeatherCondition || ds.smallField || ds.wideField) ? 0 : 15;

      var heightWt = (ds.oneField) ? dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY) : 0;
      var dashesUnderColumnHeight = $._dashesUnderColumnHeight;
      if (heightWind > 0 || heightWc > 0 ) { dashesUnderColumnHeight = 0; }
      ds.calculate(nrOfColumns, heightWind, heightWc, heightWt);

      if ($._showGlossary && ds.oneField) {
        var render = new RenderWeather(dc, ds);
        render.drawGlossary();
        return;
      }

      // @@ Check if weather data has changed    
      var weatherChanged = true;
      var garminWeather = WeatherService.purgePastWeatherdata(GarminWeather.getLatestGarminWeather());
      $._bgData = WeatherService.purgePastWeatherdata($._bgData);
      $._mostRecentData = WeatherService.mergeWeather(garminWeather, $._bgData, $._weatherDataSource);
      if (weatherChanged) {
        onUpdateWeather(dc, ds, dashesUnderColumnHeight);
      }
     
      if ($._showAlertLevel) {
        drawWarningLevel(dc, ds.margin, ds.columnHeight, Graphics.COLOR_LT_GRAY,$._alertLevelPrecipitationChance);
      }

      if ($._showPrecipitationChanceAxis) { drawPrecipitationChanceAxis(dc, ds.margin, ds.columnHeight); }

      showInfo(dc, ds);

      showBgInfo(dc, ds);    
    } catch (ex) {
      ex.printStackTrace();
    }  
  }

  hidden function showBgInfo(dc as Dc, ds as DisplaySettings) as Void {
    var bgHandler = getBGServiceHandler();
    if (!bgHandler.isEnabled()) { return; }
    var color = ds.COLOR_TEXT;
    var obsTime = "";
    
    if (!ds.smallField && $._bgData != null) { obsTime = Utils.getShortTimeString(($._bgData as WeatherData).getObservationTime()); }
    
    if (bgHandler.isDataDelayed()){
      color = Graphics.COLOR_RED;
      if (ds.smallField) { obsTime = "!"; }
    }
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    var text;
    if (ds.smallField || ds.wideField) {
      text = obsTime;
    } else {
      var counter = "#" + bgHandler.getCounterStats();
      var next = bgHandler.getWhenNextRequest("");    
      var status;
      if (bgHandler.hasError()) {
        status = bgHandler.getError();
      } else {
        status = bgHandler.getStatus();
      }
      text = obsTime + " " + counter + " " + status + "(" + next + ")";
    }
    // @@ if bg active -> draw current info loc
    var textWH = dc.getTextDimensions(text, Graphics.FONT_XTINY);
    dc.drawText(dc.getWidth() - textWH[0], dc.getHeight() - textWH[1], Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_LEFT);  
  }

  hidden function showInfo(dc as Dc, ds as DisplaySettings) as Void {
    var devSettings = System.getDeviceSettings();
    var info = "";
    var postfix = "";
    var showInfo = $._showInfo2;
    if (ds.smallField) {
      showInfo = $._showInfo;
    }
    switch (showInfo) {
      case SHOW_INFO_NOTHING:
        return;
      case SHOW_INFO_TIME_Of_DAY:
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var nowMin = now.min;
        var nowHour = now.hour;
        if (!devSettings.is24Hour) {
          if (!ds.smallField) {
            postfix = "am";
            if (nowHour > 12) {
              postfix = "pm";
            }
          }
          nowHour = (nowHour + 11).toNumber() % 12 + 1;
        }
        info = (nowHour.format("%02d") + ":" + nowMin.format("%02d"));
        break;
      
      // case SHOW_INFO_HEADING:
      //   var compassDirection = _currentInfo.compassDirection();
      //   if (compassDirection != null) {
      //     info = compassDirection;
      //   }
      //   break;
      case SHOW_INFO_TEMPERATURE:
        var temperatureCelcius = _currentInfo.temperature();
        if (temperatureCelcius != null) {
          postfix = "°C";
          var temperature = temperatureCelcius;
          if (devSettings.distanceUnits == System.UNIT_STATUTE) {
            postfix = "°F";
            temperature = Utils.celciusToFarenheit(temperatureCelcius);
          }
          if (ds.smallField) {
            info = temperature.format("%.0f");
          } else {
            info = temperature.format("%.2f");
          }
        }
        break;
     
      case SHOW_INFO_AMBIENT_PRESSURE:
        var ap = _currentInfo.ambientPressure();
        if (ap != null) {
          // pascal -> mbar (hPa)
          postfix = "hPa";
          if (ds.smallField) {
            info = (ap / 100).format("%.0f");
          } else {
            info = (ap / 100).format("%.2f");
          }
        }
        break;   

      case SHOW_INFO_SEALEVEL_PRESSURE:
        var sp = _currentInfo.meanSeaLevelPressure();
        if (sp != null) {
          // pascal -> mbar (hPa)
          postfix = "~hPa";
          if (ds.smallField) {
            info = (sp / 100).format("%.0f");
          } else {
            info = (sp / 100).format("%.2f");
          }
        }
        break;         
    }

    if (info.length() == 0) {
      return;
    }
    var wi = dc.getTextWidthInPixels(info, mFont);
    var wp = dc.getTextWidthInPixels(postfix, mFontPostfix);
    var xi = ds.width / 2 - (wi + wp) / 2;
    dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
    dc.drawText(xi, ds.height / 2, mFont, info, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    dc.drawText(xi + wi + 1, ds.height / 2, mFontPostfix, postfix, Graphics.TEXT_JUSTIFY_LEFT);
  }

  function onUpdateWeather(dc as Dc, ds as DisplaySettings, dashesUnderColumnHeight as Lang.Number) as Void {
    var x = ds.columnX;
    var y = ds.columnY;
    var uvPoints = [];
    var tempPoints = [];
    var humidityPoints = [];
    var windPoints = [];
    var color, colorOther, colorDashes;
    var mm = null;
    var current = null;
    var hourlyForecast = null;
    var previousCondition = -1;
    var weatherTextLine = 0;
    var alertHandler = getAlertHandler();

    try {
      if ($._mostRecentData != null && ($._mostRecentData as WeatherData).valid()) {
        mm = ($._mostRecentData as WeatherData).minutely;
        current = ($._mostRecentData as WeatherData).current;
        hourlyForecast = ($._mostRecentData as WeatherData).hourly;
      }

      var render = new RenderWeather(dc, ds);

      if ( $._maxMinuteForecast > 0) {
        var xMMstart = x; // @@ issue?
        var popTotal = 0 as Lang.Number;
        var columnWidth = 1;
        var offset = ($._maxMinuteForecast * columnWidth) + ds.space;
        if (mm != null) {
          ds.calculateColumnWidth(offset);
          var max = mm.pops.size();
          for (var i = 0; i < max && i < $._maxMinuteForecast; i += 1) {
            var pop = mm.pops[i] as Lang.Number;
            popTotal = popTotal + pop;
            if (DEBUG_DETAILS) {
              System.println( Lang.format("minutely x[$1$] pop[$2$]", [ x, pop ]));
            }

            if ($._showColumnBorder) { drawColumnBorder(dc, x, ds.columnY, columnWidth, ds.columnHeight); }
            drawColumnPrecipitationMillimeters(dc, Graphics.COLOR_BLUE, x, y, columnWidth, ds.columnHeight, pop);
            x = x + columnWidth;
          }
          x = x + ds.space;
        }

        if (dashesUnderColumnHeight > 0) {
          dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
          dc.fillRectangle(xMMstart, ds.columnY + ds.columnHeight, ($._maxMinuteForecast * columnWidth), dashesUnderColumnHeight);
        }
        x = xMMstart + offset;
        alertHandler.processRainMMfirstHour(popTotal);
      }

      var validSegment = 0;
      if ($._showCurrentForecast) {
        if (current != null) {
          color = getConditionColor(current.condition, Graphics.COLOR_BLUE);
          colorOther = getConditionColor(current.conditionOther, Graphics.COLOR_BLUE);
          if (DEBUG_DETAILS) { System.println(Lang.format("current x[$1$] pop[$2$] color[$3$]", [ x, current.info(), color ])); }

          alertHandler.processPrecipitationChance(current.precipitationChance);
          alertHandler.processPrecipitationChance(current.precipitationChanceOther);
          alertHandler.processWeather(color.toNumber());          
          alertHandler.processWeather(colorOther.toNumber());
          alertHandler.processUvi(current.uvi);
          alertHandler.processWindSpeed(current.windSpeed);

          validSegment = validSegment + 1;

          if (mShowComfort) { render.drawComfortColumn(x, current.temperature, current.relativeHumidity, current.precipitationChance); }

          if ($._showColumnBorder) { drawColumnBorder(dc, x, ds.columnY, ds.columnWidth, ds.columnHeight); }

          var cHeight = 0;
          if ($._showClouds) { cHeight = drawColumnPrecipitationChance(dc, COLOR_CLOUDS, x, ds.columnY, ds.columnWidth, ds.columnHeight, current.clouds); }
          // rain
          var rHeight = drawColumnPrecipitationChance(dc, color, x, ds.columnY, ds.columnWidth, ds.columnHeight, current.precipitationChance);
          if ($._showClouds && rHeight < 100 && cHeight <= rHeight) { drawLinePrecipitationChance(dc, COLOR_CLOUDS, COLOR_CLOUDS, x, ds.columnY, ds.columnWidth, ds.columnHeight, ds.columnWidth / 3, current.clouds); }
          // rain other
          drawLinePrecipitationChance(dc, COLOR_CLOUDS, colorOther, x, ds.columnY, ds.columnWidth, ds.columnHeight, ds.columnWidth / 4, current.precipitationChanceOther);

          if ($._showUVIndexFactor > 0) {
            var uvp = new UvPoint(x + ds.columnWidth / 2, current.uvi);
            uvp.calculateVisible(current.precipitationChance);
            uvPoints.add(uvp);
          }

          if (mShowTemperature) { tempPoints.add(new Point(x + ds.columnWidth / 2, current.temperature)); }
          if (mShowRelativeHumidity) { humidityPoints.add( new Point(x + ds.columnWidth / 2, current.relativeHumidity)); }
          if (mShowWind != SHOW_WIND_NOTHING) { windPoints.add( new WindPoint(x, current.windBearing, current.windSpeed)); }

          if (dashesUnderColumnHeight > 0) {
            colorDashes = Graphics.COLOR_DK_GRAY;
            if (current.precipitationChance == 0) { colorDashes = getConditionColor(current.condition, Graphics.COLOR_DK_GRAY); }
            dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, ds.columnY + ds.columnHeight, ds.columnWidth, dashesUnderColumnHeight);
            if (color != colorOther && current.precipitationChanceOther == 0) {
              colorDashes = getConditionColor(current.conditionOther, Graphics.COLOR_DK_GRAY);
              dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
              dc.fillRectangle(x + (ds.columnWidth/3 * 2), ds.columnY + ds.columnHeight, ds.columnWidth/3, dashesUnderColumnHeight);
            }
          }

          if (mShowWeatherCondition) {
            render.drawWeatherCondition(x, current.condition);   
            if (previousCondition != current.condition) {
              render.drawWeatherConditionText(x, current.condition, weatherTextLine);
              previousCondition = current.condition;
            }
          }

          x = x + ds.columnWidth + ds.space;
        }
      }  // showCurrentForecast

      if (hourlyForecast != null) {
        var maxSegment = hourlyForecast.size();
        for (var segment = 0; validSegment < $._maxHoursForecast && segment < maxSegment; segment += 1) {
          var forecast = hourlyForecast[segment] as WeatherHourly;
          if (DEBUG_DETAILS) { System.println(forecast.info()); }

          // Only forecast for the future
          var fcTime = Gregorian.info(forecast.forecastTime, Time.FORMAT_SHORT);
          if (forecast.forecastTime.compare(Time.now()) >= 0) {
            validSegment += 1;
            
            color = getConditionColor(forecast.condition, Graphics.COLOR_BLUE);
            colorOther = getConditionColor(forecast.conditionOther, Graphics.COLOR_BLUE); 
            alertHandler.processPrecipitationChance(forecast.precipitationChance);
            alertHandler.processPrecipitationChance(forecast.precipitationChanceOther);
            alertHandler.processWeather(color.toNumber());
            alertHandler.processWeather(colorOther.toNumber());
            alertHandler.processUvi(forecast.uvi);
            alertHandler.processWindSpeed(forecast.windSpeed);

            if (DEBUG_DETAILS) { System.println(Lang.format("valid hour x[$1$] hourly[$2$] color[$3$]",[ x, forecast.info(), color ])); }

            if (mShowComfort) { render.drawComfortColumn(x, forecast.temperature, forecast.relativeHumidity, forecast.precipitationChance); }
            if ($._showColumnBorder) { drawColumnBorder(dc, x, ds.columnY, ds.columnWidth, ds.columnHeight); }

            var cHeight = 0;
            if ($._showClouds) { cHeight = drawColumnPrecipitationChance(dc, COLOR_CLOUDS, x, ds.columnY, ds.columnWidth, ds.columnHeight, forecast.clouds); }
            // rain
            var rHeight = drawColumnPrecipitationChance(dc, color, x, ds.columnY, ds.columnWidth, ds.columnHeight, forecast.precipitationChance);
            if ($._showClouds && rHeight < 100 && cHeight <= rHeight) { drawLinePrecipitationChance(dc, COLOR_CLOUDS, COLOR_CLOUDS, x, ds.columnY, ds.columnWidth, ds.columnHeight, ds.columnWidth / 3, forecast.clouds); }
            // rain other
            drawLinePrecipitationChance(dc, COLOR_CLOUDS, colorOther, x, ds.columnY, ds.columnWidth, ds.columnHeight, ds.columnWidth / 4, forecast.precipitationChanceOther);

            if ($._showUVIndexFactor > 0) {
              var uvp = new UvPoint(x + ds.columnWidth / 2, forecast.uvi);
              uvp.calculateVisible(forecast.precipitationChance);
              uvPoints.add(uvp);
            }
            if (mShowTemperature) { tempPoints.add( new Point(x + ds.columnWidth / 2, forecast.temperature)); }
            if (mShowRelativeHumidity) { humidityPoints.add( new Point(x + ds.columnWidth / 2, forecast.relativeHumidity)); }
            if (mShowWind) { windPoints.add( new WindPoint(x, forecast.windBearing, forecast.windSpeed)); }

            if (dashesUnderColumnHeight > 0) {              
              colorDashes = Graphics.COLOR_DK_GRAY;
              if (forecast.precipitationChance == 0) { colorDashes = getConditionColor(forecast.condition, Graphics.COLOR_DK_GRAY); }
              dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
              dc.fillRectangle(x, ds.columnY + ds.columnHeight, ds.columnWidth, dashesUnderColumnHeight);
              if (color != colorOther && forecast.precipitationChanceOther == 0) {
                colorDashes = getConditionColor(forecast.conditionOther, Graphics.COLOR_DK_GRAY);
                dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x + (ds.columnWidth/3 *2), ds.columnY + ds.columnHeight, ds.columnWidth/3, dashesUnderColumnHeight);
              }
            }

            if (mShowWeatherCondition) {
              render.drawWeatherCondition(x, forecast.condition);
              if (previousCondition != forecast.condition) {
                weatherTextLine = (weatherTextLine == 0)? 1:0;
                render.drawWeatherConditionText(x, forecast.condition, weatherTextLine);
                previousCondition = forecast.condition;
               }
            }

            x = x + ds.columnWidth + ds.space;
          }
        }
      }  // hourlyForecast

      if ($._showUVIndexFactor > 0) { render.drawUvIndexGraph(uvPoints, $._showUVIndexFactor); }
      if (mShowTemperature) { render.drawTemperatureGraph(tempPoints, 1); }
      if (mShowRelativeHumidity) { render.drawHumidityGraph(humidityPoints, 1); }

      if (mShowComfortZones) { render.drawComfortZones(); }

      if (current != null) {
        // Always show position of observation
        var distance = "";
        var distanceMetric = "km";
        var distanceInKm = 0;
        if (DEBUG_DETAILS) { System.println(_currentInfo.infoLocation()); }
        if (_currentInfo.hasLocation()) {
          distanceInKm = Utils.getDistanceFromLatLonInKm( _currentInfo.lat, _currentInfo.lon, current.lat, current.lon);
          distance = distanceInKm.format("%.2f");
          var deviceSettings = System.getDeviceSettings();
          if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
            distanceMetric = "mi";
            distance = Utils.kilometerToMile(distanceInKm).format("%.2f");
          }
          var bearing = Utils.getRhumbLineBearing(_currentInfo.lat, _currentInfo.lon, current.lat, current.lon);                                            
          var compassDirection = Utils.getCompassDirection(bearing);
          render.drawObservationLocation(Lang.format( "$1$ $2$ ($3$)", [ distance, distanceMetric, compassDirection ]));
        }

        if (mShowObservationLocationName) { render.drawObservationLocationLine2(current.observationLocationName); }        
        if ($._showObservationTime) { render.drawObservationTime(current.observationTime); }
      }

      if (mShowWind != SHOW_WIND_NOTHING) { render.drawWindInfo(windPoints); }
      if (ds.wideField) { 
        render.drawAlertMessages(alertHandler.infoHandled());
      } else if (ds.smallField) { 
        render.drawAlertMessagesVert(alertHandler.infoHandledShort());
      } else {
        render.drawAlertMessages(alertHandler.infoHandled());
      }
      // @@ TEST render.drawActiveAlert(alertHandler.activeAlerts());  
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawWarningLevel(dc as Dc, margin as Number, bar_height as Number, color as Graphics.ColorType, heightPerc as Number) as Void {
    if (heightPerc <= 0) { return; }

    var width = dc.getWidth();

    // integer division truncates the result, use float values
    var lineY = margin + bar_height - bar_height * (heightPerc / 100.0);

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(margin, lineY, width - margin, lineY);
  }

  function drawPrecipitationChanceAxis(dc as Dc, margin as Number, bar_height as Number) as Void {
    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
    var width = dc.getWidth();
    var x2 = width - margin;
    var y100 = margin;
    dc.drawLine(0, y100, margin, y100);
    dc.drawLine(x2, y100, width, y100);
    var y75 = margin + bar_height - bar_height * 0.75;
    dc.drawLine(0, y75, margin, y75);
    dc.drawLine(x2, y75, width, y75);
    var y50 = margin + bar_height - bar_height * 0.5;
    dc.drawLine(0, y50, margin, y50);
    dc.drawLine(x2, y50, width, y50);
    var y25 = margin + bar_height - bar_height * 0.25;
    dc.drawLine(0, y25, margin, y25);
    dc.drawLine(x2, y25, width, y25);
    var y0 = margin + bar_height;
    dc.drawLine(0, y0, margin, y0);
    dc.drawLine(x2, y0, width, y0);
  }

  function drawColumnBorder(dc as Dc, x as Number, y as Number, width as Number, height as Number) as Void {
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawRectangle(x, y, width, height);
  }

  function drawColumnPrecipitationChance(dc as Dc, color as Graphics.ColorType, x as Number, y as Number, bar_width as Number, bar_height as Number, precipitationChance as Number) as Number{
    if (precipitationChance == 0) { return 0; }
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var barFilledHeight = bar_height - (bar_height - ((bar_height.toFloat() / 100.0) * precipitationChance));
    var barFilledY = y + bar_height - barFilledHeight;
    dc.fillRectangle(x, barFilledY, bar_width, barFilledHeight);
    return barFilledHeight.toNumber();
  }

  // function drawColumnPrecipitationChanceOther(dc as Dc, color as Graphics.ColorType, x as Number, y as Number, bar_width as Number, bar_height as Number, precipitationChance as Number) as Number{
  //   if (precipitationChance == 0) { return 0; }
  //   dc.setColor(color, Graphics.COLOR_TRANSPARENT);
  //   var barFilledHeight = bar_height - (bar_height - ((bar_height.toFloat() / 100.0) * precipitationChance));
  //   var barFilledY = y + bar_height - barFilledHeight;
  //   dc.fillRectangle(x, barFilledY, bar_width, barFilledHeight);
  //   return barFilledHeight.toNumber();
  // }

  function drawLinePrecipitationChance(dc as Dc, colorLeftLine as Graphics.ColorType, color as Graphics.ColorType, x as Number, y as Number, bar_width as Number, bar_height as Number, line_width as Number,
    precipitationChance as Number) as Number {
    if (precipitationChance == 0) { return 0; }
    var barFilledHeight = bar_height - (bar_height - ((bar_height.toFloat() / 100.0) * precipitationChance));
    var barFilledY = y + bar_height - barFilledHeight;
    // var lineWidth = bar_width / 3;
    var posX = x + bar_width - line_width;
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(posX, barFilledY, line_width, barFilledHeight);
    if (colorLeftLine != color) {
      dc.setColor(colorLeftLine, Graphics.COLOR_TRANSPARENT);
      dc.fillRectangle(posX, barFilledY, 1, barFilledHeight);    
    }
    return barFilledHeight.toNumber();
  }

  function drawColumnPrecipitationMillimeters(dc as Dc, color as Graphics.ColorType, x as Number, y as Number, bar_width as Number, bar_height as Number, popmm as Number) as Void{
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var barFilledHeight = bar_height - (bar_height - ((bar_height.toFloat() / 100.0) * popmm));
    var barFilledY = y + bar_height - barFilledHeight;
    dc.fillRectangle(x, barFilledY, bar_width, barFilledHeight);
  }

  function playAlert() as Void{
    if (Attention has : playTone) {
      Attention.playTone(Attention.TONE_CANARY);
    }
  }

  // @@ TEST
  function getWhenNextRequest() as String {
        var lastTime = Background.getLastTemporalEventTime();
        if (lastTime == null) { return ""; }
        var mUpdateFrequencyInMinutes = 5;
        var elapsedSeconds = Time.now().value() - lastTime.value();
        var secondsToNext = (mUpdateFrequencyInMinutes * 60) - elapsedSeconds;
        return Utils.secondsToShortTimeString(secondsToNext, "{m}:{s}");
    }
 
}
