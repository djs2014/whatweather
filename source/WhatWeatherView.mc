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

class CurrentInfo {
  var info as String = "";
  var postfix as String = "";
}

class WhatWeatherView extends WatchUi.DataField {
  var mBGServiceHandler as BGServiceHandler;
  var mCurrentLocation as CurrentLocation = new CurrentLocation();
  var mLat as Double = 0d;
  var mLon as Double = 0d;
  hidden var previousTrack as Float = 0.0f;
  hidden var track as Number = 0;

  var mAlertHandler as AlertHandler;
  var mWeatherAlertHandler as WeatherAlertHandler = new WeatherAlertHandler();

  var mHideTemperatureLowerThan as Lang.Number = 8;
  var mBgData as WeatherData = emptyWeatherData();
  var mRecentData as WeatherData = emptyWeatherData();
  var mGarminCheck as WeatherCheck = new WeatherCheck();
  var mCurrentInfo as CurrentInfo?;

  // @@ cleanup
  hidden var mFont as Graphics.FontType = Graphics.FONT_LARGE;
  hidden var mFontPostfix as Graphics.FontType = Graphics.FONT_TINY;
  hidden var mFontSmall as Graphics.FontType = Graphics.FONT_XTINY;
  hidden var mFontSmallH as Lang.Number = 0;

  hidden var mDs as DisplaySettings = new DisplaySettings();

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

  var mFlashScreen as Boolean = false;
  var mTriggerCheckWeatherAlerts as Boolean = true;
  // @@ TODO  var mHasMinuteRains as Boolean = false;

  function initialize() {
    DataField.initialize();

    mCurrentLocation.setOnLocationChanged(self, :onLocationChanged);
    mBGServiceHandler = getApp().getBGServiceHandler();
    mBGServiceHandler.setOnBackgroundData(self, :onBackgroundData);
    mBGServiceHandler.setCurrentLocation(mCurrentLocation);

    mAlertHandler = getApp().getAlertHandler();
    mFontSmallH = Graphics.getFontHeight(mFontSmall);
    onLocationChanged();
  }

  function onLocationChanged() as Void {
    var degrees = mCurrentLocation.getCurrentDegrees();
    mLat = degrees[0];
    mLon = degrees[1];
  }

  function onBackgroundData(data as Dictionary) as Void {
    // First entry hourly in OWM is current entry
    mBgData = toWeatherData(data, true);
    mBGServiceHandler.setLastObservationMoment(mBgData.getObservationTime());
    mTriggerCheckWeatherAlerts = true;
    data = null;
  }

  function onLayout(dc as Dc) as Void {
    calculateLayout(dc);
    // @@ TODO when minute rains is shown / or is hidden -> trigger calculatelayout
  }

