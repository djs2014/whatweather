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
  var mWeatherAlertHandler as WeatherAlertHandler = new WeatherAlertHandler();

  var mHideTemperatureLowerThan as Lang.Number = 8;

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
  var mShowComfortZone as Boolean = false;
  var mShowComfortBorders as Boolean = false;
  var mShowObservationLocationName as Boolean = false;
  var mShowWind as Number = SHOW_WIND_NOTHING;
  var mShowWindFirst as Boolean = false;
  var mShowWeatherCondition as Boolean = false;

  var mActivityPaused as Boolean = false;
  var mShowDetails as Boolean = false;
  var mTimerState as Number = 0;
  
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
    try {
      mCurrentInfo.getPosition(info);
      mActivityPaused = activityIsPaused(info);    

      if (info has :timerState && info.timerState != null) { mTimerState = info.timerState as Lang.Number; }
      mBGServiceHandler.onCompute(info);
      mBGServiceHandler.autoScheduleService();   

      handleWeatherAlerts();
    } catch (ex) {
      ex.printStackTrace();
    }  
    // Not working on EDGE830
    // var garminWeather = purgePastWeatherdata(getLatestGarminWeather());
    // $._bgData = purgePastWeatherdata($._bgData);
    // var currentWeatherDataCheck = new WeatherDataCheck($._mostRecentData);
    // $._mostRecentData = mergeWeatherData(garminWeather, $._bgData as WeatherData, $._weatherDataSource);              
    // mAlertHandler.checkStatus();
    // mWeatherChanged = isWeatherDataChanged(currentWeatherDataCheck, $._mostRecentData);
    // if (mWeatherChanged) {
    //   System.println("weather changed");
    //   $._mostRecentData = setWeatherDataChanged($._mostRecentData, false);        
    //   $._bgData = setWeatherDataChanged($._bgData, false);    
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
        mShowComfortZone = $._showComfortZone;
        mShowComfortBorders = false;
        mShowObservationLocationName = false;
        mShowWind = SHOW_WIND_NOTHING;
        mShowWindFirst = $._showCurrentWind;        
        mShowWeatherCondition = false;
      } else {
        mShowTemperature = $._showTemperature;
        mShowDewpoint = $._showDewpoint;
        mShowPressure = $._showPressure;
        mShowRelativeHumidity = $._showRelativeHumidity;
        mShowComfortZone = $._showComfortZone;
        mShowComfortBorders = $._showComfortZone;
        mShowObservationLocationName = true;
        mShowWind = $._showWind;
        mShowWindFirst = false;
        mShowWeatherCondition = $._showWeatherCondition;
      }
      mShowDetails = mActivityPaused && ds.oneField;

      var heightWind = (mShowWind == SHOW_WIND_NOTHING || ds.smallField || ds.wideField) ? 0 : 15;
      var heightWc = (!mShowWeatherCondition || ds.smallField || ds.wideField) ? 0 : 15;

      var heightWt = (ds.oneField) ? dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY) : 0;
      var dashesUnderColumnHeight = 2;
      if (heightWind > 0 || heightWc > 0 ) { dashesUnderColumnHeight = 0; }
      ds.calculate(nrOfColumns, heightWind, heightWc, heightWt);
        
      var garminWeather = purgePastWeatherdata(getLatestGarminWeather());
      $._bgData = purgePastWeatherdata($._bgData);
      $._mostRecentData = mergeWeatherData(garminWeather, $._bgData as WeatherData, $._weatherDataSource);   

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
      text = mBGServiceHandler.getErrorMessage() + " " + obsTime + " " + counter + " " + status + "(" + next + ")";
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
          if (devSettings.temperatureUnits == System.UNIT_STATUTE) {
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
    if (mShowWindFirst && ds.smallField) { xi = xi + dc.getTextWidthInPixels("0", mFont) / 2; }
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
    var nightTime = false;
    var sunsetPassed = false;

    try {
      if ($._mostRecentData != null && ($._mostRecentData as WeatherData).valid()) {
        mm = ($._mostRecentData as WeatherData).minutely;
        current = ($._mostRecentData as WeatherData).current;
        hourlyForecast = ($._mostRecentData as WeatherData).hourly;
      }

      var render = new RenderWeather(dc, ds);
      var xOffsetWindFirstColumn = 0;
      if ( $._showMinuteForecast) { 
        var maxIdx = 0;
        if (mm != null) {
          maxIdx = mm.pops.size();

          if (maxIdx > 0 && mm.max > 0.049) {        
            xOffsetWindFirstColumn = 60; 
            var mmMinutesDelayed = Utils.getMinutesDelayed(mm.forecastTime);
            var xMMstart = x;
            var popTotal = 0.0 as Lang.Float;
            var columnWidth = 1;
            var offset = ((maxIdx * columnWidth) + ds.space).toNumber();
            var rainInXminutes = 0;
            ds.calculateColumnWidth(offset);
            for (var i = mmMinutesDelayed; i < maxIdx && i < 60; i += 1) {
              var pop = (mm as WeatherMinutely).pops[i];
              popTotal = popTotal + pop / 60.0; // pop is mm/hour, pop is for 1 minute
              if (DEBUG_DETAILS) {
                System.println( Lang.format("minutely x[$1$] pop[$2$]", [ x, pop ]));
              }
              if (pop > 0 && rainInXminutes == 0) { rainInXminutes = i - mmMinutesDelayed; }
              // if ($._showColumnBorder) { drawColumnBorder(dc, x, ds.columnY, columnWidth, ds.columnHeight); }
              // pop is float? 
              // * 10.0 
              drawColumnPrecipitationMillimeters(dc, Graphics.COLOR_BLUE, x, y, columnWidth, ds.columnHeight, pop);
              x = x + columnWidth;
            }
            if (popTotal > 0.0) {    
              // total mm in x minutes
              dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);            
              var rainTextTotal = popTotal.format("%.1f") + " mm";
              var rainTextTime = "in " + rainInXminutes.format("%d") + " min";
              if (ds.smallField) { 
                rainTextTime = rainInXminutes.format("%d") + " min";
                dc.drawText(xMMstart, ds.columnY + (ds.columnHeight * 0.7), Graphics.FONT_XTINY, rainTextTime, Graphics.TEXT_JUSTIFY_LEFT);              
              } else if (ds.wideField) {
                dc.drawText(xMMstart, ds.columnY + ds.columnHeight - 2 * dc.getFontHeight(Graphics.FONT_TINY), Graphics.FONT_TINY, rainTextTotal, Graphics.TEXT_JUSTIFY_LEFT);              
                dc.drawText(xMMstart, ds.columnY + ds.columnHeight - 1 * dc.getFontHeight(Graphics.FONT_TINY), Graphics.FONT_TINY, rainTextTime, Graphics.TEXT_JUSTIFY_LEFT);              
              } else {
                dc.drawText(xMMstart, ds.columnY + ds.columnHeight, Graphics.FONT_TINY, rainTextTotal, Graphics.TEXT_JUSTIFY_LEFT);
                dc.drawText(xMMstart, ds.columnY + ds.columnHeight + dc.getFontHeight(Graphics.FONT_XTINY), Graphics.FONT_TINY, rainTextTime, Graphics.TEXT_JUSTIFY_LEFT);
              }            
              x = x + ds.space;
              if (dashesUnderColumnHeight > 0) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(xMMstart, ds.columnY + ds.columnHeight, (maxIdx * columnWidth), dashesUnderColumnHeight);
              }
              x = xMMstart + offset;
              mAlertHandler.processRainMMfirstHour(popTotal);
            }
          }
        }
      }

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
          nightTime = mCurrentLocation.isAtNightTime(current.forecastTime, false);          
          colorClouds = COLOR_CLOUDS;
          if ($._showClouds) { 
            if (nightTime) { colorClouds = COLOR_CLOUDS_NIGHT; }
            cHeight = drawColumnPrecipitationChance(dc, colorClouds, x, ds.columnY, ds.columnWidth, ds.columnHeight, current.clouds); 
          }
          if (mShowComfortZone) { render.drawComfortColumn(x, current.temperature, current.dewPoint); }
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
          if (mShowTemperature) { tempPoints.add(new WeatherPoint(x + ds.columnWidth / 2, current.temperature, mHideTemperatureLowerThan)); }
          if (mShowDewpoint) { dewPoints.add(new WeatherPoint(x + ds.columnWidth / 2, current.getDewPoint(), mHideTemperatureLowerThan)); }
          if (mShowWind != SHOW_WIND_NOTHING || mShowWindFirst) { windPoints.add( new WindPoint(x, current.windBearing, current.windSpeed)); }

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
            render.drawWeatherCondition(x, current.condition, nightTime);   
            if (nightTime && !sunsetPassed) {
              render.drawSunsetIndication(x);
              sunsetPassed = true;
            }
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
          // var fcTime = Gregorian.info(forecast.forecastTime, Time.FORMAT_SHORT);
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
            nightTime = mCurrentLocation.isAtNightTime(forecast.forecastTime, false);
            
            var cHeight = 0;
            if ($._showClouds) { 
              if (nightTime) { colorClouds = COLOR_CLOUDS_NIGHT; }
              cHeight = drawColumnPrecipitationChance(dc, colorClouds, x, ds.columnY, ds.columnWidth, ds.columnHeight, forecast.clouds); 
            }
            if (mShowComfortZone) { render.drawComfortColumn(x, forecast.temperature, forecast.dewPoint); }
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
            if (mShowTemperature) { tempPoints.add( new WeatherPoint(x + ds.columnWidth / 2, forecast.temperature, mHideTemperatureLowerThan)); }
            if (mShowDewpoint) { dewPoints.add(new WeatherPoint(x + ds.columnWidth / 2, forecast.getDewPoint(), mHideTemperatureLowerThan)); }
            if (mShowWind != SHOW_WIND_NOTHING || mShowWindFirst) { windPoints.add( new WindPoint(x, forecast.windBearing, forecast.windSpeed)); }

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
              render.drawWeatherCondition(x, forecast.condition, nightTime);
              if (nightTime && !sunsetPassed) {
                render.drawSunsetIndication(x);
                sunsetPassed = true;
              }
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
      if (mShowTemperature) { render.drawTemperatureGraph(tempPoints, mShowDetails, blueBarPercentage); }
      if (mShowRelativeHumidity) { render.drawHumidityGraph(humidityPoints, mShowDetails, blueBarPercentage); }
      if (mShowDewpoint) { render.drawDewpointGraph(dewPoints, mShowDetails, blueBarPercentage); }
      if (mShowPressure) { render.drawPressureGraph(pressurePoints, mShowDetails, blueBarPercentage); }

      if (mShowComfortBorders) { render.drawComfortBorders(); } 

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
        var showLocationName = mShowObservationLocationName;
        if (mTimerState == Activity.TIMER_STATE_PAUSED && mAlertHandler.hasAlertsHandled()) { showLocationName = false; }
        if (showLocationName) { render.drawObservationLocationLine2(current.observationLocationName); }        
        render.drawObservationTime(current.observationTime); 
      }

      if (mShowWindFirst) {        
        render.drawWindInfoFirstColumn(windPoints, xOffsetWindFirstColumn);
      } else if (mShowWind != SHOW_WIND_NOTHING) { render.drawWindInfo(windPoints); }
      
      if (ds.wideField) { 
        render.drawAlertMessages(mAlertHandler.infoHandled(), false);
      } else if (ds.smallField) { 
        render.drawAlertMessagesVert(mAlertHandler.infoHandledShort());
      } else {
        render.drawAlertMessages(mAlertHandler.infoHandled(), mActivityPaused);
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

  // function drawColumnBorder(dc as Dc, x as Number, y as Number, width as Number, height as Number) as Void {
  //   dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
  //   dc.drawRectangle(x, y, width, height);
  // }

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

  function drawColumnPrecipitationMillimeters(dc as Dc, color as Graphics.ColorType, x as Number, y as Number, bar_width as Number, bar_height as Number, mmhour as Float) as Void{
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var max_mmPerHour = 20;
    var perc = Utils.percentageOf(mmhour, max_mmPerHour).toNumber(); 
    if (perc <= 0) { return; }
    var ymm = ds.getYpostion(perc);
    var height = bar_height - ymm;
    var barFilledY = y + bar_height - height;
    dc.fillRectangle(x, barFilledY, bar_width, height);    
  }

  function activityIsPaused(info as Activity.Info) as Boolean {
      if (info has :timerState) {
        return info.timerState == Activity.TIMER_STATE_PAUSED || info.timerState == Activity.TIMER_STATE_OFF;
      }
      return false;
  }
  
  function playAlert() as Void{
    if (Attention has : playTone) {
      Attention.playTone(Attention.TONE_CANARY);
    }
  }

  function handleWeatherAlerts() as Void {
    if (!(WatchUi.DataField has :showAlert)) {
      return;
    } 
    if (!$._showWeatherAlerts || !(WatchUi.DataField has :showAlert) || $._mostRecentData == null) { return; }
    var alerts = ($._mostRecentData as WeatherData).alerts;
    if (alerts.size() == 0) { return; }
        
    mWeatherAlertHandler.handle(alerts);          
  } 
}
