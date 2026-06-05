import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Application.Storage;
import Toybox.Position;

// TODO var gDebug as Boolean = false;

(:typecheck(disableBackgroundCheck))
var gSettingsChanged as Boolean = false;

// (:typecheck(disableBackgroundCheck))
// var _weatherDescriptions as Lang.Array = []; // Lang.Dictionary = {};

(:background)
class WhatWeatherApp extends Application.AppBase {
  function initialize() {
    AppBase.initialize();
  }

  function onStart(state as Dictionary?) as Void {
    System.println("on Start");
  }

  function onStop(state as Dictionary?) as Void {
    System.println("on Stop");
  }

  (:typecheck(disableBackgroundCheck))
  function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
    // $._weatherDescriptions = Application.loadResource(Rez.JsonData.weatherDescriptions) as Array;
    loadUserSettings();
    return [new WhatWeatherView()];
  }

  (:typecheck(disableBackgroundCheck))
  function getSettingsView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null {
    return [new $.DataFieldSettingsView(), new $.DataFieldSettingsDelegate()];
  }

  (:typecheck(disableBackgroundCheck))
  function onSettingsChanged() as Void {
    loadUserSettings();
  }

  (:typecheck(disableBackgroundCheck))
  function loadUserSettings() as Void {
    try {
      System.println("Loading user settings");

      var hadConversionToArrays = Storage.getValue("show_one_field");
      if (hadConversionToArrays == null) {
        removeObsolete();
        resetDisplayFields();
      }

      var reset = Storage.getValue("resetDefaults");
      if (reset == null || (reset as Boolean)) {
        Storage.setValue("resetDefaults", false);

        resetDisplayFields();

        Storage.setValue("checkIntervalMinutes", 5);

        Storage.setValue("alertLevelPrecipitationChance", 70);
        Storage.setValue("alertLevelUVi", 6);
        Storage.setValue("alertLevelRainMMfirstHour", 0.2f);
        Storage.setValue("alertLevelRainMMHour", 0.2f);
        Storage.setValue("alertWindIn", SHOW_WIND_KILOMETERS);
        Storage.setValue("alertLevelWindSpeed", 30);
        Storage.setValue("alertLevelWindGust", 2);
        Storage.setValue("alertLevelDewpoint", 19);

        Storage.setValue("maxUVIndex", 20);
        Storage.setValue("minTemperature", 0);
        Storage.setValue("maxTemperature", 50);
        Storage.setValue("minPressure", 870);
        Storage.setValue("maxPressure", 1080);
        Storage.setValue("maxMMRainPerHour", 10);
        Storage.setValue("percHideDetails", 5);

        Storage.setValue("comfortHumidityMin", 40);
        Storage.setValue("comfortHumidityMax", 60);
        Storage.setValue("comfortTempMin", 19);
        Storage.setValue("comfortTempMax", 27);

        // Init empty entry - for editing in simulator
        var apikey = Storage.getValue("openWeatherAPIKey");
        if (apikey == null) {
          Storage.setValue("openWeatherAPIKey", "");
        }
      }

      // $.gDebug = $.getStorageValue("debug", $.gDebug) as Boolean;

      $.g_bg_timeout_seconds = $.getStorageValue("g_bg_timeout_seconds", $.g_bg_timeout_seconds) as Number;
      $.g_bg_delay_seconds = $.getStorageValue("g_bg_delay_seconds", $.g_bg_delay_seconds) as Number;
      $._weatherDataSource = $.getStorageValue("weatherDataSource", $._weatherDataSource) as WeatherSource;

      $.gShow_OneField =
        $.getStorageValue("show_one_field", $.gShow_OneField as Array<Application.PropertyValueType>) as Array<Number>;
      $.gShow_LargeField =
        $.getStorageValue("show_large_field", $.gShow_LargeField as Array<Application.PropertyValueType>) as Array<Number>;
      $.gShow_WideField =
        $.getStorageValue("show_wide_field", $.gShow_WideField as Array<Application.PropertyValueType>) as Array<Number>;
      $.gShow_SmallField =
        $.getStorageValue("show_small_field", $.gShow_SmallField as Array<Application.PropertyValueType>) as Array<Number>;

      if ($.ensureArraySize($.gShow_OneField, $.gSizeArrFieldItems, 0)) {
        $.setStorageValueOrArray("show_one_field", $.gShow_OneField);
      }
      if ($.ensureArraySize($.gShow_LargeField, $.gSizeArrFieldItems, 0)) {
        $.setStorageValueOrArray("show_one_field", $.gShow_LargeField);
      }
      if ($.ensureArraySize($.gShow_WideField, $.gSizeArrFieldItems, 0)) {
        $.setStorageValueOrArray("show_one_field", $.gShow_WideField);
      }
      if ($.ensureArraySize($.gShow_SmallField, $.gSizeArrFieldItems, 0)) {
        $.setStorageValueOrArray("show_one_field", $.gShow_SmallField);
      }

      $._alertLevelPrecipitationChance = $.getStorageValue("alertLevelPrecipitationChance", 70) as Number;
      $._alertLevelUVi = $.getStorageValue("alertLevelUVi", 6) as Number;
      $._alertLevelRainMMfirstHour = $.getStorageValue("alertLevelRainMMfirstHour", 0.2f) as Float;
      $._alertLevelRainMMHour = $.getStorageValue("alertLevelRainMMHour", 0.2f) as Float;
      $._alertWindIn = $.getStorageValue("alertWindIn", $._alertWindIn) as Number;
      $._alertLevelWindSpeed = $.getStorageValue("alertLevelWindSpeed", 5.0f) as Float;
      $._alertLevelWindGust = $.getStorageValue("alertLevelWindGust", 2) as Number;
      $._alertLevelDewpoint = $.getStorageValue("alertLevelDewpoint", 19) as Number;

      $._soundMode = $.getStorageValue("sound_mode", 1) as Number;
      $._alertBacklight = $.getStorageValue("alert_backlight", false) as Boolean;


      $._loopWeatherCondition = $.getStorageValue("weather_condition_loop", false) as Boolean;

      $._maxUVIndex = $.getStorageValue("maxUVIndex", 20) as Number;
      $._minTemperature = $.getStorageValue("minTemperature", 0) as Number;
      $._maxTemperature = $.getStorageValue("maxTemperature", 50) as Number;

      $.initDewpointColors($._maxTemperature);

      $._minPressure = $.getStorageValue("minPressure", 870) as Number;
      $._maxPressure = $.getStorageValue("maxPressure", 1080) as Number;
      if ($._minPressure > $._maxPressure) {
        $._minPressure = 870;
        $._maxPressure = 1080;
      }
      $._maxMMRainPerHour = $.getStorageValue("maxMMRainPerHour", 10) as Number;
      // Hide values if below 5% of y-axis
      $._percHideDetails = $.getStorageValue("percHideDetails", 5) as Number;

      var bgHandler = $.getBGServiceHandler();
      bgHandler.setObservationTimeDelayedMinutes($._observationTimeDelayedMinutesThreshold);
      var minimalGPSquality = $.getStorageValue("minimalGPSquality", 1) as Number; // 1 is last known location
      bgHandler.setMinimalGPSLevel(minimalGPSquality);
      var interval = $.getStorageValue("checkIntervalMinutes", 5) as Number;
      if (interval < 5) {
        interval = 5;
        Storage.setValue("checkIntervalMinutes", interval);
      }
      bgHandler.setUpdateFrequencyInMinutes(interval);

      var ws = $.getStorageValue("weatherDataSource", 0) as Number;
      $._weatherDataSource = ws as WeatherSource;

      var apiKey = $.getStorageValue("openWeatherAPIKey", "") as String;
      if (apiKey.length == 0 && $._weatherDataSource == wsOWMFirst) {
        $._weatherDataSource = wsGarminFirst;
      }
      if ($._weatherDataSource == wsOWMFirst || $._weatherDataSource == wsOWMOnly || $._weatherDataSource == wsGarminFirst) {
        bgHandler.Enable();
      } else {
        bgHandler.Disable();
      }

      var alertHandler = $.getAlertHandler();
      alertHandler.setAlertPrecipitationChance($._alertLevelPrecipitationChance);
      alertHandler.setAlertUVi($._alertLevelUVi);
      alertHandler.setAlertRainMMfirstHour($._alertLevelRainMMfirstHour);
      alertHandler.setAlertRainMMHour($._alertLevelRainMMHour);
      alertHandler.setAlertWindIn($._alertWindIn);
      alertHandler.setAlertWindSpeed($._alertLevelWindSpeed);
      alertHandler.setAlertWindGust($._alertLevelWindGust);
      alertHandler.setAlertDewpoint($._alertLevelDewpoint);
      alertHandler.resetStatus();

      initComfortSettings();
      
      Storage.setValue("weatherDataSource", ws);
      setStorageValueIfChanged("openWeatherAPIKey", "");

      // Fix proxy url
      var proxuUrl = $.getApplicationProperty("openWeatherProxy", "") as String;
      if (proxuUrl.equals("https://api.castlephoto.info/owm_one")) {
        Application.Properties.setValue("openWeatherProxy", "https://owm.castlephoto.info/owm_one");
      }

      setStorageValueIfChanged("openWeatherProxy", "https://owm.castlephoto.info/owm_one");
      setStorageValueIfChanged("openWeatherProxyAPIKey", "0548b3c7-61bc-4afc-b6e5-616f19d3cf23");
      Storage.setValue("openWeatherAPIVersion", $.getStorageValue("openWeatherAPIVersion", 1) as Number);
      //Storage.setValue("testScenario", $.getStorageValue("testScenario", 0) as Number);

      var maxHours = $.max($.gShow_OneField[0], $.gShow_LargeField[0]);
      maxHours = $.max($.gShow_WideField[0], maxHours);
      maxHours = $.max($.gShow_SmallField[0], maxHours);

      var showMinutely = $.gShow_OneField[1] || $.gShow_LargeField[1] || $.gShow_WideField[1] || $.gShow_SmallField[1];

      Storage.setValue("openWeatherMaxHours", maxHours + 1);
      Storage.setValue("openWeatherMinutely", showMinutely);

      $.gSettingsChanged = true;
      System.println("User settings loaded");
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  (:typecheck(disableBackgroundCheck))
  function setStorageValueIfChanged(key as String, def as String) as Void {
    try {
      var propertyValue = $.getApplicationProperty(key, "") as String;
      if (propertyValue.length() == 0) {
        propertyValue = def;
        Application.Properties.setValue(key, def);
      }
      if (propertyValue.length() > 0) {
        var storageValue = Storage.getValue(key);
        if (storageValue == null || !(storageValue as String).equals(propertyValue)) {
          Storage.setValue(key, propertyValue);
          System.println("Storage [" + key + "] set to [" + propertyValue + "]");
        }
      }
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  (:typecheck(disableBackgroundCheck))
  function initComfortSettings() as Void {
    var comfort = getComfort();

    var humMin = $.getStorageValue("comfortHumidityMin", 40) as Number;
    var humMax = $.getStorageValue("comfortHumidityMax", 60) as Number;
    comfort.humidityMin = $.min(humMin, humMax).toNumber();
    comfort.humidityMax = $.max(humMin, humMax).toNumber();

    var tempMin = $.getStorageValue("comfortTempMin", 19) as Number;
    var tempMax = $.getStorageValue("comfortTempMax", 27) as Number;
    comfort.temperatureMin = $.min(tempMin, tempMax).toNumber();
    comfort.temperatureMax = $.max(tempMin, tempMax).toNumber();
  }

  public function getServiceDelegate() as [System.ServiceDelegate] {
    System.println("getServiceDelegate start bg task:");
    return [new BackgroundServiceDelegate()];
  }

  (:typecheck(disableBackgroundCheck))
  function onBackgroundData(data as Application.PersistableType) as Void {
    System.println("Background data recieved");    

    if (data instanceof Lang.Number && data == 0) {
      System.println("Response code is 0 -> reset bg service");
      loadUserSettings();
      return;
    }

    var bgHandler = $.getBGServiceHandler();
    bgHandler.onBackgroundData(data as Dictionary or Number or Null);

    WatchUi.requestUpdate();
  }

  function removeObsolete() {
    Storage.deleteValue("showCurrentForecast");
    Storage.deleteValue("showMinuteForecast");
    Storage.deleteValue("zoomMinuteForecast");
    Storage.deleteValue("zoomMinuteForecastMM");
    Storage.deleteValue("zoomFactorMinuteForecast");
    Storage.deleteValue("maxHoursForecast");
    Storage.deleteValue("showClouds");
    Storage.deleteValue("showCurrentWind");
    Storage.deleteValue("showRelativeWind");
    Storage.deleteValue("showWind");
    Storage.deleteValue("showUVIndex");
    Storage.deleteValue("showTemperature");
    Storage.deleteValue("showRelativeHumidity");
    Storage.deleteValue("showPressure");
    Storage.deleteValue("showDewpoint");
    Storage.deleteValue("showComfortZone");
    Storage.deleteValue("showWeatherCondition");
    Storage.deleteValue("showInfoOneField");
    Storage.deleteValue("showInfoLargeField");
    Storage.deleteValue("showInfoWideField");
    Storage.deleteValue("showInfoSmallField");
  }

  function resetDisplayFields() {
    Storage.setValue("show_one_field", [
      8, // hours forecast
      true, // rain first hour
      false, // zoom when rain
      0.1f, // zoom when mm
      3, // zoom factor
      3, // number of columns
      false, // show weather details when has alert (if was hidden)
      true, // clouds
      true, // wind
      SHOW_WIND_KILOMETERS, // wind format
      true, // uv
      true, // temperature
      true, // relative humidity
      true, // pressure sealevel
      true, // dewpoint
      true, // comfort zone
      true, // weather icons
      SHOW_INFO_NOTHING, // extra info
      true, // details when paused,      
      true, // show 0 temperature line
      true, // show weather text
    ]);

    Storage.setValue("show_large_field", [
      8, // hours forecast
      true, // rain first hour
      true, // zoom when rain
      0.1f, // zoom when mm
      3, // zoom factor
      3, // number of columns
      false, // show weather details when has alert (if was hidden)
      true, // clouds
      true, // wind
      SHOW_WIND_KILOMETERS, // wind format
      true, // uv
      true, // temperature
      true, // relative humidity
      true, // pressure sealevel
      true, // dewpoint
      true, // comfort zone
      true, // weather icons
      SHOW_INFO_NOTHING, // extra info
      true, // details when paused
      true, // show 0 temperature line
      false, // show weather text
    ]);

    Storage.setValue("show_wide_field", [
      8, // hours forecast
      true, // rain first hour
      true, // zoom when rain
      0.1f, // zoom when mm
      3, // zoom factor
      3, // number of columns
      true, // show weather details when has alert (if was hidden)
      true, // clouds
      false, // wind
      SHOW_WIND_KILOMETERS, // wind format
      true, // uv
      true, // temperature
      true, // relative humidity
      false, // pressure sealevel
      false, // dewpoint
      true, // comfort zone
      false, // weather icons
      SHOW_INFO_RELATIVE_WIND, // extra info
      false, // details when paused
      false, // show 0 temperature line
      false, // show weather text
    ]);

    Storage.setValue("show_small_field", [
      6, // hours forecast
      true, // rain first hour
      true, // zoom when rain
      0.1f, // zoom when mm
      3, // zoom factor
      3, // number of columns
      true, // show weather details when has alert (if was hidden)
      true, // clouds
      false, // wind
      SHOW_WIND_KILOMETERS, // wind format
      false, // uv
      false, // temperature
      false, // relative humidity
      false, // pressure sealevel
      false, // dewpoint
      true, // comfort zone
      false, // weather icons
      SHOW_INFO_RELATIVE_WIND, // extra info
      false, // details when paused
      false, // show 0 temperature line
      false, // show weather text
    ]);
  }
}

function getApp() as WhatWeatherApp {
  return Application.getApp() as WhatWeatherApp;
}

var _alertHandler as AlertHandler?;
var _BGServiceHandler as BGServiceHandler?;
var _CurrentLocation as CurrentLocation?;

(:typecheck(disableBackgroundCheck))
function getAlertHandler() as AlertHandler {
  if ($._alertHandler == null) {
    $._alertHandler = new AlertHandler();
  }
  return $._alertHandler as AlertHandler;
}

(:typecheck(disableBackgroundCheck))
function getBGServiceHandler() as BGServiceHandler {
  if ($._BGServiceHandler == null) {
    $._BGServiceHandler = new BGServiceHandler();
  }
  return $._BGServiceHandler as BGServiceHandler;
}

(:typecheck(disableBackgroundCheck))
function getCurrentLocation() as CurrentLocation {
  if ($._CurrentLocation == null) {
    $._CurrentLocation = new CurrentLocation();
  }
  return $._CurrentLocation as CurrentLocation;
}

var g_bg_timeout_seconds as Number = 0;
var g_bg_delay_seconds as Number = 0;
var gSizeArrFieldItems = 21;
var gShow_OneField as Array<Numeric> = [] as Array<Numeric>;
var gShow_LargeField as Array<Numeric> = [] as Array<Numeric>;
var gShow_WideField as Array<Numeric> = [] as Array<Numeric>;
var gShow_SmallField as Array<Numeric> = [] as Array<Numeric>;
