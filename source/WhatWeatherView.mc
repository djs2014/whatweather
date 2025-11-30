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
  var nr as Number = 0;
  var info as String = "";
  var postfix as String = "";
}

class WhatWeatherView extends WatchUi.DataField {
  hidden var mAlertHandler as AlertHandler;

  hidden var mCreateColors as Boolean = false;
  hidden var mUseSetFillStroke as Boolean = false;

  hidden var render as RenderWeather = new RenderWeather();

  hidden var mLat as Double = 0d;
  hidden var mLon as Double = 0d;
  hidden var mPreviousTrack as Float = 0.0f;
  hidden var mBearing as Number = 0;

  hidden var mBgWeatherData as WeatherData = emptyWeatherData();
  hidden var mWeatherData as WeatherData = emptyWeatherData();
  hidden var mGarminCheck as WeatherCheck = new WeatherCheck();
  hidden var mCurrentInfo as CurrentInfo?;

  // hidden var mTotalRain1stHour as Lang.Float = 0.0f;
  // hidden var mRain1stHour as Array<WeatherPoint> = [];
  hidden var mWindPoints as Array<WindPoint> = [];

  hidden var mFontInfo as Graphics.FontType = Graphics.FONT_LARGE;
  hidden var mFontPostfix as Graphics.FontType = Graphics.FONT_TINY;

  hidden var mAlertDisplayed as Array<String> = [] as Array<String>;
  hidden var mAlertFont as Graphics.FontType = Graphics.FONT_SYSTEM_SMALL;
  hidden var mAlertCounter as Number = 30;
  hidden var mAlertDisplayedOnOneField as Number = 0;
  hidden var mAlertDisplayedOnOtherField as Number = 0;
  hidden var mAlertIndex as Number = -1;
  hidden var mGetNextAlert as Boolean = true;

  hidden var mDs as DisplaySettings = new DisplaySettings();

  hidden var mHoursForecast as Number = 8;
  hidden var mShowMinuteForecast as Boolean = false;
  hidden var mZoomMinuteForecast as Boolean = false;
  hidden var mZoomMinuteForecastWhenMM as Float = 0.2f;
  hidden var mZoomMinuteForecastFactor as Number = 3;
  hidden var mZoomMinuteForecastColumns as Number = 2;
  hidden var mShowCurrentForecast as Boolean = false;
  hidden var mShowClouds as Boolean = false;
  hidden var mShowWind as Boolean = false;
  hidden var mShowWindUnit as Number = SHOW_WIND_KILOMETERS;
  hidden var mShowUv as Boolean = false;
  hidden var mShowTemperature as Boolean = false;
  hidden var mShowRelativeHumidity as Boolean = false;
  hidden var mShowPressure as Boolean = false;
  hidden var mShowDewpoint as Boolean = false;
  hidden var mShowComfortZone as Boolean = false;
  hidden var mShowWeatherCondition as Boolean = false;
  hidden var mShowExtraInfo as Number = SHOW_INFO_NOTHING;
  hidden var mShowDetailsWhenPaused as Boolean = false;
  // Note, all weather and windpoints must be calculated for mShowDetailsWhenAlert == true
  hidden var mShowDetailsWhenAlert as Boolean = false;
  // Info fields
  hidden var mShowRelativeWind as Boolean = false;
  hidden var mShowComfortBorders as Boolean = false;
  hidden var mShowObservationLocationName as Boolean = false;
  hidden var mShowObservationTime as Boolean = false;
  hidden var mShowRainTotalSize as Number = 3;

  hidden var mActivityPaused as Boolean = false;
  hidden var mShowDetails as Boolean = false;
  hidden var mTimerState as Number = 0;

  hidden var mFlashScreen as Boolean = false;
  hidden var mTriggerCheckWeatherAlerts as Boolean = true;

  hidden var mHasMinuteRains as Boolean = false;
  hidden var mCalculateLayout as Boolean = false;
  hidden var mCurrentEdgeField as EdgeField = EfLarge;
  hidden var mActiveZoomMinuteForecast as Boolean = false;
  // hidden var mCurrentHour as Number = -1;
  hidden var mDarkBackground as Boolean = false;

  function initialize() {
    DataField.initialize();

    // $.checkFeatures();

    var mCurrentLocation = $.getCurrentLocation();
    mCurrentLocation.setOnLocationChanged(self, :onLocationChanged);

    var mBGServiceHandler = $.getBGServiceHandler();
    mBGServiceHandler.setOnBackgroundData(self, :onBackgroundData);
    mBGServiceHandler.setCurrentLocation(mCurrentLocation);

    mAlertHandler = $.getAlertHandler();
    onLocationChanged(mCurrentLocation.getCurrentDegrees());
  }

  function onLocationChanged(degrees as Array<Double>) as Void {
    mLat = degrees[0];
    mLon = degrees[1];
  }

  function onBackgroundData(data as Dictionary) as Void {
    mBgWeatherData = $.toWeatherData(data);
    var mBGServiceHandler = $.getBGServiceHandler();
    mBGServiceHandler.setLastObservationMoment(mBgWeatherData.getObservationTime());
    mTriggerCheckWeatherAlerts = true;
    data = null;
  }

  function onLayout(dc as Dc) as Void {
    dc.clearClip();

    calculateLayout(dc);
    calculateOWMAlerts(dc);
  }

