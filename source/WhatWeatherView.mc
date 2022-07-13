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
  var mBGServiceHandler as BGServiceHandler;
  var mAlertHandler as AlertHandler;
  var mCurrentLocation as Utils.CurrentLocation = new Utils.CurrentLocation();

  // @@ cleanup
  hidden var mFont as Graphics.FontType = Graphics.FONT_LARGE;
  hidden var mFontPostfix as Graphics.FontType = Graphics.FONT_TINY;
  hidden var mFontSmall as Graphics.FontType = Graphics.FONT_XTINY;
  hidden var mFontSmallH as Lang.Number = 0;

  hidden var ds as DisplaySettings = new DisplaySettings();
  hidden var mCurrentInfo as CurrentInfo = new CurrentInfo();


  var mShowTemperature as Boolean = false;
  var mShowDewpoint as Boolean = false;
  var mShowPressure as Boolean = false;
  var mShowRelativeHumidity as Boolean = false;
  var mShowComfort as Boolean = false;
  var mShowComfortZones as Boolean = false;
  var mShowObservationLocationName as Boolean = false;
  var mShowWind as Number = SHOW_WIND_NOTHING;
  var mShowWeatherCondition as Boolean = false;

  // var mWeatherChanged as Boolean = false;
  var mActivityPaused as Boolean = false;
  var mShowDetails as Boolean = false;
  
  // @@ TODO glossary rotate x conditions per 5 sec.
  // var mGlossaryStart as Number = 0;
  

  function initialize() {
    DataField.initialize();
   
    mBGServiceHandler = getApp().getBGServiceHandler();
    mBGServiceHandler.setCurrentLocation(mCurrentLocation);  
    mAlertHandler = getApp().getAlertHandler();
    mFontSmallH = Graphics.getFontHeight(mFontSmall);        
  }
  
  function onLayout(dc as Dc) as Void {


  }

  function compute(info as Activity.Info) as Void {
    mCurrentInfo.getPosition(info);
    mActivityPaused = activityIsPaused(info);    
    
    mBGServiceHandler.onCompute(info);
    mBGServiceHandler.autoScheduleService();   


    // Not working on EDGE830
    // var garminWeather = WeatherService.purgePastWeatherdata(GarminWeather.getLatestGarminWeather());
    // $._bgData = WeatherService.purgePastWeatherdata($._bgData);
    // var currentWeatherDataCheck = new WeatherDataCheck($._mostRecentData);
    // $._mostRecentData = WeatherService.mergeWeather(garminWeather, $._bgData as WeatherData, $._weatherDataSource);              
    // mAlertHandler.checkStatus();
    // mWeatherChanged = WeatherService.isWeatherDataChanged(currentWeatherDataCheck, $._mostRecentData);
    // if (mWeatherChanged) {
    //   System.println("weather changed");
    //   $._mostRecentData = WeatherService.setChanged($._mostRecentData, false);        
    //   $._bgData = WeatherService.setChanged($._bgData, false);    
    //   CheckWeatherForAlerts();      
    // }
    // if (mAlertHandler.isAnyAlertTriggered()) {
    //   // backgroundColor = Graphics.COLOR_YELLOW;
    //   playAlert();
    //   mAlertHandler.currentlyTriggeredHandled();
    // }          

  }

  // Display the value you computed here. This will be called once a second when
  // the data field is visible.
  function onUpdate(dc as Dc) as Void {
    try {
      if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

      var backgroundColor = getBackgroundColor();
      mAlertHandler.checkStatus();
      if (mAlertHandler.isAnyAlertTriggered()) {
        backgroundColor = Graphics.COLOR_YELLOW;
        playAlert();
        mAlertHandler.currentlyTriggeredHandled();
      }    

      var nrOfColumns = $._maxHoursForecast;
      ds.setDc(dc, backgroundColor);
      ds.clearScreen();
    
      // @@ settings object
      if (ds.smallField || ds.wideField) {
        mShowTemperature = false;
        mShowDewpoint = false;
        mShowPressure = false;
        mShowRelativeHumidity = false;
        mShowComfort = $._showComfort;
        mShowComfortZones = false;
        mShowObservationLocationName = false;
        mShowWind = SHOW_WIND_NOTHING;
        mShowWeatherCondition = false;
      } else {
        mShowTemperature = $._showTemperature;
        mShowDewpoint = $._showDewpoint;
        mShowPressure = $._showPressure;
        mShowRelativeHumidity = $._showRelativeHumidity;
        mShowComfort = $._showComfort;
        mShowComfortZones = $._showComfort;
        mShowObservationLocationName = $._showObservationLocationName;
        mShowWind = $._showWind;
        mShowWeatherCondition = $._showWeatherCondition;
      }
      mShowDetails = $._showDetailsWhenPaused && mActivityPaused && ds.oneField;

      var heightWind = (mShowWind == SHOW_WIND_NOTHING || ds.smallField || ds.wideField) ? 0 : 15;
      var heightWc = (!mShowWeatherCondition || ds.smallField || ds.wideField) ? 0 : 15;

      var heightWt = (ds.oneField) ? dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY) : 0;
      var dashesUnderColumnHeight = $._dashesUnderColumnHeight;
      if (heightWind > 0 || heightWc > 0 ) { dashesUnderColumnHeight = 0; }
      ds.calculate(nrOfColumns, heightWind, heightWc, heightWt);

      // if ($._showGlossary && ds.oneField) {
      //   var render = new RenderWeather(dc, ds);
      //   render.drawGlossary();
      //   return;
      // }
                  
      var garminWeather = WeatherService.purgePastWeatherdata(GarminWeather.getLatestGarminWeather());
      $._bgData = WeatherService.purgePastWeatherdata($._bgData);
      $._mostRecentData = WeatherService.mergeWeather(garminWeather, $._bgData as WeatherData, $._weatherDataSource);   

      onUpdateWeather(dc, ds, dashesUnderColumnHeight);
                    
      drawPrecipitationChanceAxis(dc, ds.margin, ds.columnHeight);

      showInfo(dc, ds);

      showBgInfo(dc, ds);    
    } catch (ex) {
      ex.printStackTrace();
    }  
  }

  hidden function showBgInfo(dc as Dc, ds as DisplaySettings) as Void {
    if ($._weatherDataSource == wsGarminOnly) { return; }
    
    // var bgHandler = getBGServiceHandler();
    if (!mBGServiceHandler.isEnabled()) { return; }
    if (! ($._weatherDataSource == wsOWMFirst  || $._weatherDataSource == wsOWMOnly || $._weatherDataSource == wsGarminFirst))  { return; }

    var color = ds.COLOR_TEXT;
    var obsTime = "";
    
    if (!ds.smallField && $._bgData != null) { obsTime = Utils.getShortTimeString(($._bgData as WeatherData).getObservationTime()); }
    
    if (mBGServiceHandler.isDataDelayed()){
      color = Graphics.COLOR_RED;
      if (ds.smallField) { obsTime = "!"; }
    }
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    var text;
    if (ds.smallField || ds.wideField) {
      text = obsTime;
    } else {
      var counter = "#" + mBGServiceHandler.getCounterStats();
      var next = mBGServiceHandler.getWhenNextRequest("");    
      var status;
      if (mBGServiceHandler.hasError()) {
        status = mBGServiceHandler.getError();
      } else {
        status = mBGServiceHandler.getStatus();
      }
      text = obsTime + " " + counter + " " + status + "(" + next + ")";
    }
    
    var textWH = dc.getTextDimensions(text, Graphics.FONT_XTINY);
    dc.drawText(dc.getWidth() - textWH[0], dc.getHeight() - textWH[1], Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_LEFT);  
  }

  hidden function showInfo(dc as Dc, ds as DisplaySettings) as Void {
    var devSettings = System.getDeviceSettings();
    var info = "";
    var postfix = "";
    var showInfo = $._showInfoLargeField;
    if (ds.smallField) { showInfo = $._showInfoSmallField; }
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
          
      case SHOW_INFO_TEMPERATURE:
        var temperatureCelcius = mCurrentInfo.temperature();
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
        var ap = mCurrentInfo.ambientPressure();
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
        var sp = mCurrentInfo.meanSeaLevelPressure();
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

      case SHOW_INFO_DISTANCE:
        var distanceInKm = mCurrentInfo.elapsedDistance();
        if (distanceInKm != null) {
          postfix = "km";
          var distance = distanceInKm;
          if (devSettings.distanceUnits == System.UNIT_STATUTE) {
            postfix = "mi";
            distance = Utils.kilometerToMile(distanceInKm);
          }
          if (distance < 1) {
            info = distance.format("%.3f");
          } else {                        
            if (ds.smallField) {
              if (distance < 99) {
                info = distance.format("%.2f");
              } else {
                info = distance.format("%.1f");
              }
            } else {
              if (distance < 99) {
                info = distance.format("%.3f");
              } else {
                info = distance.format("%.2f");
              }
            }
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
    var dewPoints = [];
    var pressurePoints = [];
    var humidityPoints = [];
    var windPoints = [];
    var color, colorOther, colorDashes, colorClouds;
    var mm = null;
    var current = null;
    var hourlyForecast = null;
    var previousCondition = -1;
    var weatherTextLine = 0;
    var blueBarPercentage = []; 

    try {
      if ($._mostRecentData != null && ($._mostRecentData as WeatherData).valid()) {
        mm = ($._mostRecentData as WeatherData).minutely;
        current = ($._mostRecentData as WeatherData).current;
        hourlyForecast = ($._mostRecentData as WeatherData).hourly;
      }

      var render = new RenderWeather(dc, ds);

      // @@ Test to find the bug in properties
      // if ( $._maxMinuteForecast > 0) { @@ <-- $._maxMinuteForecast is not a number?
      //   var xMMstart = x; // @@ issue?
      //   var popTotal = 0 as Lang.Number;
      //   var columnWidth = 1;
      //   var offset = (($._maxMinuteForecast * columnWidth) + ds.space).toNumber();
      //   if (mm != null) {
      //     ds.calculateColumnWidth(offset);
      //     var max = mm.pops.size();
      //     for (var i = 0; i < max && i < $._maxMinuteForecast; i += 1) {
      //       var pop = mm.pops[i] as Lang.Number;
      //       popTotal = popTotal + pop;
      //       if (DEBUG_DETAILS) {
      //         System.println( Lang.format("minutely x[$1$] pop[$2$]", [ x, pop ]));
      //       }

      //       if ($._showColumnBorder) { drawColumnBorder(dc, x, ds.columnY, columnWidth, ds.columnHeight); }
      //       drawColumnPrecipitationMillimeters(dc, Graphics.COLOR_BLUE, x, y, columnWidth, ds.columnHeight, pop);
      //       x = x + columnWidth;
      //     }
      //     x = x + ds.space;
      //   }
      //   if (dashesUnderColumnHeight > 0) {
      //     dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      //     dc.fillRectangle(xMMstart, ds.columnY + ds.columnHeight, ($._maxMinuteForecast * columnWidth), dashesUnderColumnHeight);
      //   }
      //   x = xMMstart + offset;
      //   mAlertHandler.processRainMMfirstHour(popTotal);
      // }

      // @@ TODO donotrepeat current/hourly @@DRY
      var validSegment = 0;
      if ($._showCurrentForecast) {
        if (current != null) {
          color = getConditionColor(current.condition, Graphics.COLOR_BLUE);
          colorOther = getConditionColor(current.conditionOther, Graphics.COLOR_BLUE);
          if (DEBUG_DETAILS) { System.println(Lang.format("current x[$1$] pop[$2$] color[$3$]", [ x, current.info(), color ])); }

          mAlertHandler.processPrecipitationChance(current.precipitationChance);
          mAlertHandler.processPrecipitationChance(current.precipitationChanceOther);
          mAlertHandler.processWeather(color.toNumber());          
          mAlertHandler.processWeather(colorOther.toNumber());
          mAlertHandler.processUvi(current.uvi);
          mAlertHandler.processWindSpeed(current.windSpeed);
          mAlertHandler.processDewpoint(current.dewPoint);

          validSegment = validSegment + 1;

          // if ($._showColumnBorder) { drawColumnBorder(dc, x, ds.columnY, ds.columnWidth, ds.columnHeight); }

          var cHeight = 0;
          colorClouds = COLOR_CLOUDS;
          if ($._showClouds) { 
            if (mCurrentLocation.isAtNightTime(current.forecastTime, false)) { colorClouds = COLOR_CLOUDS_NIGHT; }
            cHeight = drawColumnPrecipitationChance(dc, colorClouds, x, ds.columnY, ds.columnWidth, ds.columnHeight, current.clouds); 
          }
          if (mShowComfort) { render.drawComfortColumn(x, current.temperature, current.relativeHumidity, current.precipitationChance); }
          // rain
          var rHeight = drawColumnPrecipitationChance(dc, color, x, ds.columnY, ds.columnWidth, ds.columnHeight, current.precipitationChance);
          if ($._showClouds && rHeight < 100 && cHeight <= rHeight) { drawLinePrecipitationChance(dc, colorClouds, colorClouds, x, ds.columnY, ds.columnWidth, ds.columnHeight, ds.columnWidth / 3, current.clouds); }
          // rain other
          drawLinePrecipitationChance(dc, colorClouds, colorOther, x, ds.columnY, ds.columnWidth, ds.columnHeight, ds.columnWidth / 4, current.precipitationChanceOther);

          if ($._showUVIndex) {
            var uvp = new UvPoint(x + ds.columnWidth / 2, current.uvi);
            uvp.calculateVisible(current.precipitationChance);
            uvPoints.add(uvp);
          }
          if (mShowDetails) { blueBarPercentage.add(current.precipitationChance); }

          if (mShowPressure) { pressurePoints.add(new WeatherPoint(x + ds.columnWidth / 2, current.pressure, 0)); }
          if (mShowRelativeHumidity) { humidityPoints.add( new WeatherPoint(x + ds.columnWidth / 2, current.relativeHumidity, 0)); }
          if (mShowTemperature) { tempPoints.add(new WeatherPoint(x + ds.columnWidth / 2, current.temperature, $._hideTemperatureLowerThan)); }
          if (mShowDewpoint) { dewPoints.add(new WeatherPoint(x + ds.columnWidth / 2, current.getDewPoint(), $._hideTemperatureLowerThan)); }
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
            mAlertHandler.processPrecipitationChance(forecast.precipitationChance);
            mAlertHandler.processPrecipitationChance(forecast.precipitationChanceOther);
            mAlertHandler.processWeather(color.toNumber());
            mAlertHandler.processWeather(colorOther.toNumber());
            mAlertHandler.processUvi(forecast.uvi);
            mAlertHandler.processWindSpeed(forecast.windSpeed);
            mAlertHandler.processDewpoint(forecast.dewPoint);

            if (DEBUG_DETAILS) { System.println(Lang.format("valid hour x[$1$] hourly[$2$] color[$3$]",[ x, forecast.info(), color ])); }

            // if ($._showColumnBorder) { drawColumnBorder(dc, x, ds.columnY, ds.columnWidth, ds.columnHeight); }

            colorClouds = COLOR_CLOUDS;
            var cHeight = 0;
            if ($._showClouds) { 
              if (mCurrentLocation.isAtNightTime(forecast.forecastTime, false)) { 
                colorClouds = COLOR_CLOUDS_NIGHT;
                 }
              cHeight = drawColumnPrecipitationChance(dc, colorClouds, x, ds.columnY, ds.columnWidth, ds.columnHeight, forecast.clouds); 
            }
            if (mShowComfort) { render.drawComfortColumn(x, forecast.temperature, forecast.relativeHumidity, forecast.precipitationChance); }
            // rain
            var rHeight = drawColumnPrecipitationChance(dc, color, x, ds.columnY, ds.columnWidth, ds.columnHeight, forecast.precipitationChance);
            if ($._showClouds && rHeight < 100 && cHeight <= rHeight) { drawLinePrecipitationChance(dc, colorClouds, colorClouds, x, ds.columnY, ds.columnWidth, ds.columnHeight, ds.columnWidth / 3, forecast.clouds); }
            // rain other
            drawLinePrecipitationChance(dc, colorClouds, colorOther, x, ds.columnY, ds.columnWidth, ds.columnHeight, ds.columnWidth / 4, forecast.precipitationChanceOther);

            if (mShowDetails) { blueBarPercentage.add(forecast.precipitationChance); }

            if ($._showUVIndex) {
              var uvp = new UvPoint(x + ds.columnWidth / 2, forecast.uvi);
              uvp.calculateVisible(forecast.precipitationChance);
              uvPoints.add(uvp);
            }
            if (mShowPressure) { pressurePoints.add(new WeatherPoint(x + ds.columnWidth / 2, forecast.pressure, 0)); }
            if (mShowRelativeHumidity) { humidityPoints.add( new WeatherPoint(x + ds.columnWidth / 2, forecast.relativeHumidity, 0)); }
            if (mShowTemperature) { tempPoints.add( new WeatherPoint(x + ds.columnWidth / 2, forecast.temperature, $._hideTemperatureLowerThan)); }
            if (mShowDewpoint) { dewPoints.add(new WeatherPoint(x + ds.columnWidth / 2, forecast.getDewPoint(), $._hideTemperatureLowerThan)); }
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

      if ($._showUVIndex) { render.drawUvIndexGraph(uvPoints, $._maxUVIndex, mShowDetails, blueBarPercentage); }
      if (mShowTemperature) { render.drawTemperatureGraph(tempPoints, 1, mShowDetails, blueBarPercentage); }
      if (mShowRelativeHumidity) { render.drawHumidityGraph(humidityPoints, 1, mShowDetails, blueBarPercentage); }
      if (mShowDewpoint) { render.drawDewpointGraph(dewPoints, 1, mShowDetails, blueBarPercentage); }
      if (mShowPressure) { render.drawPressureGraph(pressurePoints, 1, mShowDetails, blueBarPercentage); }

      if (mShowComfortZones) { render.drawComfortZones(); } // @@ small field, not the lines

      if (current != null) {
        // Always show position of observation
        var distance = "";
        var distanceMetric = "km";
        var distanceInKm = 0;
        if (DEBUG_DETAILS) { System.println(mCurrentInfo.infoLocation()); }
        if (mCurrentInfo.hasLocation()) {
          distanceInKm = Utils.getDistanceFromLatLonInKm( mCurrentInfo.lat, mCurrentInfo.lon, current.lat, current.lon);
          distance = distanceInKm.format("%.2f");
          var deviceSettings = System.getDeviceSettings();
          if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
            distanceMetric = "mi";
            distance = Utils.kilometerToMile(distanceInKm).format("%.2f");
          }
          var bearing = Utils.getRhumbLineBearing(mCurrentInfo.lat, mCurrentInfo.lon, current.lat, current.lon);                                            
          var compassDirection = Utils.getCompassDirection(bearing);
          render.drawObservationLocation(Lang.format( "$1$ $2$ ($3$)", [ distance, distanceMetric, compassDirection ]));
        }

        // @@ mActivityPaused -> y offset to line 2
        if (mShowObservationLocationName) { render.drawObservationLocationLine2(current.observationLocationName); }        
        if ($._showObservationTime) { render.drawObservationTime(current.observationTime); }
      }

      if (mShowWind != SHOW_WIND_NOTHING) { render.drawWindInfo(windPoints); }
      if (ds.wideField) { 
        render.drawAlertMessages(mAlertHandler.infoHandled());
      } else if (ds.smallField) { 
        render.drawAlertMessagesVert(mAlertHandler.infoHandledShort());
      } else {
        render.drawAlertMessages(mAlertHandler.infoHandled());
      }      
    } catch (ex) {
      ex.printStackTrace();
    }
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

    //
    if (mShowDetails && precipitationChance > 50 && precipitationChance < 100) {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      var h = dc.getFontHeight(Graphics.FONT_SMALL);
      dc.drawText(x + bar_width / 2, barFilledY + h, Graphics.FONT_SMALL, precipitationChance.format("%d"), Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER);
    }
    return barFilledHeight.toNumber();
  }
  
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

  function activityIsPaused(info as Activity.Info) as Boolean {
      if (info has :timerState) {
        return info.timerState == Activity.TIMER_STATE_PAUSED;
      }
      return false;
  }

  function playAlert() as Void{
    if (Attention has : playTone) {
      Attention.playTone(Attention.TONE_CANARY);
    }
  }

  // function CheckWeatherForAlerts() as Void {
  //   if ($._mostRecentData == null) { return; }
  //   var data = $._mostRecentData as WeatherData;
  //   if (!data.valid()) { return; }

  //   if ( $._maxMinuteForecast > 0) {
  //     var popTotal = 0 as Lang.Number;  
  //     var max = data.minutely.pops.size();
  //     for (var i = 0; i < max && i < $._maxMinuteForecast; i += 1) {
  //           var pop = data.minutely.pops[i] as Lang.Number;
  //           popTotal = popTotal + pop;            
  //     }
  //     mAlertHandler.processRainMMfirstHour(popTotal);
  //   }

  //   var validSegment = 0;
  //   var color, colorOther;
  //   if ($._showCurrentForecast) {
  //     var current = data.current;
  //     color = getConditionColor(current.condition, Graphics.COLOR_BLUE);
  //     colorOther = getConditionColor(current.conditionOther, Graphics.COLOR_BLUE);

  //     mAlertHandler.processPrecipitationChance(current.precipitationChance);
  //     mAlertHandler.processPrecipitationChance(current.precipitationChanceOther);
  //     mAlertHandler.processWeather(color.toNumber());          
  //     mAlertHandler.processWeather(colorOther.toNumber());
  //     mAlertHandler.processUvi(current.uvi);
  //     mAlertHandler.processWindSpeed(current.windSpeed);
  //     mAlertHandler.processDewpoint(current.dewPoint);

  //     validSegment = validSegment + 1;
  //   }

  //   var maxSegment = data.hourly.size();
  //   for (var segment = 0; validSegment < $._maxHoursForecast && segment < maxSegment; segment += 1) {
  //     var forecast = data.hourly[segment] as WeatherHourly;

  //     color = getConditionColor(forecast.condition, Graphics.COLOR_BLUE);
  //     colorOther = getConditionColor(forecast.conditionOther, Graphics.COLOR_BLUE); 
  //     mAlertHandler.processPrecipitationChance(forecast.precipitationChance);
  //     mAlertHandler.processPrecipitationChance(forecast.precipitationChanceOther);
  //     mAlertHandler.processWeather(color.toNumber());
  //     mAlertHandler.processWeather(colorOther.toNumber());
  //     mAlertHandler.processUvi(forecast.uvi);
  //     mAlertHandler.processWindSpeed(forecast.windSpeed);
  //     mAlertHandler.processDewpoint(forecast.dewPoint);
  //   }    
  // }

}
