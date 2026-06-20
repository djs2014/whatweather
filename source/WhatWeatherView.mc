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
import Toybox.Application;

class CurrentInfo {
  var nr as Number = 0;
  var info as String = "";
  var postfix as String = "";
}

(:extendedCode)
class WhatWeatherView extends WatchUi.DataField {
  hidden var mAlertHandler as AlertHandler;

  hidden var mCreateColors as Boolean = false;
  hidden var mUseSetFillStroke as Boolean = false;

  hidden var render as RenderWeather = new RenderWeather();

  hidden var mLat as Double = 0d;
  hidden var mLon as Double = 0d;
  hidden var mPreviousTrack as Float = 0.0f;
  hidden var mBearing as Number = 0;

  hidden var mBgWeatherData as Dictionary = ({}) as Dictionary;
  hidden var mGarminWeatherData as Dictionary = ({}) as Dictionary;
  hidden var mGarminCheck as GarminWeatherCheck = new GarminWeatherCheck();
  hidden var mCurrentInfo as CurrentInfo?;

  hidden var mWindPoints as Array<WindPoint> = [];
  hidden var mWeatherAlerts as Array<WeatherForecastAlert> = [];

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
  hidden var mZoomMinuteForecastColumns as Number = 3;
  hidden var mShowDetailsWhenAlert as Boolean = false;
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
  hidden var m0TemperatureLineYpos as Number = -1;
  hidden var mShowWeatherText as Boolean = false;

  hidden var mWeatherConditionLoop as Number = 0;

  // Note, all weather and windpoints must be calculated for mShowDetailsWhenAlert == true
  hidden var mShowHourOnColumn as Boolean = false;
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
  hidden var mDarkBackground as Boolean = false;

  function initialize() {
    DataField.initialize();

    // $.checkFeatures();

    var mCurrentLocation = $.getCurrentLocation();
    mCurrentLocation.setOnLocationChanged(self, :onLocationChanged);

    var bgServiceHandler = $.getBGServiceHandler();
    bgServiceHandler.setCurrentLocation(mCurrentLocation);

    mAlertHandler = $.getAlertHandler();
    onLocationChanged(mCurrentLocation.getCurrentDegrees());
  }

  function onLocationChanged(degrees as Array<Double>) as Void {
    mLat = degrees[0];
    mLon = degrees[1];
  }

  function processIncomingWeatherData() as Void {
    if ($.gIncomingWeatherData == null) {
      return;
    }
    try {
      mBgWeatherData = $.gIncomingWeatherData;
      $.gIncomingWeatherData = null;

      var bgServiceHandler = $.getBGServiceHandler();
      if (mBgWeatherData.hasKey(:observationTime)) {
        var obsTime = mBgWeatherData[:observationTime] as Time.Moment;
        bgServiceHandler.setLastObservationMoment(obsTime);
      }

      mTriggerCheckWeatherAlerts = true;      
    } catch (ex) {
      $.logInfo(ex.getErrorMessage());
      ex.printStackTrace();
      $.gIncomingWeatherData = null;
    }
  }
  function onLayout(dc as Dc) as Void {
    dc.clearClip();

    calculateLayout(dc);
    calculateOWMAlerts(dc);
  }

  function compute(info as Activity.Info) as Void {
    try {
      $.checkMemory();
      processIncomingWeatherData();

      var bgServiceHandler = $.getBGServiceHandler();

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
      bgServiceHandler.onCompute(info);
      if ($.g_bg_delay_seconds <= 0) {
        bgServiceHandler.autoScheduleService();
      } else {
        $.g_bg_delay_seconds = $.g_bg_delay_seconds - 1;
      }

      if (mGarminCheck.changed()) {
        $.logInfo("Garmin weather data changed");
        mGarminWeatherData = getLatestGarminWeatherFlat();
        mGarminWeatherData[:changed] = true;
        mGarminCheck.update();
      }

      mGarminWeatherData = $.purgePastWeatherdataFlat(mGarminWeatherData);
      mBgWeatherData = $.purgePastWeatherdataFlat(mBgWeatherData);
      if (DEBUG_DETAILS) {
       $.logInfo(mBgWeatherData);
      }
      
      if (
        mTriggerCheckWeatherAlerts ||
        mBgWeatherData[:changed] ||
        mGarminWeatherData[:changed]
      ) {        
        mTriggerCheckWeatherAlerts = false;
        mBgWeatherData[:changed] = false;
        mGarminWeatherData[:changed] = false;

        mAlertHandler.checkStatus();
        checkForWeatherAlerts();
        if (mAlertHandler.isAnyAlertTriggered()) {
          mFlashScreen = true;
          playAlert();
          mAlertHandler.currentlyTriggeredHandled();
        }
      } else {
        // Only check for zoom when minutely forecast is enabled, and we have minutely data
        processCheckZoomMinuteForecast();
      }
    } catch (ex) {
      $.logInfo("Error compute: " + ex.getErrorMessage());
      ex.printStackTrace();
    }    
  }

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
      $.logInfo("Error on update: " + ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  hidden function calculateLayout(dc as Dc) as Void {
    var windIconHeight = 30;
    var weatherIconHeight = 20;

    mShowComfortBorders = true;
    mShowObservationLocationName = true;
    mShowObservationTime = true;
    mShowRainTotalSize = 3;
    mCurrentEdgeField = $.getEdgeField(dc);

    var arrShowField = [] as Array<Numeric>;
    if (mCurrentEdgeField == EfOne) {
      arrShowField = $.getStorageValue("show_one_field", []) as Array<Numeric or Boolean>;
      mShowRainTotalSize = 3;
    } else if (mCurrentEdgeField == EfLarge) {
      arrShowField =
        $.getStorageValue("show_large_field", []) as Array<Numeric or Boolean>;
      mShowRainTotalSize = 2;
      mShowObservationLocationName = false;
    } else if (mCurrentEdgeField == EfWide) {
      arrShowField = $.getStorageValue("show_wide_field", []) as Array<Numeric or Boolean>;
      mShowRainTotalSize = 2;
      mShowComfortBorders = false;
      mShowObservationLocationName = false;
      mShowObservationTime = false;
    } else if (mCurrentEdgeField == EfSmall) {
      arrShowField =
        $.getStorageValue("show_small_field", []) as Array<Numeric or Boolean>;
      mShowRainTotalSize = 1;
      mShowComfortBorders = false;
      mShowObservationLocationName = false;
      mShowObservationTime = false;
      windIconHeight = 10;
    }

    $.ensureArraySize(arrShowField, $.gSizeArrFieldItems, 0);

    mHoursForecast = arrShowField[0];
    mShowMinuteForecast = arrShowField[1] == true;
    mZoomMinuteForecast = arrShowField[2] == true;
    mZoomMinuteForecastWhenMM = arrShowField[3];
    mZoomMinuteForecastFactor = arrShowField[4];
    mZoomMinuteForecastColumns = arrShowField[5];
    mShowDetailsWhenAlert = arrShowField[6] == true;
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
    var show0TemperatureLine = arrShowField[19] == true;
    mShowWeatherText = arrShowField[20] == true;

    mShowRelativeWind = mShowExtraInfo == SHOW_INFO_RELATIVE_WIND;

    mShowHourOnColumn = true; // TEST TODO @@@

    // Height wind icons
    var heightWind = mShowWind ? windIconHeight : 0;
    // Height weather icons / text
    var heightWc = mShowWeatherCondition ? weatherIconHeight : 0;
    // 2 lines of weather text
    var heightWt = mShowWeatherText
      ? dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY)
      : 0;
    mDs.calculate(dc, mHoursForecast, heightWind, heightWc, heightWt);

    render.initValues(dc, mDs, mCurrentEdgeField);

    // Calculate 0 temperature line position
    if (
      show0TemperatureLine &&
      $._minTemperature < 0 &&
      $._maxTemperature > 0
    ) {
      var perc = $.percentageOf(
        0,
        $._minTemperature,
        $._maxTemperature
      ).toNumber();
      m0TemperatureLineYpos = mDs.getYpostion(perc);
    } else {
      m0TemperatureLineYpos = -1;
    }
  }