  function compute(info as Activity.Info) as Void {
    try {
      if ($.gSettingsChanged) {
        mTriggerCheckWeatherAlerts = true;
        $.gSettingsChanged = false;
      }

      track = getBearing(info);
      mCurrentInfo = GetCurrentInfo(info);
      mActivityPaused = activityIsPaused(info);

      mShowDetails = mActivityPaused && mDs.oneField;

      if (info has :timerState && info.timerState != null) {
        mTimerState = info.timerState as Lang.Number;
      }
      mBGServiceHandler.onCompute(info);
      mBGServiceHandler.autoScheduleService();

      var garminWeather = purgePastWeatherdata(getLatestGarminWeather());
      // Ignore this, there is no event onNewGarminData
      garminWeather.setChanged(false);
      var garminWeatherChanged = mGarminCheck.changed(
        garminWeather.getLat(),
        garminWeather.getLon(),
        garminWeather.getObservationTime()
      );
      if (garminWeatherChanged) {
        mGarminCheck.lat = garminWeather.getLat();
        mGarminCheck.lon = garminWeather.getLon();
        mGarminCheck.observationTime = garminWeather.getObservationTime();
      }
      mBgData = purgePastWeatherdata(mBgData);
      mRecentData = mergeWeatherData(garminWeather, mBgData, $._weatherDataSource);

      // Only when needed, ex when weather data is changed (new hour, new location, new bg data)
      if (mTriggerCheckWeatherAlerts || mRecentData.changed || garminWeatherChanged) {
        if (DEBUG_DETAILS) {
          System.println(
            Lang.format("WeatherChanged[$1$] mRecentData.changed[$2$] mBgData.changed[$3$] garminWeatherChanged[$4$]", [
              mTriggerCheckWeatherAlerts,
              mRecentData.changed,
              mBgData.changed,
              garminWeatherChanged,
            ])
          );
        }
        mTriggerCheckWeatherAlerts = false;
        mBgData.setChanged(false);
        mRecentData.setChanged(false);

        mAlertHandler.checkStatus();
        checkForWeatherAlerts();
        if (mAlertHandler.isAnyAlertTriggered()) {
          mFlashScreen = true;
          playAlert();
          mAlertHandler.currentlyTriggeredHandled();
        }
        // TODO display OWM alerts for x seconds
        handleWeatherAlerts();
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  // Display the value you computed here. This will be called once a second when
  // the data field is visible.
  // Draw the weather
  function onUpdate(dc as Dc) as Void {
    try {
      if ($.gExitedMenu) {
        // fix for leaving menu, draw complete screen, large field
        dc.clearClip();
        $.gExitedMenu = false;
        calculateLayout(dc);
      }

      if (dc has :setAntiAlias) {
        dc.setAntiAlias(true);
      }

      // TODO, night mode
      var backgroundColor = getBackgroundColor();
      mAlertHandler.checkStatus();
      if (mFlashScreen) {
        mFlashScreen = false;
        backgroundColor = Graphics.COLOR_YELLOW;
      }

      dc.setColor(backgroundColor, backgroundColor);
      dc.clear();

      onUpdateWeather(dc, mDs.dashesUnderColumnHeight);

      drawPrecipitationChanceAxis(dc, mDs.margin, mDs.columnHeight);

      showInfo(dc);

      showBgInfo(dc);
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  hidden function calculateLayout(dc as Dc) as Void {
    mDs.detectFieldType(dc);

    var nrOfColumns = $._maxHoursForecast;
    if (mDs.smallField || mDs.wideField) {
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

    var heightWind = mShowWind == SHOW_WIND_NOTHING || mDs.smallField || mDs.wideField ? 0 : 15;
    var heightWc = !mShowWeatherCondition || mDs.smallField || mDs.wideField ? 0 : 15;
    var heightWt = mDs.oneField ? dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY) : 0;
    mDs.calculate(nrOfColumns, heightWind, heightWc, heightWt);
  }

  hidden function showBgInfo(dc as Dc) as Void {
    if ($._weatherDataSource == wsGarminOnly) {
      return;
    }

    if (!mBGServiceHandler.isEnabled()) {
      return;
    }
    if (
      !(
        $._weatherDataSource == wsOWMFirst ||
        $._weatherDataSource == wsOWMOnly ||
        $._weatherDataSource == wsGarminFirst
      )
    ) {
      return;
    }

    var color = mDs.COLOR_TEXT;
    var obsTime = "";

    if (!mDs.smallField) {
      obsTime = $.getShortTimeString(mBgData.getObservationTime());
    }

    if (mBGServiceHandler.isDataDelayed()) {
      color = Graphics.COLOR_RED;
      if (mDs.smallField) {
        obsTime = "!";
      }
    }
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    var text;
    if (mDs.smallField || mDs.wideField) {
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
    dc.drawText(
      dc.getWidth() - textWH[0],
      dc.getHeight() - textWH[1],
      Graphics.FONT_XTINY,
      text,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  hidden function showInfo(dc as Dc) as Void {
    if (mCurrentInfo == null) {
      return;
    }
    
    var ci = mCurrentInfo as CurrentInfo;
    var info = ci.info;
    var postfix = ci.postfix;

    var wi = dc.getTextWidthInPixels(info, mFont);
    var wp = dc.getTextWidthInPixels(postfix, mFontPostfix);
    var xi = mDs.width / 2 - (wi + wp) / 2;
    if (mShowWindFirst && mDs.smallField) {
      xi = xi + dc.getTextWidthInPixels("0", mFont) / 2;
    }
    dc.setColor(mDs.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
    dc.drawText(xi, mDs.height / 2, mFont, info, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    dc.drawText(xi + wi + 1, mDs.height / 2, mFontPostfix, postfix, Graphics.TEXT_JUSTIFY_LEFT);
  }

  function onUpdateWeather(dc as Dc, dashesUnderColumnHeight as Lang.Number) as Void {
    var x = mDs.columnX;
    var y = mDs.columnY;
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
      if (mRecentData.valid()) {
        mm = mRecentData.minutely;
        current = mRecentData.current;
        hourlyForecast = mRecentData.hourly;
      }

      var render = new RenderWeather(dc, mDs);
      var xOffsetWindFirstColumn = 0;
      if ($._showMinuteForecast) {
        var maxIdx = 0;
        if (mm != null) {
          maxIdx = mm.pops.size();

          if (maxIdx > 0 && mm.max > 0.049) {
            xOffsetWindFirstColumn = 60;
            var mmMinutesDelayed = $.getMinutesDelayed(mm.forecastTime);
            var xMMstart = x;
            var popTotal = 0.0 as Lang.Float;
            var columnWidth = 1;
            var offset = (maxIdx * columnWidth + mDs.space).toNumber();
            var rainInXminutes = 0;
            mDs.calculateColumnWidth(offset);
            for (var i = mmMinutesDelayed; i < maxIdx && i < 60; i += 1) {
              var pop = (mm as WeatherMinutely).pops[i];
              popTotal = popTotal + pop / 60.0; // pop is mm/hour, pop is for 1 minute
              if (DEBUG_DETAILS) {
                System.println(Lang.format("minutely x[$1$] pop[$2$]", [x, pop]));
              }
              if (pop > 0 && rainInXminutes == 0) {
                rainInXminutes = i - mmMinutesDelayed;
              }
              // if ($._showColumnBorder) { drawColumnBorder(dc, x, mDs.columnY, columnWidth, mDs.columnHeight); }
              // pop is float?
              // * 10.0
              drawColumnPrecipitationMillimeters(dc, COLOR_MM_RAIN, x, y, columnWidth, mDs.columnHeight, pop);
              x = x + columnWidth;
            }
            if (popTotal > 0.0) {
              // total mm in x minutes
              dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
              var rainTextTotal = popTotal.format("%.1f") + " mm";
              var rainTextTime = "in " + rainInXminutes.format("%d") + " min";
              if (mDs.smallField) {
                rainTextTime = rainInXminutes.format("%d") + " min";
                dc.drawText(
                  xMMstart,
                  mDs.columnY + mDs.columnHeight * 0.7,
                  Graphics.FONT_XTINY,
                  rainTextTime,
                  Graphics.TEXT_JUSTIFY_LEFT
                );
              } else if (mDs.wideField) {
                dc.drawText(
                  xMMstart,
                  mDs.columnY + mDs.columnHeight - 2 * dc.getFontHeight(Graphics.FONT_TINY),
                  Graphics.FONT_TINY,
                  rainTextTotal,
                  Graphics.TEXT_JUSTIFY_LEFT
                );
                dc.drawText(
                  xMMstart,
                  mDs.columnY + mDs.columnHeight - 1 * dc.getFontHeight(Graphics.FONT_TINY),
                  Graphics.FONT_TINY,
                  rainTextTime,
                  Graphics.TEXT_JUSTIFY_LEFT
                );
              } else {
                dc.drawText(
                  xMMstart,
                  mDs.columnY + mDs.columnHeight,
                  Graphics.FONT_TINY,
                  rainTextTotal,
                  Graphics.TEXT_JUSTIFY_LEFT
                );
                dc.drawText(
                  xMMstart,
                  mDs.columnY + mDs.columnHeight + dc.getFontHeight(Graphics.FONT_XTINY),
                  Graphics.FONT_TINY,
                  rainTextTime,
                  Graphics.TEXT_JUSTIFY_LEFT
                );
              }
              x = x + mDs.space;
              if (dashesUnderColumnHeight > 0) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(xMMstart, mDs.columnY + mDs.columnHeight, maxIdx * columnWidth, dashesUnderColumnHeight);
              }
              x = xMMstart + offset;
            }
          }
        }
      }

      // @@ TODO donotrepeat current/hourly @@DRY or not because of memory issue
      var validSegment = 0;
      if ($._showCurrentForecast) {
        if (current != null) {
          color = getConditionColor(current.condition, Graphics.COLOR_BLUE);
          colorOther = getConditionColor(current.conditionOther, Graphics.COLOR_BLUE);
          if (DEBUG_DETAILS) {
            System.println(Lang.format("current x[$1$] pop[$2$] color[$3$]", [x, current.info(), color]));
          }

          validSegment = validSegment + 1;

          // if ($._showColumnBorder) { drawColumnBorder(dc, x, mDs.columnY, mDs.columnWidth, mDs.columnHeight); }

          var cHeight = 0;
          nightTime = mCurrentLocation.isAtNightTime(current.forecastTime, false);
          colorClouds = COLOR_CLOUDS;
          if ($._showClouds) {
            if (nightTime) {
              colorClouds = COLOR_CLOUDS_NIGHT;
            }
            cHeight = drawColumnPrecipitationChance(
              dc,
              colorClouds,
              x,
              mDs.columnY,
              mDs.columnWidth,
              mDs.columnHeight,
              current.clouds
            );
          }
          if (mShowComfortZone) {
            render.drawComfortColumn(x, current.temperature, current.dewPoint);
          }
          // rain
          var rHeight = drawColumnPrecipitationChance(
            dc,
            color,
            x,
            mDs.columnY,
            mDs.columnWidth,
            mDs.columnHeight,
            current.precipitationChance
          );
          if ($._showClouds && rHeight < 100 && cHeight <= rHeight) {
            drawLinePrecipitationChance(
              dc,
              colorClouds,
              colorClouds,
              x,
              mDs.columnY,
              mDs.columnWidth,
              mDs.columnHeight,
              mDs.columnWidth / 3,
              current.clouds
            );
          }
          // rain other
          drawLinePrecipitationChance(
            dc,
            colorClouds,
            colorOther,
            x,
            mDs.columnY,
            mDs.columnWidth,
            mDs.columnHeight,
            mDs.columnWidth / 4,
            current.precipitationChanceOther
          );
          // mm per hour
          if (current.rain1hr > 0.0) {
            drawColumnPrecipitationMillimeters(
              dc,
              COLOR_MM_RAIN,
              x,
              mDs.columnY,
              mDs.columnWidth,
              mDs.columnHeight,
              current.rain1hr
            );
          }
          if ($._showUVIndex) {
            var uvp = new UvPoint(x + mDs.columnWidth / 2, current.uvi);
            uvp.calculateVisible(current.precipitationChance);
            uvPoints.add(uvp);
          }
          if (mShowDetails) {
            blueBarPercentage.add(current.precipitationChance);
          }

          if (mShowPressure) {
            pressurePoints.add(new WeatherPoint(x + mDs.columnWidth / 2, current.pressure, 0));
          }
          if (mShowRelativeHumidity) {
            humidityPoints.add(new WeatherPoint(x + mDs.columnWidth / 2, current.relativeHumidity, 0));
          }
          if (mShowTemperature) {
            tempPoints.add(new WeatherPoint(x + mDs.columnWidth / 2, current.temperature, mHideTemperatureLowerThan));
          }
          if (mShowDewpoint) {
            dewPoints.add(new WeatherPoint(x + mDs.columnWidth / 2, current.getDewPoint(), mHideTemperatureLowerThan));
          }
          if (mShowWind != SHOW_WIND_NOTHING || mShowWindFirst) {
            windPoints.add(new WindPoint(x, current.windBearing, current.windSpeed));
          }

          if (dashesUnderColumnHeight > 0) {
            colorDashes = Graphics.COLOR_DK_GRAY;
            if (current.precipitationChance == 0) {
              colorDashes = getConditionColor(current.condition, Graphics.COLOR_DK_GRAY);
            }
            dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, mDs.columnY + mDs.columnHeight, mDs.columnWidth, dashesUnderColumnHeight);
            if (color != colorOther && current.precipitationChanceOther == 0) {
              colorDashes = getConditionColor(current.conditionOther, Graphics.COLOR_DK_GRAY);
              dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
              dc.fillRectangle(
                x + (mDs.columnWidth / 3) * 2,
                mDs.columnY + mDs.columnHeight,
                mDs.columnWidth / 3,
                dashesUnderColumnHeight
              );
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

          x = x + mDs.columnWidth + mDs.space;
        }
      } // showCurrentForecast

      if (hourlyForecast != null) {
        var maxSegment = hourlyForecast.size();
        for (var segment = 0; validSegment < $._maxHoursForecast && segment < maxSegment; segment += 1) {
          var forecast = hourlyForecast[segment] as WeatherHourly;
          if (DEBUG_DETAILS) {
            System.println(forecast.info());
          }

          // Only forecast for the future
          // var fcTime = Gregorian.info(forecast.forecastTime, Time.FORMAT_SHORT);
          if (forecast.forecastTime.compare(Time.now()) >= 0) {
            validSegment += 1;

            color = getConditionColor(forecast.condition, Graphics.COLOR_BLUE);
            colorOther = getConditionColor(forecast.conditionOther, Graphics.COLOR_BLUE);

            if (DEBUG_DETAILS) {
              System.println(Lang.format("valid hour x[$1$] hourly[$2$] color[$3$]", [x, forecast.info(), color]));
            }

            // if ($._showColumnBorder) { drawColumnBorder(dc, x, mDs.columnY, mDs.columnWidth, mDs.columnHeight); }

            colorClouds = COLOR_CLOUDS;
            nightTime = mCurrentLocation.isAtNightTime(forecast.forecastTime, false);

            var cHeight = 0;
            if ($._showClouds) {
              if (nightTime) {
                colorClouds = COLOR_CLOUDS_NIGHT;
              }
              cHeight = drawColumnPrecipitationChance(
                dc,
                colorClouds,
                x,
                mDs.columnY,
                mDs.columnWidth,
                mDs.columnHeight,
                forecast.clouds
              );
            }
            if (mShowComfortZone) {
              render.drawComfortColumn(x, forecast.temperature, forecast.dewPoint);
            }
            // rain
            var rHeight = drawColumnPrecipitationChance(
              dc,
              color,
              x,
              mDs.columnY,
              mDs.columnWidth,
              mDs.columnHeight,
              forecast.precipitationChance
            );
            if ($._showClouds && rHeight < 100 && cHeight <= rHeight) {
              drawLinePrecipitationChance(
                dc,
                colorClouds,
                colorClouds,
                x,
                mDs.columnY,
                mDs.columnWidth,
                mDs.columnHeight,
                mDs.columnWidth / 3,
                forecast.clouds
              );
            }
            // rain other
            drawLinePrecipitationChance(
              dc,
              colorClouds,
              colorOther,
              x,
              mDs.columnY,
              mDs.columnWidth,
              mDs.columnHeight,
              mDs.columnWidth / 4,
              forecast.precipitationChanceOther
            );
            // mm per hour
            if (forecast.rain1hr > 0.0) {
              drawColumnPrecipitationMillimeters(
                dc,
                COLOR_MM_RAIN,
                x,
                mDs.columnY,
                mDs.columnWidth,
                mDs.columnHeight,
                forecast.rain1hr
              );
            }
            if (mShowDetails) {
              blueBarPercentage.add(forecast.precipitationChance);
            }

            if ($._showUVIndex) {
              var uvp = new UvPoint(x + mDs.columnWidth / 2, forecast.uvi);
              uvp.calculateVisible(forecast.precipitationChance);
              uvPoints.add(uvp);
            }
            if (mShowPressure) {
              pressurePoints.add(new WeatherPoint(x + mDs.columnWidth / 2, forecast.pressure, 0));
            }
            if (mShowRelativeHumidity) {
              humidityPoints.add(new WeatherPoint(x + mDs.columnWidth / 2, forecast.relativeHumidity, 0));
            }
            if (mShowTemperature) {
              tempPoints.add(new WeatherPoint(x + mDs.columnWidth / 2, forecast.temperature, mHideTemperatureLowerThan));
            }
            if (mShowDewpoint) {
              dewPoints.add(
                new WeatherPoint(x + mDs.columnWidth / 2, forecast.getDewPoint(), mHideTemperatureLowerThan)
              );
            }
            if (mShowWind != SHOW_WIND_NOTHING || mShowWindFirst) {
              windPoints.add(new WindPoint(x, forecast.windBearing, forecast.windSpeed));
            }

            if (dashesUnderColumnHeight > 0) {
              colorDashes = Graphics.COLOR_DK_GRAY;
              if (forecast.precipitationChance == 0) {
                colorDashes = getConditionColor(forecast.condition, Graphics.COLOR_DK_GRAY);
              }
              dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
              dc.fillRectangle(x, mDs.columnY + mDs.columnHeight, mDs.columnWidth, dashesUnderColumnHeight);
              if (color != colorOther && forecast.precipitationChanceOther == 0) {
                colorDashes = getConditionColor(forecast.conditionOther, Graphics.COLOR_DK_GRAY);
                dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(
                  x + (mDs.columnWidth / 3) * 2,
                  mDs.columnY + mDs.columnHeight,
                  mDs.columnWidth / 3,
                  dashesUnderColumnHeight
                );
              }
            }

            if (mShowDetails && mDs.oneField && forecast.precipitationChance > 50) {
              var fcTime = Gregorian.info(forecast.forecastTime, Time.FORMAT_SHORT);
              var fcTimeStr = Lang.format("$1$", [fcTime.hour]);
              dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
              dc.drawText(
                x + mDs.columnWidth / 2,
                mDs.columnY + mDs.columnHeight - 30,
                Graphics.FONT_XTINY,
                fcTimeStr,
                Graphics.TEXT_JUSTIFY_CENTER
              );
            }

            if (mShowWeatherCondition) {
              render.drawWeatherCondition(x, forecast.condition, nightTime);
              if (nightTime && !sunsetPassed) {
                render.drawSunsetIndication(x);
                sunsetPassed = true;
              }
              if (previousCondition != forecast.condition) {
                weatherTextLine = weatherTextLine == 0 ? 1 : 0;
                render.drawWeatherConditionText(x, forecast.condition, weatherTextLine);
                previousCondition = forecast.condition;
              }
            }

            x = x + mDs.columnWidth + mDs.space;
          }
        }
      } // hourlyForecast

      if ($._showUVIndex) {
        render.drawUvIndexGraph(uvPoints, $._maxUVIndex, mShowDetails, blueBarPercentage);
      }
      if (mShowTemperature) {
        render.drawTemperatureGraph(tempPoints, mShowDetails, blueBarPercentage);
      }
      if (mShowRelativeHumidity) {
        render.drawHumidityGraph(humidityPoints, mShowDetails, blueBarPercentage);
      }
      if (mShowDewpoint) {
        render.drawDewpointGraph(dewPoints, mShowDetails, blueBarPercentage);
      }
      if (mShowPressure) {
        render.drawPressureGraph(pressurePoints, mShowDetails, blueBarPercentage);
      }

      if (mShowComfortBorders) {
        render.drawComfortBorders();
      }

      if (current != null) {
        // Always show position of observation
        var distance = "";
        var distanceMetric = "km";
        var distanceInKm = 0;
        if (DEBUG_DETAILS) {
          System.println(mCurrentLocation.infoLocation());
        }
        if (mCurrentLocation.hasLocation()) {
          distanceInKm = $.getDistanceFromLatLonInKm(mLat, mLon, current.lat, current.lon);
          distance = distanceInKm.format("%.2f");
          var deviceSettings = System.getDeviceSettings();
          if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
            distanceMetric = "mi";
            distance = $.kilometerToMile(distanceInKm).format("%.2f");
          }
          var bearing = $.getRhumbLineBearing(mLat, mLon, current.lat, current.lon);
          var compassDirection = $.getCompassDirection(bearing);
          render.drawObservationLocation(Lang.format("$1$ $2$ ($3$)", [distance, distanceMetric, compassDirection]));
        }
        var showLocationName = mShowObservationLocationName;
        if (mTimerState == Activity.TIMER_STATE_PAUSED && mAlertHandler.hasAlertsHandled()) {
          showLocationName = false;
        }
        if (showLocationName) {
          render.drawObservationLocationLine2(current.observationLocationName);
        }
        render.drawObservationTime(current.observationTime);
      }

      if (mShowWindFirst) {
        if ($._showRelativeWind && !mActivityPaused) {
          render.drawWindInfoFirstColumn(windPoints, xOffsetWindFirstColumn, track);
        } else {
          render.drawWindInfoFirstColumn(windPoints, xOffsetWindFirstColumn, null);
        }
      } else if (mShowWind != SHOW_WIND_NOTHING) {
        render.drawWindInfo(windPoints);
      }

      if (mDs.wideField) {
        render.drawAlertMessages(mAlertHandler.infoHandled(), false);
      } else if (mDs.smallField) {
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

  function drawColumnPrecipitationChance(
    dc as Dc,
    color as Graphics.ColorType,
    x as Number,
    y as Number,
    bar_width as Number,
    bar_height as Number,
    precipitationChance as Number
  ) as Number {
    if (precipitationChance == 0) {
      return 0;
    }
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var barFilledHeight = bar_height - (bar_height - (bar_height.toFloat() / 100.0) * precipitationChance);
    var barFilledY = y + bar_height - barFilledHeight;
    dc.fillRectangle(x, barFilledY, bar_width, barFilledHeight);

    //
    if (mShowDetails && precipitationChance > 50 && precipitationChance < 100) {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      var h = dc.getFontHeight(Graphics.FONT_SMALL);
      dc.drawText(
        x + bar_width / 2,
        barFilledY + h,
        Graphics.FONT_SMALL,
        precipitationChance.format("%d"),
        Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
      );
    }
    return barFilledHeight.toNumber();
  }

  function drawLinePrecipitationChance(
    dc as Dc,
    colorLeftLine as Graphics.ColorType,
    color as Graphics.ColorType,
    x as Number,
    y as Number,
    bar_width as Number,
    bar_height as Number,
    line_width as Number,
    precipitationChance as Number
  ) as Number {
    if (precipitationChance == 0) {
      return 0;
    }
    var barFilledHeight = bar_height - (bar_height - (bar_height.toFloat() / 100.0) * precipitationChance);
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

  function drawColumnPrecipitationMillimeters(
    dc as Dc,
    color as Graphics.ColorType,
    x as Number,
    y as Number,
    bar_width as Number,
    bar_height as Number,
    mmhour as Float
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var max_mmPerHour = 20;
    var perc = $.percentageOf(mmhour, max_mmPerHour).toNumber();
    if (perc <= 0) {
      return;
    }
    var ymm = mDs.getYpostion(perc);
    var height = bar_height - ymm;
    var barFilledY = y + bar_height - height;
    dc.fillRectangle(x, barFilledY, bar_width, height);
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(x, barFilledY - 1, x + bar_width, barFilledY - 1);
  }

  function playAlert() as Void {
    if (Attention has :playTone) {
      Attention.playTone(Attention.TONE_CANARY);
    }
  }

  function handleWeatherAlerts() as Void {
    if (!(WatchUi.DataField has :showAlert) || !mRecentData.valid()) {
      return;
    }

    if (mRecentData.alerts.size() == 0) {
      return;
    }

    mWeatherAlertHandler.handle(mRecentData.alerts);
  }

  function getBearing(a_info as Activity.Info) as Number {
    var track = getActivityValue(a_info, :track, 0.0f) as Float;
    if (track == 0.0f) {
      track = getActivityValue(a_info, :currentHeading, 0.0f) as Float;
    }
    if (track == 0.0f) {
      track = previousTrack;
    } else {
      previousTrack = track;
    }
    return $.rad2deg(track).toNumber();
  }

  function activityIsPaused(a_info as Activity.Info) as Boolean {
    if (a_info has :timerState) {
      return a_info.timerState == Activity.TIMER_STATE_PAUSED || a_info.timerState == Activity.TIMER_STATE_OFF;
    }
    return true;
  }

  function GetCurrentInfo(a_info as Activity.Info) as CurrentInfo? {
    var devSettings = System.getDeviceSettings();
    var showInfo = $._showInfoLargeField;
    if (mDs.smallField) {
      showInfo = $._showInfoSmallField;
    }

    var info = "";
    var postfix = "";
    switch (showInfo) {
      case SHOW_INFO_NOTHING:
        return null;
      case SHOW_INFO_TIME_Of_DAY:
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var nowMin = now.min;
        var nowHour = now.hour;
        if (!devSettings.is24Hour) {
          if (!mDs.smallField) {
            postfix = "am";
            if (nowHour > 12) {
              postfix = "pm";
            }
          }
          nowHour = ((nowHour + 11).toNumber() % 12) + 1;
        }
        info = nowHour.format("%02d") + ":" + nowMin.format("%02d");
        break;

      case SHOW_INFO_TEMPERATURE:
        var temperatureCelcius = $.getStorageValue("Temperature", null) as Lang.Float?;
        if (temperatureCelcius != null) {
          postfix = "°C";
          var temperature = temperatureCelcius;
          if (devSettings.temperatureUnits == System.UNIT_STATUTE) {
            postfix = "°F";
            temperature = $.celciusToFarenheit(temperatureCelcius);
          }
          if (mDs.smallField) {
            info = temperature.format("%.0f");
          } else {
            info = temperature.format("%.2f");
          }
        }
        break;

      case SHOW_INFO_AMBIENT_PRESSURE:
        var ap = getActivityValue(a_info, :ambientPressure, 0.0f) as Float;
        if (ap > 0) {
          // pascal -> mbar (hPa)
          postfix = "hPa";
          if (mDs.smallField) {
            info = (ap / 100).format("%.0f");
          } else {
            info = (ap / 100).format("%.2f");
          }
        }
        break;

      case SHOW_INFO_SEALEVEL_PRESSURE:
        var sp = getActivityValue(a_info, :meanSeaLevelPressure, 0.0f) as Float;
        if (sp != null) {
          // pascal -> mbar (hPa)
          postfix = "~hPa";
          if (mDs.smallField) {
            info = (sp / 100).format("%.0f");
          } else {
            info = (sp / 100).format("%.2f");
          }
        }
        break;

      case SHOW_INFO_DISTANCE:
        var distanceInKm = (getActivityValue(a_info, :elapsedDistance, 0.0f) as Float) / 1000.0;
        if (distanceInKm != null) {
          postfix = "km";
          var distance = distanceInKm;
          if (devSettings.distanceUnits == System.UNIT_STATUTE) {
            postfix = "mi";
            distance = $.kilometerToMile(distanceInKm);
          }
          if (distance < 1) {
            info = distance.format("%.3f");
          } else {
            if (mDs.smallField) {
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

    var ci = new CurrentInfo();
    ci.info = info;
    ci.postfix = postfix;
    return ci;
  }

  function checkForWeatherAlerts() as Void {
    var mm = null;
    var current = null;
    var hourlyForecast = null;

    mAlertHandler.resetAllClear();

    try {
      if (!mRecentData.valid()) {
        return;
      }
      mm = mRecentData.minutely;
      current = mRecentData.current;
      hourlyForecast = mRecentData.hourly;

      if ($._showMinuteForecast) {
        var maxIdx = mm.pops.size();
        var mmMinutesDelayed = $.getMinutesDelayed(mm.forecastTime);
        var popTotal = 0.0 as Lang.Float;
        if (maxIdx > 0 && mm.max > 0.049) {
          for (var i = mmMinutesDelayed; i < maxIdx && i < 60; i += 1) {
            var pop = (mm as WeatherMinutely).pops[i];
            popTotal = popTotal + pop / 60.0; // pop is mm/hour, pop is for 1 minute
          }
          mAlertHandler.processRainMMfirstHour(popTotal);
        }
      } // showMinuteForecast

      var validSegment = 0;
      if ($._showCurrentForecast) {
        var color = getConditionColor(current.condition, Graphics.COLOR_BLUE);
        var colorOther = getConditionColor(current.conditionOther, Graphics.COLOR_BLUE);
        mAlertHandler.processPrecipitationChance(current.precipitationChance);
        mAlertHandler.processPrecipitationChance(current.precipitationChanceOther);
        mAlertHandler.processWeather(color);
        mAlertHandler.processWeather(colorOther);
        mAlertHandler.processUvi(current.uvi);
        mAlertHandler.processWindSpeed(current.windSpeed);
        mAlertHandler.processDewpoint(current.dewPoint);
      } // showCurrentForecast

      var maxSegment = hourlyForecast.size();
      for (var segment = 0; validSegment < $._maxHoursForecast && segment < maxSegment; segment += 1) {
        var forecast = hourlyForecast[segment] as WeatherHourly;

        // Only forecast for the future
        if (forecast.forecastTime.compare(Time.now()) >= 0) {
          validSegment += 1;

          var color = getConditionColor(forecast.condition, Graphics.COLOR_BLUE);
          var colorOther = getConditionColor(forecast.conditionOther, Graphics.COLOR_BLUE);
          mAlertHandler.processPrecipitationChance(forecast.precipitationChance);
          mAlertHandler.processPrecipitationChance(forecast.precipitationChanceOther);
          mAlertHandler.processWeather(color.toNumber());
          mAlertHandler.processWeather(colorOther.toNumber());
          mAlertHandler.processUvi(forecast.uvi);
          mAlertHandler.processWindSpeed(forecast.windSpeed);
          mAlertHandler.processDewpoint(forecast.dewPoint);
        }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }
}