  function compute(info as Activity.Info) as Void {
    try {
      var mBGServiceHandler = $.getBGServiceHandler();

      if ($.gSettingsChanged) {
        mTriggerCheckWeatherAlerts = true;
        $.gSettingsChanged = false;

        var resetAlerts = $.getStorageValue("resetAlerts", false) as Boolean;
        if (resetAlerts) {
          Storage.setValue("resetAlerts", false);
          resetOWMAlerts();
        }
      }

      mBearing = getBearing(info);
      mCurrentInfo = getCurrentInfo(info);
      mActivityPaused = activityIsPaused(info);
      mShowDetails = mActivityPaused && mShowDetailsWhenPaused;

      if (info has :timerState && info.timerState != null) {
        mTimerState = info.timerState as Lang.Number;
      }
      mBGServiceHandler.onCompute(info);
      if ($.g_bg_delay_seconds <= 0) {
        mBGServiceHandler.autoScheduleService();
      } else {
        $.g_bg_delay_seconds = $.g_bg_delay_seconds - 1;
      }

      var garminWeather = $.purgePastWeatherdata(getLatestGarminWeather());
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
      mBgWeatherData = $.purgePastWeatherdata(mBgWeatherData);
      mWeatherData = $.mergeWeatherData(garminWeather, mBgWeatherData, $._weatherDataSource);

      if (DEBUG_DETAILS) {
        System.println(
          Lang.format("Is weatherChanged Request[$1$] background[$2$] garmin[$3$] merged[$4$]", [
            mTriggerCheckWeatherAlerts,
            mBgWeatherData.changed,
            garminWeatherChanged,
            mWeatherData.changed,
          ])
        );
      }

      if (mTriggerCheckWeatherAlerts || mWeatherData.changed || garminWeatherChanged) {
        if (DEBUG_DETAILS) {
          System.println(
            Lang.format("WeatherChanged[$1$] mWeatherData.changed[$2$] mBgWeatherData.changed[$3$] garminWeatherChanged[$4$]", [
              mTriggerCheckWeatherAlerts,
              mWeatherData.changed,
              mBgWeatherData.changed,
              garminWeatherChanged,
            ])
          );
        }
        mTriggerCheckWeatherAlerts = false;
        mBgWeatherData.setChanged(false);
        mWeatherData.setChanged(false);

        mAlertHandler.checkStatus();
        checkForWeatherAlerts();
        if (mAlertHandler.isAnyAlertTriggered()) {
          mFlashScreen = true;
          playAlert();
          mAlertHandler.currentlyTriggeredHandled();
        }
      }
      // TODO - calc all weather points ..
      // computeAllWheater();
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  // On hour change, we shift the weather forcast. Not showing past hour.
  // function newHour() as Boolean {
  //   var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
  //   if (mCurrentHour == today.hour) {
  //     return false;
  //   }
  //   mCurrentHour = today.hour;
  //   return true;
  // }

  function onUpdate(dc as Dc) as Void {
    try {
      if ($.gExitedMenu) {
        // fix for leaving menu, draw complete screen, large field
        dc.clearClip();
        $.gExitedMenu = false;
        calculateLayout(dc);
        mCalculateLayout = false;
      } else if (mCalculateLayout) {
        mCalculateLayout = false;
        calculateLayout(dc);
      }

      if (dc has :setAntiAlias) {
        dc.setAntiAlias(true);
      }

      // var backgroundColor = Graphics.COLOR_WHITE;
      var backgroundColor = getBackgroundColor();
      mDarkBackground = backgroundColor == Graphics.COLOR_BLACK;
      mDs.setColors(mDarkBackground);

      mAlertHandler.checkStatus();
      if (mFlashScreen) {
        mFlashScreen = false;
        backgroundColor = mDs.COLOR_BACKGROUND_ALERT;
      }

      dc.setColor(backgroundColor, backgroundColor);
      dc.clear();

      var validWeather = onUpdateWeather(dc);

      drawPrecipitationChanceAxis(dc, mDs.margin, mDs.columnHeight);

      showInfo(dc);
      showBgInfo(dc, validWeather);

      calculateOWMAlerts(dc);
      handleOWMAlerts(dc);
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  hidden function calculateLayout(dc as Dc) as Void {
    mShowComfortBorders = true;
    mShowObservationLocationName = true;
    mShowObservationTime = true;
    mShowRainTotalSize = 3;
    mCurrentEdgeField = $.getEdgeField(dc);
    var arrShowField = $.gShow_OneField;
    if (mCurrentEdgeField == EfLarge) {
      arrShowField = $.gShow_LargeField;
      mShowRainTotalSize = 2;
      mShowObservationLocationName = false;
    } else if (mCurrentEdgeField == EfWide) {
      arrShowField = $.gShow_WideField;
      mShowRainTotalSize = 2;
      mShowComfortBorders = false;
      mShowObservationLocationName = false;
      mShowObservationTime = false;
    } else if (mCurrentEdgeField == EfSmall) {
      arrShowField = $.gShow_SmallField;
      mShowRainTotalSize = 1;
      mShowComfortBorders = false;
      mShowObservationLocationName = false;
      mShowObservationTime = false;
    }

    if (DEBUG_DETAILS) {
      System.println(["Onlayout", arrShowField]);
    }
    mHoursForecast = arrShowField[0];
    mShowMinuteForecast = arrShowField[1] == true;
    mZoomMinuteForecast = arrShowField[2] == true;
    mZoomMinuteForecastWhenMM = arrShowField[3];
    mZoomMinuteForecastFactor = arrShowField[4];
    mZoomMinuteForecastColumns = arrShowField[5];
    mShowCurrentForecast = arrShowField[6] == true;
    mShowClouds = arrShowField[7] == true;
    mShowWind = arrShowField[8] == true;
    mShowWindUnit = arrShowField[9];
    mShowUv = arrShowField[10] == true;
    mShowTemperature = arrShowField[11] == true;
    mShowRelativeHumidity = arrShowField[12] == true;
    mShowPressure = arrShowField[13] == true;
    mShowDewpoint = arrShowField[14] == true;
    mShowComfortZone = arrShowField[15] == true;
    mShowWeatherCondition = arrShowField[16] == true;
    mShowExtraInfo = arrShowField[17];
    mShowDetailsWhenPaused = arrShowField[18] == true;
    mShowDetailsWhenAlert = arrShowField[19] == true;
    mShowRelativeWind = mShowExtraInfo == SHOW_INFO_RELATIVE_WIND;

    // Height wind icons
    var heightWind = mShowWind ? 15 : 0;
    // Height weather icons / text
    var heightWc = mShowWeatherCondition ? 15 : 0;
    var heightWt = mShowWeatherCondition ? dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY) : 0;
    mDs.calculate(dc, mHoursForecast, heightWind, heightWc, heightWt);

    render.initValues(dc, mDs, mCurrentEdgeField);
  }

  hidden function showBgInfo(dc as Dc, hasWeatherData as Boolean) as Void {
    if ($._weatherDataSource == wsGarminOnly) {
      return;
    }

    var mBGServiceHandler = $.getBGServiceHandler();
    if (!mBGServiceHandler.isEnabled()) {
      return;
    }

    var color = mDs.COLOR_TEXT;
    var text;
    var status;
    if (mBGServiceHandler.hasError()) {
      status = mBGServiceHandler.getError();
    } else {
      status = mBGServiceHandler.getStatus();
    }
    if (!hasWeatherData) {
      // Counting down to next weather request
      text = mBGServiceHandler.getErrorMessage() + " " + status + "(" + mBGServiceHandler.getWhenNextRequest("") + ")";
      dc.setColor(color, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        dc.getWidth() / 2,
        dc.getHeight() / 2,
        Graphics.FONT_SYSTEM_SMALL,
        text,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }

    var delayed = mBGServiceHandler.isDataDelayed();
    var delayedIndication = "";
    if (!mShowObservationTime) {
      if (delayed) {
        color = Graphics.COLOR_RED;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        delayedIndication = "!";
        var textWHsmall = dc.getTextDimensions(delayedIndication, Graphics.FONT_XTINY);
        dc.drawText(
          dc.getWidth() - textWHsmall[0],
          dc.getHeight() - textWHsmall[1],
          Graphics.FONT_XTINY,
          delayedIndication,
          Graphics.TEXT_JUSTIFY_LEFT
        );
      }
      return;
    }

    if (delayed) {
      color = mDs.COLOR_TEXT_ALERT;
      delayedIndication = "!";
    }
    // obsTime = $.getShortTimeString(mBgWeatherData.getObservationTime());

    var counter = "#" + mBGServiceHandler.getCounterStats();
    var next = mBGServiceHandler.getWhenNextRequest("");
    if ($.g_bg_delay_seconds > 0) {
      next = $.g_bg_delay_seconds.format("%d");
    }
    text = mBGServiceHandler.getErrorMessage() + " " + delayedIndication + counter + " " + status + "(" + next + ")";

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var textWH = dc.getTextDimensions(text, Graphics.FONT_XTINY);
    dc.drawText(dc.getWidth() - textWH[0], dc.getHeight() - textWH[1], Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_LEFT);
  }

  hidden function showInfo(dc as Dc) as Void {
    if (mCurrentInfo == null) {
      return;
    }

    var ci = mCurrentInfo as CurrentInfo;
    if (ci.nr == SHOW_INFO_RELATIVE_WIND) {
      // Done somewhere else
      return;
    }

    var info = ci.info;
    var postfix = ci.postfix;

    var wi = dc.getTextWidthInPixels(info, mFontInfo);
    var wp = dc.getTextWidthInPixels(postfix, mFontPostfix);
    var xi = mDs.width / 2 - (wi + wp) / 2;

    dc.setColor(mDs.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
    dc.drawText(xi, mDs.height / 2, mFontInfo, info, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    dc.drawText(xi + wi + 1, mDs.height / 2, mFontPostfix, postfix, Graphics.TEXT_JUSTIFY_LEFT);
  }

  // Returns true when valid weather data
  function onUpdateWeather(dc as Dc) as Boolean {
    var x = mDs.columnX;
    var y = mDs.columnY;

    var tempPoints = [];
    var dewPoints = [];

    var blueBarPercentage = [] as Array<Number>;

    var previousCondition = -1;
    var weatherTextLine = 0;
    var sunsetPassed = false;

    var skipFirstForecast = false;

    var maxHoursForecast = mHoursForecast;

    try {
      if (!mWeatherData.valid()) {
        return false;
      }

      var mCurrentLocation = $.getCurrentLocation();

      if (mShowMinuteForecast) {
        var maxIdx = 0;
        var mm = WeatherData.minutely;
        if (mm != null) {
          maxIdx = mm.pops.size();
          var show5minMarker = false;
          var popTotal = 0.0 as Lang.Float;
          if (maxIdx > 0 && mm.max > 0.049) {
            var mmMinutesDelayed = $.getMinutesDelayed(mm.forecastTime);
            var xMMstart = x;
            var columnWidth = 1;
            var max_mmPerHour = $._maxMMRainPerHour;
            if (mActiveZoomMinuteForecast) {
              columnWidth = 3; // @@TODO calculate width based on nrOfColumns / width of screen
              maxHoursForecast = mZoomMinuteForecastColumns;
              show5minMarker = true;
              if (mZoomMinuteForecastFactor == 0) {
                mZoomMinuteForecastFactor = 3;
              }
              // Zoom in, or else small amounts not visible.
              max_mmPerHour = max_mmPerHour / mZoomMinuteForecastFactor;
              skipFirstForecast = true;
              System.println(["Zoom maxHoursForecast", maxHoursForecast]);
            }
            var offset = (maxIdx * columnWidth + mDs.space).toNumber();
            var rainInXminutes = -1;
            var rainLastEntry = 0;
            mDs.calculateColumnWidth(offset, maxHoursForecast);
            for (var i = mmMinutesDelayed; i < maxIdx && i < 60; i += 1) {
              var pop = (mm as WeatherMinutely).pops[i];
              popTotal = popTotal + pop; // / 60.0; // popTotal is mm/hour, pop is for 1 minute
              if (DEBUG_DETAILS) {
                System.println(Lang.format("minutely x[$1$] pop[$2$] i[$3$]", [x, pop, i]));
              }
              if (pop > 0 && rainInXminutes < 0) {
                // First rain happens in i minutes
                rainInXminutes = i - mmMinutesDelayed - 1;
              }

              drawColumnPrecipitationMillimeters(dc, mDs.COLOR_MM_RAIN, x, y, columnWidth, mDs.columnHeight, pop, max_mmPerHour);

              if (show5minMarker && (i + mmMinutesDelayed) % 5 == 0) {
                //Draw 5 min marker
                drawColumnPrecipitationMillimetersDivider(dc, mDs.COLOR_MM_DIVIDER, x, y, columnWidth, mDs.columnHeight, 5);
              }
              x = x + columnWidth;
              rainLastEntry = rainLastEntry + 1;
            }
            if (rainLastEntry > 0 && rainLastEntry < 59) {
              // System.println("rainLastEntry: " + rainLastEntry);
              drawColumnPrecipitationMillimetersDivider(dc, mDs.COLOR_MM_DIVIDER, x, y, columnWidth, mDs.columnHeight, 5);
            }

            if (popTotal > 0.0) {
              mHasMinuteRains = true;
              dc.setColor(mDs.COLOR_MM_DETAILS, Graphics.COLOR_TRANSPARENT);
              // // popTotal is mm/hour, pop is for 1 minute
              var rainTextTotal = (popTotal / 60.0).format("%.2f") + " mm";
              var rainTextTime = "in " + rainInXminutes.format("%d") + " min";
              if (mShowRainTotalSize == 1) {
                rainTextTime = rainInXminutes.format("%d") + " min";
                dc.drawText(
                  xMMstart,
                  mDs.columnY + mDs.columnHeight * 0.7,
                  Graphics.FONT_XTINY,
                  rainTextTime,
                  Graphics.TEXT_JUSTIFY_LEFT
                );
              } else if (mShowRainTotalSize == 2) {
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
              } else if (mShowRainTotalSize == 3) {
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
              if (mDs.dashesUnderColumnHeight > 0) {
                dc.setColor(mDs.COLOR_TEXT_DASHES, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(xMMstart, mDs.columnY + mDs.columnHeight, maxIdx * columnWidth, mDs.dashesUnderColumnHeight);
              }
              x = xMMstart + offset;
            }
          }
          if (popTotal == 0.0 && mHasMinuteRains) {
            // No mm rain anymore, recalculate layout
            mCalculateLayout = true;
            mHasMinuteRains = false;
            mActiveZoomMinuteForecast = false;
          }
        }
      }

      var hourlyForecast = mWeatherData.hourly;
      if (hourlyForecast != null) {
        var maxForecast = hourlyForecast.size();
        for (var fcIdx = 0; fcIdx < maxHoursForecast && fcIdx < maxForecast; fcIdx += 1) {
          if (skipFirstForecast && fcIdx == 0) {
            System.println("Skip first forecast due to rain 1stmm zoom");
            continue;
          }
          var forecast = hourlyForecast[fcIdx] as WeatherHourly;
          if (DEBUG_DETAILS) {
            System.println(forecast.info());
          }

          var colorCondition = getConditionColor(forecast.condition, Graphics.COLOR_BLUE, mDarkBackground);
          var colorOtherCondition = getConditionColor(forecast.conditionOther, Graphics.COLOR_BLUE, mDarkBackground);
          var cloudColor = mDs.COLOR_CLOUDS;

          if (DEBUG_DETAILS) {
            System.println(
              Lang.format("valid hour x[$1$] hourly[$2$] colorCondition[$3$]", [x, forecast.info(), colorCondition])
            );
          }

          var cloudHeight = 0;
          if (mShowClouds) {
            cloudHeight = drawColumnChance(dc, cloudColor, x, mDs.columnY, mDs.columnWidth, mDs.columnHeight, forecast.clouds);
          }
          if (mShowComfortZone) {
            render.drawComfortColumn(dc, x, forecast.dewPoint, mDarkBackground);
          }
          // rain
          var rainHeight = drawColumnChance(
            dc,
            colorCondition,
            x,
            mDs.columnY,
            mDs.columnWidth,
            mDs.columnHeight,
            forecast.precipitationChance
          );
          if (mShowClouds && rainHeight < 100 && cloudHeight <= rainHeight) {
            drawLineChance(
              dc,
              cloudColor,
              cloudColor,
              x,
              mDs.columnY,
              mDs.columnWidth,
              mDs.columnHeight,
              mDs.columnWidth / 3,
              forecast.clouds
            );
          }
          // rain other
          drawLineChance(
            dc,
            cloudColor,
            colorOtherCondition,
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
              mDs.COLOR_MM_RAIN,
              x,
              mDs.columnY,
              mDs.columnWidth,
              mDs.columnHeight,
              forecast.rain1hr,
              $._maxMMRainPerHour
            );
          }

          var bluebarPerc = forecast.precipitationChance;
          var xCenterColumn = x + mDs.columnWidth / 2;

          if (mShowDetails) {
            blueBarPercentage.add(forecast.precipitationChance);
          }

          if (mShowUv) {
            render.drawUvIndexItem(dc, xCenterColumn, forecast.uvi, $._maxUVIndex, mShowDetails, bluebarPerc);
          }
          if (mShowPressure) {
            render.drawPressureItem(dc, xCenterColumn, forecast.pressure, mShowDetails, bluebarPerc);
          }

          if (mShowRelativeHumidity) {            
            render.drawHumidityItem(dc, xCenterColumn, forecast.relativeHumidity, mShowDetails, bluebarPerc);
          }
          if (mShowTemperature) {
            render.drawTemperatureItem(dc, xCenterColumn,forecast.temperature, mShowDetails, bluebarPerc);
          }

          if (mShowDewpoint) {
            render.drawDewpointItem(dc, xCenterColumn,forecast.dewPoint, mShowDetails, bluebarPerc, mDarkBackground);
          }

          if (fcIdx < mWindPoints.size()) {
            mWindPoints[fcIdx].setXposition(x);
          }

          if (mDs.dashesUnderColumnHeight > 0 || forecast.rain1hr > 0.0) {
            // TODO Only for small field?
            var dh = mDs.dashesUnderColumnHeight;
            var colorDashes = Graphics.COLOR_DK_GRAY;
            if (forecast.rain1hr > 0.0) {
              colorDashes = mDs.COLOR_MM_RAIN;
              if (dh == 0) {
                dh = 1;
              }
            } else if (forecast.precipitationChance == 0) {
              colorDashes = getConditionColor(forecast.condition, Graphics.COLOR_DK_GRAY, mDarkBackground);
            }
            dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, mDs.columnY + mDs.columnHeight, mDs.columnWidth, dh);
            if (colorCondition != colorOtherCondition && forecast.precipitationChanceOther == 0) {
              colorDashes = getConditionColor(forecast.conditionOther, Graphics.COLOR_DK_GRAY, mDarkBackground);
              dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
              dc.fillRectangle(x + (mDs.columnWidth / 3) * 2, mDs.columnY + mDs.columnHeight + 1, mDs.columnWidth / 3, dh);
            }
          }

          if (mShowDetails) {
            // Show rain mm
            var infoStr = "";
            if (forecast.rain1hr > 0.0) {
              infoStr = forecast.rain1hr.format("%.1f");
              dc.setColor(mDs.COLOR_TEXT_DETAILS, Graphics.COLOR_TRANSPARENT);
              dc.drawText(
                x + mDs.columnWidth / 2,
                mDs.columnY + mDs.columnHeight - 30,
                Graphics.FONT_XTINY,
                infoStr,
                Graphics.TEXT_JUSTIFY_CENTER
              );
            }
          }

          if (mShowWeatherCondition) {
            var nightTime = mCurrentLocation.isAtNightTime(forecast.forecastTime, false);
            render.drawWeatherCondition(dc, x, forecast.condition, nightTime);
            if (nightTime && !sunsetPassed) {
              render.drawSunsetIndication(dc, x);
              sunsetPassed = true;
            }
            if (previousCondition != forecast.condition) {
              weatherTextLine = weatherTextLine == 0 ? 1 : 0;
              render.drawWeatherConditionText(dc, x, forecast.condition, weatherTextLine);
              previousCondition = forecast.condition;
            }
          }

          x = x + mDs.columnWidth + mDs.space;
        }
      } // hourlyForecast
     
      // TODO dashed line ??
      if (mShowComfortBorders) {
        render.drawComfortBorders(dc);
      }

      if (mWeatherData.observation != null) {
        var wo = mWeatherData.observation;
        // Always show position of observation
        var distance = "";
        var distanceMetric = "km";
        var distanceInKm = 0;
        if (DEBUG_DETAILS) {
          System.println(mCurrentLocation.infoLocation());
        }
        if (mCurrentLocation.hasLocation()) {
          distanceInKm = $.getDistanceFromLatLonInKm(mLat, mLon, wo.lat, wo.lon);
          distance = distanceInKm.format("%.2f");
          var deviceSettings = System.getDeviceSettings();
          if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
            distanceMetric = "mi";
            distance = $.kilometerToMile(distanceInKm).format("%.2f");
          }
          var bearing = $.getRhumbLineBearing(mLat, mLon, wo.lat, wo.lon);
          var compassDirection = $.getCompassDirection(bearing);
          render.drawObservationLocation(dc, Lang.format("$1$ $2$ ($3$)", [distance, distanceMetric, compassDirection]));
        }
        var showLocationName = mShowObservationLocationName;
        if (mTimerState == Activity.TIMER_STATE_PAUSED && mAlertHandler.hasAlertsHandled()) {
          showLocationName = false;
        }
        if (showLocationName) {
          render.drawObservationLocationLine2(dc, wo.observationLocationName);
        }
        render.drawObservationTime(dc, wo.observationTime);
      }

      // Wind icons or wind relative or wind first column

      // mShowDetailsWhenAlert only for wind TODO others
      // TODO merge in forecastloop
      if (mShowWind || mShowDetailsWhenAlert) {
        var maxWp = mWindPoints.size();
        for (var idx = 0; idx < maxWp; idx++) {
          var wp = mWindPoints[idx] as WindPoint;
          if (mShowWind || wp.hasAlert()) {
            var xW = wp.x + mDs.columnWidth / 2;
            var yW = mDs.columnY + mDs.columnHeight + mDs.heightWind / 2;
            render.drawWind(dc, xW, yW, wp, 0, false);
          }
        }
      }

      if (mShowRelativeWind || mShowDetailsWhenAlert) {
        var activityBearing = mBearing;
        if (mActivityPaused) {
          activityBearing = 0;
        }
        if (mWindPoints.size() > 0) {
          var wp1 = mWindPoints[0] as WindPoint;
          var show = mShowRelativeWind || wp1.hasAlert();
          // In center of screen. Show big arrow when moving or has alert
          var bigArrow = activityBearing != 0 || wp1.hasAlert();
          render.drawWind(dc, mDs.width / 2, mDs.columnY + mDs.columnHeight / 2, wp1, activityBearing, bigArrow);
        }
      }

      if (mCurrentEdgeField == EfWide) {
        render.drawAlertMessages(dc, mAlertHandler.infoHandled(), false);
      } else if (mCurrentEdgeField == EfSmall) {
        render.drawAlertMessagesVert(dc, mAlertHandler.infoHandledShort());
      } else {
        render.drawAlertMessages(dc, mAlertHandler.infoHandled(), mActivityPaused);
      }
      return true;
    } catch (ex) {
      ex.printStackTrace();
    }
    return false;
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

  function drawColumnChance(
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
      dc.setColor(mDs.COLOR_TEXT_DETAILS, Graphics.COLOR_TRANSPARENT);
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

  function drawLineChance(
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
    mmhour as Float,
    max_mmPerHour as Number
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    // var max_mmPerHour = $._maxMMRainPerHour;
    var perc = $.percentageOf(mmhour, 0, max_mmPerHour).toNumber();
    if (perc <= 0) {
      return;
    }
    var ymm = mDs.getYpostion(perc);
    var height = bar_height - ymm;
    var barFilledY = y + bar_height - height;
    dc.fillRectangle(x, barFilledY, bar_width, height);
    dc.setColor(mDs.COLOR_TEXT_DETAILS, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(x, barFilledY - 1, x + bar_width, barFilledY - 1);
  }

  function drawColumnPrecipitationMillimetersDivider(
    dc as Dc,
    color as Graphics.ColorType,
    x as Number,
    y as Number,
    bar_width as Number,
    bar_height as Number,
    divider_height as Number
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var y1 = y + bar_height - divider_height;
    var y2 = y + bar_height + divider_height;
    dc.drawLine(x, y1, x, y2);
  }

  function playAlert() as Void {
    if ($._alertBacklight && Attention has :backlight) {
      try {
        Attention.backlight(true);
      } catch (ex) {
        System.println("Attention.backlight(true) failed");
        ex.printStackTrace();
      }
    }

    if ($._soundMode == 0 || !(Attention has :playTone) || !System.getDeviceSettings().tonesOn) {
      return;
    }
    if ($._soundMode == 1) {
      Attention.playTone(Attention.TONE_KEY);
      return;
    }
    if ($._soundMode == 2) {
      Attention.playTone(Attention.TONE_CANARY);
      return;
    }
    if ($._soundMode == 3) {
      // TODO quick fix, no toneprofile on edge1050
      if ($.getEdgeVersion() >= 1050) {
        Attention.playTone(Attention.TONE_LAP);
        return;
      }

      var toneProfile =
        [new Attention.ToneProfile(800, 40), new Attention.ToneProfile(1200, 150), new Attention.ToneProfile(3000, 0)] as
        Lang.Array<Attention.ToneProfile>;
      Attention.playTone({ :toneProfile => toneProfile, :repeatCount => 1 });
    }
  }

  function getBearing(a_info as Activity.Info) as Number {
    var track = getActivityValue(a_info, :track, 0.0f) as Float;
    if (track == 0.0f) {
      track = getActivityValue(a_info, :currentHeading, 0.0f) as Float;
    }
    if (track == 0.0f) {
      track = mPreviousTrack;
    } else {
      mPreviousTrack = track;
    }
    return $.rad2deg(track).toNumber();
  }

  function activityIsPaused(info as Activity.Info) as Boolean {
    if (info has :timerState) {
      return info.timerState == Activity.TIMER_STATE_PAUSED || info.timerState == Activity.TIMER_STATE_OFF;
    }
    return true;
  }

  function getCurrentInfo(a_info as Activity.Info) as CurrentInfo? {
    var info = "";
    var postfix = "";
    switch (mShowExtraInfo) {
      case SHOW_INFO_NOTHING:
        return null;
      case SHOW_INFO_TIME_Of_DAY:
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var nowMin = now.min;
        var nowHour = now.hour;
        if (!System.getDeviceSettings().is24Hour) {
          if (mCurrentEdgeField != EfSmall) {
            postfix = "am";
            if (nowHour > 12) {
              postfix = "pm";
            }
          }
          nowHour = ((nowHour + 11).toNumber() % 12) + 1;
        }
        info = nowHour.format("%02d") + ":" + nowMin.format("%02d");
        break;

      case SHOW_INFO_AMBIENT_PRESSURE:
        var ap = getActivityValue(a_info, :ambientPressure, 0.0f) as Float;
        if (ap > 0) {
          // pascal -> mbar (hPa)
          postfix = "hPa";
          if (mCurrentEdgeField == EfSmall) {
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
          if (mCurrentEdgeField == EfSmall) {
            //TODO format is in onlayout.
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
          if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
            postfix = "mi";
            distance = $.kilometerToMile(distanceInKm);
          }
          if (distance < 1) {
            info = distance.format("%.3f");
          } else {
            if (mCurrentEdgeField == EfSmall) {
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
      case SHOW_INFO_RELATIVE_WIND:
        break;
    }

    System.println("Info: " + mShowExtraInfo + "|" + info + " " + postfix);
    var ci = new CurrentInfo();
    ci.nr = mShowExtraInfo;
    ci.info = info;
    ci.postfix = postfix;
    return ci;
  }

  // Build weather data to be displayed - TEST calculate windpoints
  // TODO, build all weather points
  // TODO -> current will be index 0 [0]?
  // Check for alerts
  function checkForWeatherAlerts() as Void {
    mActiveZoomMinuteForecast = false;

    var hasAlert;
    var hasAlert2;
    var wPoint;

    mAlertHandler.resetAllClear();
    mWindPoints = [];

    try {
      if (!mWeatherData.valid()) {
        return;
      }
      var mm = mWeatherData.minutely;
      var hourlyForecast = mWeatherData.hourly;

      if (mShowMinuteForecast) {
        var maxIdx = mm.pops.size();
        var mmMinutesDelayed = $.getMinutesDelayed(mm.forecastTime);
        var popTotal = 0.0 as Lang.Float;
        if (maxIdx > 0 && mm.max > 0.049) {
          for (var i = mmMinutesDelayed; i < maxIdx && i < 60; i += 1) {
            var pop = (mm as WeatherMinutely).pops[i];
            popTotal = popTotal + pop;
          }
          popTotal = popTotal / 60.0; // popTotal is mm/hour, pop is for 1 minute
          mAlertHandler.processRainMMfirstHour(popTotal);

          mActiveZoomMinuteForecast = mZoomMinuteForecast && popTotal >= mZoomMinuteForecastWhenMM;
        }
      } // showMinuteForecast

      // ?? mShowCurrentForecast

      // We always have valid forecast hours
      var maxHourly = hourlyForecast.size();
      for (var idx = 0; idx < mHoursForecast && idx < maxHourly; idx += 1) {
        var forecast = hourlyForecast[idx] as WeatherHourly;

        mAlertHandler.processPrecipitationChance(forecast.precipitationChance);
        mAlertHandler.processPrecipitationChance(forecast.precipitationChanceOther);
        mAlertHandler.processWeather(forecast.condition);
        mAlertHandler.processWeather(forecast.conditionOther);
        mAlertHandler.processUvi(forecast.uvi);

        hasAlert = mAlertHandler.processWindSpeed(forecast.windSpeed);
        hasAlert2 = mAlertHandler.processWindGust(forecast.windSpeed, forecast.windGust);
        if (mShowWind || mShowRelativeWind || mShowDetailsWhenAlert) {
          wPoint = new WindPoint(forecast.windBearing, forecast.windSpeed, hasAlert, forecast.windGust, hasAlert2);
          wPoint.setUIelements(mShowWindUnit);
          mWindPoints.add(wPoint);
        }

        mAlertHandler.processDewpoint(forecast.dewPoint);
        mAlertHandler.processRainMMHour(forecast.rain1hr);
      }

      var hasOWMAlert = mWeatherData.alerts.size() > 0;
      mAlertHandler.processOWMAlert(hasOWMAlert);
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function resetOWMAlerts() as Void {
    mAlertDisplayedOnOneField = 0;
    mAlertDisplayedOnOtherField = 0;
    mAlertCounter = 30;
    mAlertIndex = -1;
    mAlertDisplayed = [];
    mGetNextAlert = true;

    for (var i = 0; i < mWeatherData.alerts.size(); i++) {
      var alert = mWeatherData.alerts[i];
      alert.handled = false;
    }
  }

  function calculateOWMAlerts(dc as Dc) as Void {
    if (!mWeatherData.valid()) {
      return;
    }

    if (mWeatherData.alerts.size() == 0) {
      mAlertIndex = -1;
      return;
    }

    if (mAlertIndex > -1 && !mGetNextAlert) {
      return;
    }

    mGetNextAlert = false;
    for (var i = 0; i < mWeatherData.alerts.size(); i++) {
      var alert = mWeatherData.alerts[i];
      if (!alert.handled) {
        mAlertIndex = i;
        mAlertFont = $.getMatchingFont(dc, mDs.alertFonts, dc.getWidth() - 2, alert.event, -1);
        return;
      }
    }

    mAlertIndex = -1;
  }

  function handleOWMAlerts(dc as Dc) as Void {
    if (!mWeatherData.valid()) {
      return;
    }

    if (mWeatherData.alerts.size() == 0 || mAlertIndex <= -1 || mAlertIndex >= mWeatherData.alerts.size()) {
      mAlertDisplayedOnOneField = 0;
      mAlertDisplayedOnOtherField = 0;
      mAlertCounter = 30;
      mAlertIndex = -1;
      return;
    }

    var alert = mWeatherData.alerts[mAlertIndex];

    if (alert.handled || alert.start == null || alert.end == null) {
      alert.handled = true;
      mAlertDisplayedOnOneField = 0;
      mAlertDisplayedOnOtherField = 0;
      mAlertCounter = 30;
      mGetNextAlert = true;
      return;
    }

    var key = alert.event + (alert.start as Moment).value().format("%d") + (alert.end as Moment).value().format("%d");

    if (mAlertDisplayed.indexOf(key) > -1) {
      return;
    }
    mAlertCounter = mAlertCounter - 1;
    System.println("Counter: " + mAlertCounter);
    if (mAlertCounter < 0) {
      mAlertDisplayed.add(key);
      alert.handled = true;
      mAlertDisplayedOnOneField = 0;
      mAlertDisplayedOnOtherField = 0;
      mAlertCounter = 30;
      mGetNextAlert = true;
    }

    if (mCurrentEdgeField != EfOne) {
      // small - one - small -> exit alert
      if (mAlertDisplayedOnOtherField == 0) {
        mAlertDisplayedOnOtherField = 1;
      } else if (mAlertDisplayedOnOtherField == 1 && mAlertDisplayedOnOneField > 1) {
        mAlertDisplayed.add(key);
        alert.handled = true;
        mGetNextAlert = true;
      }

      var x = 1;
      var width = dc.getWidth() - 2;
      var height = dc.getHeight() / 3;
      var y = height;
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
      dc.fillRectangle(x, y, width, height);

      var text = alert.event;
      System.println(text);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        dc.getWidth() / 2,
        dc.getHeight() / 2,
        mAlertFont,
        text,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    } else {
      // one - small - one - small -> exit alert
      if (mAlertDisplayedOnOneField == 0) {
        mAlertDisplayedOnOneField = 1;
      } else if (mAlertDisplayedOnOneField == 1 && mAlertDisplayedOnOtherField > 0) {
        mAlertDisplayedOnOneField = 2;
      }

      var x = 1;
      var y = 1;
      var width = dc.getWidth();
      var height = dc.getHeight();
      dc.setColor(mDs.COLOR_BACKGROUND, mDs.COLOR_BACKGROUND);
      dc.fillRectangle(x, y, width, height);
      dc.setColor(mDs.COLOR_TEXT_ALERT, Graphics.COLOR_TRANSPARENT);
      dc.setPenWidth(3);
      dc.drawRectangle(x, y, width, height);
      dc.setPenWidth(1);

      x = 5;
      dc.setColor(mDs.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);

      var lineHeight = dc.getFontHeight(mAlertFont);
      y = y + lineHeight;
      dc.drawText(dc.getWidth() / 2, y, mAlertFont, alert.event, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

      y = y + lineHeight;
      var counterText = mAlertCounter.format("%d");
      if (mWeatherData.alerts.size() > 1) {
        counterText = counterText + " " + (mAlertIndex + 1).format("%d") + "/" + mWeatherData.alerts.size().format("%d");
      }
      dc.drawText(
        dc.getWidth() / 2,
        y,
        Graphics.FONT_TINY,
        counterText,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
      y = y + lineHeight;

      lineHeight = dc.getFontHeight(Graphics.FONT_SMALL);
      var start = Time.Gregorian.info(alert.start as Time.Moment, Time.FORMAT_MEDIUM);
      var startString =
        "From " +
        Lang.format("$1$-$2$-$3$ $4$:$5$", [
          start.day,
          start.month,
          start.year,
          start.hour.format("%02d"),
          start.min.format("%02d"),
        ]);
      dc.drawText(x, y, Graphics.FONT_SMALL, startString, Graphics.TEXT_JUSTIFY_LEFT);
      y = y + lineHeight;

      var end = Time.Gregorian.info(alert.end as Time.Moment, Time.FORMAT_MEDIUM);
      var endString =
        "Until " +
        Lang.format("$1$-$2$-$3$ $4$:$5$", [end.day, end.month, end.year, end.hour.format("%02d"), end.min.format("%02d")]);
      dc.drawText(x, y, Graphics.FONT_SMALL, endString, Graphics.TEXT_JUSTIFY_LEFT);

      y = y + lineHeight;

      if (alert.description.length() > 0) {
        var desc = alert.description;

        var textWidth = dc.getTextWidthInPixels(desc, Graphics.FONT_SMALL);
        // in @@ oncompute, split text in lines with same width as the alert box
        if (textWidth > width - 6) {
          var pieces = (textWidth / (width - 6)).toNumber() + 1;
          var chars = desc.length();
          desc = $.stringReplaceAtInterval(desc, (chars / pieces).toNumber(), "\n");
        }
        y = y + lineHeight;
        dc.drawText(x, y, Graphics.FONT_SMALL, desc, Graphics.TEXT_JUSTIFY_LEFT);
      }
    }
  }
}