  hidden function showBgInfo(dc as Dc, hasWeatherData as Boolean) as Void {
    if ($._weatherDataSource == wsGarminOnly) {
      return;
    }

    var bgServiceHandler = $.getBGServiceHandler();
    if (!bgServiceHandler.isEnabled()) {
      return;
    }

    var color = mDs.COLOR_TEXT;
    var text;
    var status;
    if (bgServiceHandler.hasError()) {
      status = bgServiceHandler.getError();
    } else {
      status = bgServiceHandler.getStatus();
    }
    if (!hasWeatherData) {
      // Counting down to next weather request
      text =
        bgServiceHandler.getErrorMessage() +
        " " +
        status +
        "(" +
        bgServiceHandler.getWhenNextRequest("") +
        ")";
      dc.setColor(color, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        (dc.getWidth() / 2).toNumber(),
        (dc.getHeight() / 2).toNumber(),
        Graphics.FONT_SYSTEM_SMALL,
        text,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }

    var delayed = bgServiceHandler.isDataDelayed();
    var delayedIndication = "";
    if (!mShowObservationTime) {
      if (delayed) {
        color = Graphics.COLOR_RED;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        delayedIndication = "!";
        var textWHsmall = dc.getTextDimensions(
          delayedIndication,
          Graphics.FONT_XTINY
        );
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

    var counter = "#" + bgServiceHandler.getCounterStats();
    var next = bgServiceHandler.getWhenNextRequest("");
    if ($.g_bg_delay_seconds > 0) {
      next = $.g_bg_delay_seconds.format("%d");
    }
    text =
      bgServiceHandler.getErrorMessage() +
      " " +
      delayedIndication +
      counter +
      " " +
      status +
      "(" +
      next +
      ")";

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
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
    if (ci.nr == SHOW_INFO_RELATIVE_WIND) {
      // Done somewhere else
      return;
    }

    var info = ci.info;
    var postfix = ci.postfix;

    var wi = dc.getTextWidthInPixels(info, mFontInfo);
    var wp = dc.getTextWidthInPixels(postfix, mFontPostfix);
    var xi = (mDs.width / 2 - (wi + wp) / 2).toNumber();

    dc.setColor(mDs.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      xi,
      (mDs.height / 2).toNumber(),
      mFontInfo,
      info,
      Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
    );
    dc.drawText(
      xi + wi + 1,
      (mDs.height / 2).toNumber(),
      mFontPostfix,
      postfix,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  var hrDtArray as Array<Time.Moment> = [] as Array<Time.Moment>;
  var hrHourArray as Array<Lang.Number> = [] as Array<Lang.Number>;
  var hrCloudsArray as Array<Lang.Number> = [] as Array<Lang.Number>;
  var hrPrecipitationChanceArray as Array<Lang.Number> =
    [] as Array<Lang.Number>;
  var hrConditionArray as Array<Lang.Number> = [] as Array<Lang.Number>;
  var hrUviArray as Array<Lang.Float> = [] as Array<Lang.Float>;
  var hrWindSpeedArray as Array<Lang.Float> = [] as Array<Lang.Float>;
  var hrWindBearingArray as Array<Lang.Number> = [] as Array<Lang.Number>;
  var hrTemperatureArray as Array<Lang.Numeric> = [] as Array<Lang.Numeric>;
  var hrPressureArray as Array<Lang.Number> = [] as Array<Lang.Number>;
  var hrRelativeHumidityArray as Array<Lang.Number> = [] as Array<Lang.Number>;
  var hrDewPointArray as Array<Lang.Float> = [] as Array<Lang.Float>;
  var hrRain1hrArray as Array<Lang.Float> = [] as Array<Lang.Float>;
  // var hrSnow1hrArray as Array<Lang.Float> = [] as Array<Lang.Float>;
  var hrWindGustArray as Array<Lang.Float> = [] as Array<Lang.Float>;
  // The other forecast we use
  var hrPrecipitationChanceOtherArray as Array<Lang.Number> =
    [] as Array<Lang.Number>;
  var hrConditionOtherArray as Array<Lang.Number> = [] as Array<Lang.Number>;

  var mWeatherData as Dictionary = ({}) as Dictionary;
  var mWeatherDataOther as Dictionary = ({}) as Dictionary;

  // To prevent stack overflow
  // Set actual and other arrays
  // Returns number of forecast hours available in main source
  hidden function setWeatherArrays() as Number {
    switch ($._weatherDataSource) {
      case wsOWMFirst:
        mWeatherData = mBgWeatherData;
        mWeatherDataOther = mGarminWeatherData;
        break;
      case wsGarminFirst:
        mWeatherData = mGarminWeatherData;
        mWeatherDataOther = mBgWeatherData;
        break;
      case wsOWMOnly:
        mWeatherData = mBgWeatherData;
        break;
      case wsGarminOnly:
        mWeatherData = mGarminWeatherData;
        break;
    }

    var maxForecast = $.getWeatherDataSize(mWeatherData);
    if (
      maxForecast == 0 &&
      ($._weatherDataSource == wsOWMFirst ||
        $._weatherDataSource == wsGarminFirst)
    ) {
      // Try other source if main source has no data, except when Source only is selected
      mWeatherData = mWeatherDataOther;
      mWeatherDataOther = ({}) as Dictionary;
      maxForecast = $.getWeatherDataSize(mWeatherData);
    }

    if (maxForecast == 0) {
      $.logInfo("No weather data to show");
      // Reset the other
      hrPrecipitationChanceOtherArray = [] as Array<Lang.Number>;
      hrConditionOtherArray = [] as Array<Lang.Number>;
      return 0;
    }

    hrDtArray = mWeatherData[:hr_dt] as Array<Time.Moment>;
    hrHourArray = mWeatherData[:hr_hour] as Array<Lang.Number>;
    hrCloudsArray = mWeatherData[:hr_clouds] as Array<Lang.Number>;
    hrPrecipitationChanceArray =
      mWeatherData[:hr_precipitationChance] as Array<Lang.Number>;
    hrConditionArray = mWeatherData[:hr_condition] as Array<Lang.Number>;
    hrUviArray = mWeatherData[:hr_uvi] as Array<Lang.Float>;
    hrWindSpeedArray = mWeatherData[:hr_windSpeed] as Array<Lang.Float>;
    hrWindBearingArray = mWeatherData[:hr_windBearing] as Array<Lang.Number>;
    hrTemperatureArray = mWeatherData[:hr_temperature] as Array<Lang.Numeric>;
    hrPressureArray = mWeatherData[:hr_pressure] as Array<Lang.Number>;
    hrRelativeHumidityArray =
      mWeatherData[:hr_relativeHumidity] as Array<Lang.Number>;
    hrDewPointArray = mWeatherData[:hr_dewPoint] as Array<Lang.Float>;
    hrRain1hrArray = mWeatherData[:hr_rain1hr] as Array<Lang.Float>;
    // hrSnow1hrArray = mWeatherData[:hr_snow1hr] as Array<Lang.Float>;
    hrWindGustArray = mWeatherData[:hr_windGust] as Array<Lang.Float>;

    // The other forecast we use
    hrPrecipitationChanceOtherArray =
      mWeatherDataOther[:hr_precipitationChance] as Array<Lang.Number>;
    hrConditionOtherArray =
      mWeatherDataOther[:hr_condition] as Array<Lang.Number>;

    return maxForecast;
  }

  // Returns true when valid weather data
  function onUpdateWeather(dc as Dc) as Boolean {
    var x = mDs.columnX;
    var y = mDs.columnY;
    var previousCondition = -1;
    var weatherTextLine = 0;
    var sunsetPassed = false;
    var skipFirstForecast = false;
    var maxHoursForecast = mHoursForecast;

    // Decide which weather data to use
    // Initialize the weather arrays.
    var maxForecast = setWeatherArrays();
    if (maxForecast == 0) {
      return false;
    }
    
    var maxHoursForecastOther = $.getWeatherDataSize(mWeatherDataOther);

    try {
      if ($._loopWeatherCondition) {
        // Loop through all conditions, for testing (0-53 conditions in Garmin API)
        mWeatherConditionLoop = ((mWeatherConditionLoop + 1) % 54).toNumber();
      }

      var mCurrentLocation = $.getCurrentLocation();

      if (
        mShowMinuteForecast &&
        mWeatherData.hasKey(:minutely_pops) &&
        mWeatherData.hasKey(:minutely_max)
      ) {
        var maxIdx = 0;
        var mm_pops = mWeatherData[:minutely_pops] as Array<Numeric>;
        var mm_max = mWeatherData[:minutely_max] as Float;
        maxIdx = mm_pops.size();
        var show5minMarker = false;
        var popTotal = 0.0f;
        if (maxIdx > 0 && mm_max > 0.049) {
          var mmMinutesDelayed = $.getMinutesDelayed(
            mWeatherData[:minutely_dt]
          );
          var xMMstart = x;
          var columnWidth = 1;
          var max_mmPerHour = $._maxMMRainPerHour;
          if (mActiveZoomMinuteForecast) {
            columnWidth = 3; // @@TODO calculate width based on nrOfColumns / width of screen            
            maxHoursForecast = mZoomMinuteForecastColumns + 1; // We skip the first forecast.
            show5minMarker = true;
            if (mZoomMinuteForecastFactor == 0) {
              mZoomMinuteForecastFactor = 3;
            }
            // Zoom in, or else small amounts not visible.
            max_mmPerHour = (
              max_mmPerHour / mZoomMinuteForecastFactor
            ).toNumber();
            skipFirstForecast = true;
            // System.println(["Zoom maxHoursForecast", maxHoursForecast]);
          }
          var offset = (maxIdx * columnWidth + mDs.space).toNumber();
          var rainInXminutes = -1;
          var rainLastEntry = 0;
          mDs.calculateColumns(offset, maxHoursForecast);
          for (var i = mmMinutesDelayed; i < maxIdx && i < 60; i += 1) {
            var pop = mm_pops[i];
            popTotal = popTotal + pop; // / 60.0; // popTotal is mm/hour, pop is for 1 minute
            if (DEBUG_DETAILS) {
              $.logInfo(
                Lang.format("minutely x[$1$] pop[$2$] i[$3$]", [x, pop, i])
              );
            }
            if (pop > 0 && rainInXminutes < 0) {
              // First rain happens in i minutes
              rainInXminutes = i - mmMinutesDelayed - 1;
            }

            drawColumnPrecipitationMillimeters(
              dc,
              mDs.COLOR_MM_RAIN,
              x,
              y,
              columnWidth,
              mDs.columnHeight,
              pop,
              max_mmPerHour
            );

            if (
              show5minMarker &&
              ((i + mmMinutesDelayed) % 5).toNumber() == 0
            ) {
              //Draw 5 min marker
              drawColumnPrecipitationMillimetersDivider(
                dc,
                mDs.COLOR_MM_DIVIDER,
                x,
                y,
                columnWidth,
                mDs.columnHeight,
                5
              );
            }
            x = x + columnWidth;
            rainLastEntry = rainLastEntry + 1;
          }
          if (rainLastEntry > 0 && rainLastEntry < 59) {
            // System.println("rainLastEntry: " + rainLastEntry);
            drawColumnPrecipitationMillimetersDivider(
              dc,
              mDs.COLOR_MM_DIVIDER,
              x,
              y,
              columnWidth,
              mDs.columnHeight,
              5
            );
          }

          if (popTotal > 0.0f) {
            mHasMinuteRains = true;
            dc.setColor(mDs.COLOR_MM_DETAILS, Graphics.COLOR_TRANSPARENT);
            // // popTotal is mm/hour, pop is for 1 minute
            var rainTextTotal = (popTotal / 60.0f).format("%.2f") + " mm";
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
                mDs.columnY +
                  mDs.columnHeight -
                  2 * dc.getFontHeight(Graphics.FONT_TINY),
                Graphics.FONT_TINY,
                rainTextTotal,
                Graphics.TEXT_JUSTIFY_LEFT
              );
              dc.drawText(
                xMMstart,
                mDs.columnY +
                  mDs.columnHeight -
                  1 * dc.getFontHeight(Graphics.FONT_TINY),
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
                mDs.columnY +
                  mDs.columnHeight +
                  dc.getFontHeight(Graphics.FONT_XTINY),
                Graphics.FONT_TINY,
                rainTextTime,
                Graphics.TEXT_JUSTIFY_LEFT
              );
            }
            x = x + mDs.space;
            if (mDs.dashesUnderColumnHeight > 0) {
              dc.setColor(mDs.COLOR_TEXT_DASHES, Graphics.COLOR_TRANSPARENT);
              dc.fillRectangle(
                xMMstart,
                mDs.columnY + mDs.columnHeight,
                maxIdx * columnWidth,
                mDs.dashesUnderColumnHeight
              );
            }
            x = xMMstart + offset;
          }
        }
        if (popTotal == 0.0f && mHasMinuteRains) {
          // No mm rain anymore, recalculate layout
          mCalculateLayout = true;
          mHasMinuteRains = false;
          mActiveZoomMinuteForecast = false;
        }

        // minutely forecast end
      }

      // Use the hourly forecast arrays

      for (
        var fcIdx = 0;
        fcIdx < maxHoursForecast && fcIdx < maxForecast;
        fcIdx += 1
      ) {
        // TODO check this
        if (skipFirstForecast && fcIdx == 0) {
          $.logInfo("Skip first forecast due to rain 1stmm zoom");
          continue;
        }
        // TODO log info
        // if (DEBUG_DETAILS) {
        //   $.logInfo(forecast.info());
        // }
        var hasOtherForecast =
          fcIdx < maxHoursForecastOther && fcIdx < maxForecast;

        var wa;
        if (mShowDetailsWhenAlert && fcIdx < mWeatherAlerts.size()) {
          wa = mWeatherAlerts[fcIdx];
        } else {
          wa = new WeatherForecastAlert();
        }

        var colorCondition = getConditionColor(
          hrConditionArray[fcIdx],
          Graphics.COLOR_BLUE,
          mDarkBackground
        );
        var colorOtherCondition = colorCondition;
        if (hasOtherForecast) {
          colorOtherCondition = getConditionColor(
            hrConditionOtherArray[fcIdx],
            Graphics.COLOR_BLUE,
            mDarkBackground
          );
        }
        var cloudColor = mDs.COLOR_CLOUDS;
        var cloudHeight = 0;
        if (mShowClouds) {
          cloudHeight = drawColumnChance(
            dc,
            cloudColor,
            x,
            mDs.columnY,
            mDs.columnWidth,
            mDs.columnHeight,
            hrCloudsArray[fcIdx]
          );
        }
        if (mShowComfortZone) {
          var hour = -1;
          if (mShowHourOnColumn && mShowDetails) {
            hour = hrHourArray[fcIdx];
          }
          render.drawComfortColumn(
            dc,
            x,
            hrDewPointArray[fcIdx],
            mDarkBackground,
            hour
          );
        }
        // rain chance and rain mm is always shown, the base of the weather columns.
        var rainHeight = drawColumnChance(
          dc,
          colorCondition,
          x,
          mDs.columnY,
          mDs.columnWidth,
          mDs.columnHeight,
          hrPrecipitationChanceArray[fcIdx]
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
            (mDs.columnWidth / 3).toNumber(),
            hrCloudsArray[fcIdx]
          );
        }
        if (hasOtherForecast && colorCondition != colorOtherCondition) {
          // rain other
          drawLineChance(
            dc,
            cloudColor,
            colorOtherCondition,
            x,
            mDs.columnY,
            mDs.columnWidth,
            mDs.columnHeight,
            (mDs.columnWidth / 4).toNumber(),
            hrPrecipitationChanceOtherArray[fcIdx]
          );
        }
        // mm per hour
        if (hrRain1hrArray[fcIdx] > 0.0f) {
          drawColumnPrecipitationMillimeters(
            dc,
            mDs.COLOR_MM_RAIN,
            x,
            mDs.columnY,
            mDs.columnWidth,
            mDs.columnHeight,
            hrRain1hrArray[fcIdx], // TODO float
            $._maxMMRainPerHour
          );
        }

        var bluebarPerc = hrPrecipitationChanceArray[fcIdx];
        var xCenterColumn = x + (mDs.columnWidth / 2).toNumber();

        if (mShowUv || wa.alertUvi) {
          render.drawUvIndexItem(
            dc,
            xCenterColumn,
            hrUviArray[fcIdx],
            $._maxUVIndex,
            mShowDetails,
            bluebarPerc
          );
        }
        if (mShowPressure) {
          render.drawPressureItem(
            dc,
            xCenterColumn,
            hrPressureArray[fcIdx],
            mShowDetails,
            bluebarPerc
          );
        }

        if (mShowRelativeHumidity) {
          render.drawHumidityItem(
            dc,
            xCenterColumn,
            hrRelativeHumidityArray[fcIdx],
            mShowDetails,
            bluebarPerc
          );
        }

        if (m0TemperatureLineYpos > -1) {
          render.draw0TemperatureLine(dc, xCenterColumn, m0TemperatureLineYpos);
        }

        if (mShowTemperature) {
          render.drawTemperatureItem(
            dc,
            xCenterColumn,
            hrTemperatureArray[fcIdx],
            mShowDetails,
            bluebarPerc
          );
        }

        if (mShowDewpoint || wa.alertDewpoint) {
          render.drawDewpointItem(
            dc,
            xCenterColumn,
            hrDewPointArray[fcIdx],
            mShowDetails,
            bluebarPerc,
            mDarkBackground
          );
        }

        if (mDs.dashesUnderColumnHeight > 0 || hrRain1hrArray[fcIdx] > 0.0f) {
          // TODO Only for small field?
          var dh = mDs.dashesUnderColumnHeight;
          var colorDashes = Graphics.COLOR_DK_GRAY;
          if (hrRain1hrArray[fcIdx] > 0.0f) {
            colorDashes = mDs.COLOR_MM_RAIN;
            if (dh == 0) {
              dh = 1;
            }
          } else if (hrPrecipitationChanceArray[fcIdx] == 0) {
            colorDashes = getConditionColor(
              hrConditionArray[fcIdx],
              Graphics.COLOR_DK_GRAY,
              mDarkBackground
            );
          }
          dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
          dc.fillRectangle(
            x,
            mDs.columnY + mDs.columnHeight,
            mDs.columnWidth,
            dh
          );
          if (
            hasOtherForecast &&
            colorCondition != colorOtherCondition &&
            hrPrecipitationChanceOtherArray[fcIdx] == 0
          ) {
            colorDashes = getConditionColor(
              hrConditionOtherArray[fcIdx],
              Graphics.COLOR_DK_GRAY,
              mDarkBackground
            );
            dc.setColor(colorDashes, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(
              x + (mDs.columnWidth / 3).toNumber() * 2,
              mDs.columnY + mDs.columnHeight + 1,
              (mDs.columnWidth / 3).toNumber(),
              dh
            );
          }
        }

        if (mShowDetails) {
          // Show rain mm
          var infoStr = "";
          if (hrRain1hrArray[fcIdx] > 0.0f) {
            infoStr = hrRain1hrArray[fcIdx].format("%.1f");
            dc.setColor(mDs.COLOR_TEXT_DETAILS, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
              x + (mDs.columnWidth / 2).toNumber(),
              mDs.columnY + mDs.columnHeight - 30,
              Graphics.FONT_XTINY,
              infoStr,
              Graphics.TEXT_JUSTIFY_CENTER
            );
          }
        }

        // Weather condition icon and text
        var condition = hrConditionArray[fcIdx];
        if ($._loopWeatherCondition) {
          condition = mWeatherConditionLoop;
        }

        if (mShowWeatherCondition || wa.alertWeatherCondition) {
          var nightTime = mCurrentLocation.isAtNightTime(
            hrDtArray[fcIdx],
            false
          );
          render.drawWeatherCondition(
            dc,
            x,
            condition,
            nightTime,
            mDarkBackground
          );
          if (nightTime && !sunsetPassed) {
            render.drawSunsetIndication(dc, x);
            sunsetPassed = true;
          }
        }
        if (mShowWeatherText && previousCondition != condition) {
          var line = weatherTextLine % 2 == 0 ? 0 : 1;
          weatherTextLine++;
          // When changing condition, show text on other line, to avoid flickering
          render.drawWeatherConditionText(dc, x, condition, line);
          previousCondition = condition;
        }

        if (mShowWind || wa.alertWind) {
          if (fcIdx < mWindPoints.size()) {            
            mWindPoints[fcIdx].setXposition(x);
            var wp = mWindPoints[fcIdx] as WindPoint;
            var xW = wp.x + (mDs.columnWidth / 2).toNumber();
            var yW =
              mDs.columnY + mDs.columnHeight + (mDs.heightWind / 2).toNumber();
            render.drawWindArrow(dc, xW, yW, wp, 0, false);
          }
        }

        x = x + mDs.columnWidth + mDs.space;
      } // hourlyForecast for loop

      // TODO dashed line ??
      if (mShowComfortBorders) {
        render.drawComfortBorders(dc);
      }

      // Always show position of observation
      var distance = "";
      var distanceMetric = "km";
      var distanceInKm = 0;
      if (DEBUG_DETAILS) {
        $.logInfo(["current location: ", mCurrentLocation.infoLocation()]);
      }
      if (mCurrentLocation.hasLocation()) {
        distanceInKm = $.getDistanceFromLatLonInKm(
          mLat,
          mLon,
          mWeatherData[:lat],
          mWeatherData[:lon]
        );
        distance = distanceInKm.format("%.2f");
        var deviceSettings = System.getDeviceSettings();
        if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
          distanceMetric = "mi";
          distance = $.kilometerToMile(distanceInKm).format("%.2f");
        }
        var bearing = $.getRhumbLineBearing(
          mLat,
          mLon,
          mWeatherData[:lat],
          mWeatherData[:lon]
        );
        var compassDirection = $.getCompassDirection(bearing);
        render.drawObservationLocation(
          dc,
          Lang.format("$1$ $2$ ($3$)", [
            distance,
            distanceMetric,
            compassDirection,
          ])
        );
      }
      var showLocationName = mShowObservationLocationName;
      if (
        mTimerState == Activity.TIMER_STATE_PAUSED &&
        mAlertHandler.hasAlertsHandled()
      ) {
        showLocationName = false;
      }
      if (showLocationName) {
        render.drawObservationLocationLine2(
          dc,
          mWeatherData[:observationLocationName]
        );
      }
      render.drawObservationTime(dc, mWeatherData[:observationTime]);
      // End observation location and time

      // mShowDetailsWhenAlert only for wind TODO others

      if (mShowRelativeWind || mShowDetailsWhenAlert) {
        var activityBearing = mBearing;
        if (mActivityPaused) {
          activityBearing = 0;
        }
        if (mWindPoints.size() > 0) {
          var wp1 = mWindPoints[0] as WindPoint;
          // var show = mShowRelativeWind || wp1.hasAlert();
          // In center of screen. Show big arrow when moving or has alert
          var bigArrow = activityBearing != 0 || wp1.hasAlert();
          render.drawWindArrow(
            dc,
            (mDs.width / 2).toNumber(),
            mDs.columnY + (mDs.columnHeight / 2).toNumber(),
            wp1,
            activityBearing,
            bigArrow
          );
        }
      }

      if (mCurrentEdgeField == EfWide) {
        render.drawAlertMessages(dc, mAlertHandler.infoHandled(), false);
      } else if (mCurrentEdgeField == EfSmall) {
        render.drawAlertMessagesVert(dc, mAlertHandler.infoHandledShort());
      } else {
        render.drawAlertMessages(
          dc,
          mAlertHandler.infoHandled(),
          mActivityPaused
        );
      }
      return true;
    } catch (ex) {
      $.logInfo("Error showing weather: " + ex.getErrorMessage());
      ex.printStackTrace();
    }
    return false;
  }

  function drawPrecipitationChanceAxis(
    dc as Dc,
    margin as Number,
    bar_height as Number
  ) as Void {
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
    var barFilledHeight =
      bar_height -
      (
        bar_height -
        (bar_height.toFloat() / 100.0) * precipitationChance
      ).toNumber();
    var barFilledY = y + bar_height - barFilledHeight;
    dc.fillRectangle(x, barFilledY, bar_width, barFilledHeight);

    //
    if (mShowDetails && precipitationChance > 50 && precipitationChance < 100) {
      dc.setColor(mDs.COLOR_TEXT_DETAILS, Graphics.COLOR_TRANSPARENT);
      var h = dc.getFontHeight(Graphics.FONT_SMALL);
      dc.drawText(
        x + (bar_width / 2).toNumber(),
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
    var barFilledHeight =
      bar_height -
      (
        bar_height -
        (bar_height.toFloat() / 100.0) * precipitationChance
      ).toNumber();
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
        $.logInfo("Attention.backlight(true) failed");
        ex.printStackTrace();
      }
    }

    if (
      $._soundMode == 0 ||
      !(Attention has :playTone) ||
      !System.getDeviceSettings().tonesOn
    ) {
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
        Attention.playTone(Attention.TONE_LOUD_BEEP);
        return;
      }

      var toneProfile =
        [
          new Attention.ToneProfile(800, 40),
          new Attention.ToneProfile(1200, 150),
          new Attention.ToneProfile(3000, 0),
        ] as Lang.Array<Attention.ToneProfile>;
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
      return (
        info.timerState == Activity.TIMER_STATE_PAUSED ||
        info.timerState == Activity.TIMER_STATE_OFF
      );
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
          nowHour = ((nowHour + 11).toNumber() % 12).toNumber() + 1;
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
        var distanceInKm =
          (getActivityValue(a_info, :elapsedDistance, 0.0f) as Float) / 1000.0;
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

    // System.println("Info: " + mShowExtraInfo + "|" + info + " " + postfix);
    var ci = new CurrentInfo();
    ci.nr = mShowExtraInfo;
    ci.info = info;
    ci.postfix = postfix;
    return ci;
  }

function processCheckZoomMinuteForecast() as Void {
    mActiveZoomMinuteForecast = false;

    try {
      // Decide which weather data to use
      var maxForecast = setWeatherArrays();        
      if (maxForecast == 0) {
        return;
      }
      
      // Only for the zoom factor
      if (
        mShowMinuteForecast &&
        mWeatherData.hasKey(:minutely_pops) &&
        mWeatherData.hasKey(:minutely_max)
      ) {
        var mm_pops = mWeatherData[:minutely_pops] as Array<Numeric>;
        var mm_max = mWeatherData[:minutely_max] as Float;
        $.logInfo("Minutely max pop: " + mm_max);
        $.logInfo("Minutely pops: " + mm_pops);
        var maxIdx = mm_pops.size();
        var mmMinutesDelayed = $.getMinutesDelayed(mWeatherData[:minutely_dt]);
        $.logInfo("Minutely minutes delayed: " + mmMinutesDelayed);
        var popTotal = 0.0f as Lang.Float;
        if (maxIdx > 0 && mm_max > 0.049) {
          for (var i = mmMinutesDelayed; i < maxIdx && i < 60; i += 1) {
            var pop = mm_pops[i];
            popTotal = popTotal + pop;
          }
          popTotal = popTotal / 60.0; // popTotal is mm/hour, pop is for 1 minute
          $.logInfo("Minutely pop total: " + popTotal + " mZoomMinuteForecastWhenMM: " + mZoomMinuteForecastWhenMM);
         // mAlertHandler.processRainMMfirstHour(popTotal);

          mActiveZoomMinuteForecast =
            mZoomMinuteForecast && popTotal >= mZoomMinuteForecastWhenMM;
        }
      } // showMinuteForecast
    } catch (ex) {
      $.logInfo("Error check for weather alerts: " + ex.getErrorMessage());
      ex.printStackTrace();
    }
  }
  // Check for alerts and build windpoints
  function checkForWeatherAlerts() as Void {
    mActiveZoomMinuteForecast = false;

    mAlertHandler.resetAllClear();
    mWindPoints = [];
    mWeatherAlerts = [];

    // Alerts on both sources,  TODO
    // TODO snow ..
    try {
      // Decide which weather data to use
      var maxForecast = setWeatherArrays();    
    
      if (maxForecast == 0) {
        return;
      }
      var maxHoursForecastOther = $.getWeatherDataSize(mWeatherDataOther);
      
      // Always check when for alerts
      if (
        //mShowMinuteForecast &&
        mWeatherData.hasKey(:minutely_pops) &&
        mWeatherData.hasKey(:minutely_max)
      ) {
        var mm_pops = mWeatherData[:minutely_pops] as Array<Numeric>;
        var mm_max = mWeatherData[:minutely_max] as Float;
        $.logInfo("Minutely max pop: " + mm_max);
        $.logInfo("Minutely pops: " + mm_pops);
        var maxIdx = mm_pops.size();
        var mmMinutesDelayed = $.getMinutesDelayed(mWeatherData[:minutely_dt]);
        $.logInfo("Minutely minutes delayed: " + mmMinutesDelayed);
        var popTotal = 0.0f as Lang.Float;
        if (maxIdx > 0 && mm_max > 0.049) {
          for (var i = mmMinutesDelayed; i < maxIdx && i < 60; i += 1) {
            var pop = mm_pops[i];
            popTotal = popTotal + pop;
          }
          popTotal = popTotal / 60.0; // popTotal is mm/hour, pop is for 1 minute
          $.logInfo("Minutely pop total: " + popTotal + " mZoomMinuteForecastWhenMM: " + mZoomMinuteForecastWhenMM);
          mAlertHandler.processRainMMfirstHour(popTotal);

          mActiveZoomMinuteForecast =
            mZoomMinuteForecast && popTotal >= mZoomMinuteForecastWhenMM;
        }
      } // showMinuteForecast

      // We always have valid forecast hours, because past hours are removed.
      // fcIdx < mHoursForecast && 
      // Check all downloaded forecast hours for alerts, and build windpoints for all hours.
      var maxHourly = hrCloudsArray.size();
      for (
        var fcIdx = 0;
        fcIdx < maxHourly;
        fcIdx += 1
      ) {
        var hasOtherForecast =
          fcIdx < maxHoursForecastOther && fcIdx < maxForecast;

        var wa = new WeatherForecastAlert();

        if (
          mAlertHandler.processPrecipitationChance(
            hrPrecipitationChanceArray[fcIdx]
          )
        ) {
          wa.alertPrecipitationChance = true;
        }
        if (hasOtherForecast) {
          if (
            mAlertHandler.processPrecipitationChance(
              hrPrecipitationChanceOtherArray[fcIdx]
            )
          ) {
            wa.alertPrecipitationChance = true;
          }
        }

        if (mAlertHandler.processWeather(hrConditionArray[fcIdx])) {
          wa.alertWeatherCondition = true;
        }
        if (hasOtherForecast) {
          if (mAlertHandler.processWeather(hrConditionOtherArray[fcIdx])) {
            wa.alertWeatherCondition = true;
          }
        }
        if (mAlertHandler.processUvi(hrUviArray[fcIdx])) {
          wa.alertUvi = true;
        }

        var hasAlert = mAlertHandler.processWindSpeed(hrWindSpeedArray[fcIdx]);
        var hasAlert2 = mAlertHandler.processWindGust(
          hrWindSpeedArray[fcIdx],
          hrWindGustArray[fcIdx]
        );
        // Always fill in the wind, testing for (ShowWind || mShowRelativeWind || mShowDetailsWhenAlert)
        // doesnt work, because at startup of app they dont have the correct value.
        // Could be that onlayout event is not called?
        var wPoint = new WindPoint(
          hrWindBearingArray[fcIdx],
          hrWindSpeedArray[fcIdx],
          hasAlert,
          hrWindGustArray[fcIdx],
          hasAlert2
        );
        wPoint.setUIelements(mShowWindUnit);
        mWindPoints.add(wPoint);
        if (hasAlert || hasAlert2) {
          wa.alertWind = true;
        }

        wa.alertDewpoint = mAlertHandler.processDewpoint(
          hrDewPointArray[fcIdx]
        );
        wa.alertRainMMHour = mAlertHandler.processRainMMHour(
          hrRain1hrArray[fcIdx]
        );

        mWeatherAlerts.add(wa);
      }

      var alerts = $.getWeatherDataAlerts(mWeatherData);
      var hasOWMAlert = alerts.size() > 0;
      mAlertHandler.processOWMAlert(hasOWMAlert);
    } catch (ex) {
      $.logInfo("Error check for weather alerts: " + ex.getErrorMessage());
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

    var alerts = $.getWeatherDataAlerts(mBgWeatherData);
    for (var i = 0; i < alerts.size(); i++) {
      var alert = alerts[i] as WeatherAlert;
      alert.handled = false;
    }
  }

  function calculateOWMAlerts(dc as Dc) as Void {
    var maxForecast = $.getWeatherDataSize(mBgWeatherData);
    if (maxForecast == 0) {
      return;
    }

    var alerts = $.getWeatherDataAlerts(mBgWeatherData);
    if (alerts.size() == 0) {
      mAlertIndex = -1;
      return;
    }

    if (mAlertIndex > -1 && !mGetNextAlert) {
      return;
    }

    mGetNextAlert = false;
    for (var i = 0; i < alerts.size(); i++) {
      var alert = alerts[i] as WeatherAlert;
      if (!alert.handled) {
        mAlertIndex = i;
        mAlertFont = $.getMatchingFont(
          dc,
          mDs.alertFonts,
          dc.getWidth() - 2,
          alert.event,
          -1
        );
        return;
      }
    }

    mAlertIndex = -1;
  }

  function handleOWMAlerts(dc as Dc) as Void {
    var alerts = $.getWeatherDataAlerts(mBgWeatherData);

    if (
      alerts.size() == 0 ||
      mAlertIndex <= -1 ||
      mAlertIndex >= alerts.size()
    ) {
      // Reset
      mAlertDisplayedOnOneField = 0;
      mAlertDisplayedOnOtherField = 0;
      mAlertCounter = 30;
      mAlertIndex = -1;
      return;
    }

    var alert = alerts[mAlertIndex] as WeatherAlert;

    if (alert.handled || alert.start == null || alert.end == null) {
      alert.handled = true;
      mAlertDisplayedOnOneField = 0;
      mAlertDisplayedOnOtherField = 0;
      mAlertCounter = 30;
      mGetNextAlert = true;
      return;
    }

    var key =
      alert.event +
      (alert.start as Moment).value().format("%d") +
      (alert.end as Moment).value().format("%d");

    if (mAlertDisplayed.indexOf(key) > -1) {
      return;
    }
    mAlertCounter = mAlertCounter - 1;
    // System.println("Counter: " + mAlertCounter);
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
      } else if (
        mAlertDisplayedOnOtherField == 1 &&
        mAlertDisplayedOnOneField > 1
      ) {
        mAlertDisplayed.add(key);
        alert.handled = true;
        mGetNextAlert = true;
      }

      var x = 1;
      var width = dc.getWidth() - 2;
      var height = (dc.getHeight() / 3).toNumber();
      var y = height;
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
      dc.fillRectangle(x, y, width, height);

      var text = alert.event;
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        (dc.getWidth() / 2).toNumber(),
        (dc.getHeight() / 2).toNumber(),
        mAlertFont,
        text,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    } else {
      // one - small - one - small -> exit alert
      if (mAlertDisplayedOnOneField == 0) {
        mAlertDisplayedOnOneField = 1;
      } else if (
        mAlertDisplayedOnOneField == 1 &&
        mAlertDisplayedOnOtherField > 0
      ) {
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
      dc.drawText(
        (dc.getWidth() / 2).toNumber(),
        y,
        mAlertFont,
        alert.event,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );

      y = y + lineHeight;
      var counterText = mAlertCounter.format("%d");
      if (alerts.size() > 1) {
        counterText =
          counterText +
          " " +
          (mAlertIndex + 1).format("%d") +
          "/" +
          alerts.size().format("%d");
      }
      dc.drawText(
        (dc.getWidth() / 2).toNumber(),
        y,
        Graphics.FONT_TINY,
        counterText,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
      y = y + lineHeight;

      lineHeight = dc.getFontHeight(Graphics.FONT_SMALL);
      var start = Time.Gregorian.info(
        alert.start as Time.Moment,
        Time.FORMAT_MEDIUM
      );
      var startString =
        "From " +
        Lang.format("$1$-$2$-$3$ $4$:$5$", [
          start.day,
          start.month,
          start.year,
          start.hour.format("%02d"),
          start.min.format("%02d"),
        ]);
      dc.drawText(
        x,
        y,
        Graphics.FONT_SMALL,
        startString,
        Graphics.TEXT_JUSTIFY_LEFT
      );
      y = y + lineHeight;

      var end = Time.Gregorian.info(
        alert.end as Time.Moment,
        Time.FORMAT_MEDIUM
      );
      var endString =
        "Until " +
        Lang.format("$1$-$2$-$3$ $4$:$5$", [
          end.day,
          end.month,
          end.year,
          end.hour.format("%02d"),
          end.min.format("%02d"),
        ]);
      dc.drawText(
        x,
        y,
        Graphics.FONT_SMALL,
        endString,
        Graphics.TEXT_JUSTIFY_LEFT
      );

      y = y + lineHeight;

      if (alert.description.length() > 0) {
        var desc = alert.description;

        var textWidth = dc.getTextWidthInPixels(desc, Graphics.FONT_SMALL);
        // in @@ oncompute, split text in lines with same width as the alert box
        if (textWidth > width - 6) {
          var pieces = (textWidth / (width - 6)).toNumber() + 1;
          var chars = desc.length();
          desc = $.stringReplaceAtInterval(
            desc,
            (chars / pieces).toNumber(),
            "\n"
          );
        }
        y = y + lineHeight;
        dc.drawText(
          x,
          y,
          Graphics.FONT_SMALL,
          desc,
          Graphics.TEXT_JUSTIFY_LEFT
        );
      }
    }
  }
}

(:extendedCode)
var gIncomingWeatherData as Dictionary? = null;
