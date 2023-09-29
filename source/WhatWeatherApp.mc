import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Application.Storage;
using Toybox.Position;


var _BGServiceHandler as BGServiceHandler?;
var _alertHandler as AlertHandler?;
// var _bgData as WeatherData?;

// (:background)
// var _mostRecentData as WeatherData?;
(:background)
var _weatherDescriptions as Lang.Dictionary = {};

(:background)
class WhatWeatherApp extends Application.AppBase {
  var mInBackground as Boolean = false;
  function initialize() {
    AppBase.initialize();
  }

  function onStart(state as Dictionary?) as Void {}

  function onStop(state as Dictionary?) as Void {
    // @@ when activity is stopping?
    // if (!mInBackground) {
    //   System.println("deleteTemporalEvent");
    //   Background.deleteTemporalEvent();
    // }
  }

  (:typecheck(disableBackgroundCheck))
  function getInitialView() as Array<Views or InputDelegates>? {
    $._weatherDescriptions = Application.loadResource(Rez.JsonData.weatherDescriptions) as Dictionary;
    loadUserSettings();
    return [new WhatWeatherView()] as Array<Views or InputDelegates>;
  }

  (:typecheck(disableBackgroundCheck))
  function onSettingsChanged() as Void {
    loadUserSettings();
  }

  (:typecheck(disableBackgroundCheck))
  function getBGServiceHandler() as BGServiceHandler {
    if ($._BGServiceHandler == null) {
      $._BGServiceHandler = new BGServiceHandler();
    }
    return $._BGServiceHandler as BGServiceHandler;
  }

  (:typecheck(disableBackgroundCheck))
  function getAlertHandler() as AlertHandler {
    if ($._alertHandler == null) {
      $._alertHandler = new AlertHandler();
    }
    return $._alertHandler as AlertHandler;
  }

  (:typecheck(disableBackgroundCheck))
  function loadUserSettings() as Void {
    try {
      System.println("Loading user settings");
      $._showCurrentForecast = $.getApplicationProperty("showCurrentForecast", true) as Boolean;
      $._showMinuteForecast = $.getApplicationProperty("showMinuteForecast", true) as Boolean;
      $._maxHoursForecast = $.getApplicationProperty("maxHoursForecast", 8) as Number;

      $._showClouds = $.getApplicationProperty("showClouds", true) as Boolean;

      $._showInfoSmallField = $.getApplicationProperty("showInfoSmallField", SHOW_INFO_TIME_Of_DAY) as Number;
      $._showInfoLargeField = $.getApplicationProperty("showInfoLargeField", SHOW_INFO_NOTHING) as Number;
      $._showCurrentWind = $.getApplicationProperty("showCurrentWind", true) as Boolean;

      $._alertLevelPrecipitationChance = $.getApplicationProperty("alertLevelPrecipitationChance", 70) as Number;
      $._alertLevelUVi = $.getApplicationProperty("alertLevelUVi", 6) as Number;
      $._alertLevelRainMMfirstHour = $.getApplicationProperty("alertLevelRainMMfirstHour", 2) as Number;
      $._alertLevelDewpoint = $.getApplicationProperty("alertLevelDewpoint", 19) as Number;
      $._alertLevelWindSpeed = $.getApplicationProperty("alertLevelWindSpeed", 5) as Number;

      $._showUVIndex = $.getApplicationProperty("showUVIndex", true) as Boolean;
      $._maxUVIndex = $.getApplicationProperty("maxUVIndex", 20) as Number;
      $._showWind = $.getApplicationProperty("showWind", SHOW_WIND_BEAUFORT) as Number;
      $._showTemperature = $.getApplicationProperty("showTemperature", true) as Boolean;

      $._maxTemperature = $.getApplicationProperty("maxTemperature", 50) as Number;
      $._maxPressure = $.getApplicationProperty("maxPressure", 1080) as Number;
      $._minPressure = $.getApplicationProperty("minPressure", 870) as Number;

      $._showRelativeHumidity = $.getApplicationProperty("showRelativeHumidity", true) as Boolean;
      $._showPressure = $.getApplicationProperty("showPressure", true) as Boolean;
      $._showDewpoint = $.getApplicationProperty("showDewpoint", true) as Boolean;
      $._showComfortZone = $.getApplicationProperty("showComfortZone", true) as Boolean;
      $._showWeatherCondition = $.getApplicationProperty("showWeatherCondition", true) as Boolean;
      // $._showWeatherAlerts = $.getApplicationProperty("showWeatherAlerts", true) as Boolean;

      var bgHandler = getBGServiceHandler();
      bgHandler.setObservationTimeDelayedMinutes($._observationTimeDelayedMinutesThreshold);
      bgHandler.setMinimalGPSLevel($.getApplicationProperty("minimalGPSquality", 3) as Number);

      var ws = $.getApplicationProperty("weatherDataSource", 0) as Number;
      $._weatherDataSource = ws as WeatherSource;
      if (
        $._showInfoSmallField == SHOW_INFO_TEMPERATURE ||
        $._showInfoLargeField == SHOW_INFO_TEMPERATURE ||
        $._weatherDataSource == wsOWMFirst ||
        $._weatherDataSource == wsOWMOnly ||
        $._weatherDataSource == wsGarminFirst
      ) {
        bgHandler.Enable();
      } else {
        bgHandler.Disable();
      }

      var alertHandler = getAlertHandler();
      alertHandler.setAlertPrecipitationChance($._alertLevelPrecipitationChance);
      alertHandler.setAlertUVi($._alertLevelUVi);
      alertHandler.setAlertRainMMfirstHour($._alertLevelRainMMfirstHour);
      alertHandler.setAlertWindSpeed($._alertLevelWindSpeed);
      alertHandler.setAlertDewpoint($._alertLevelDewpoint);
      alertHandler.resetStatus();

      initComfortSettings();
      System.println("Comfort settings");

      Storage.setValue("weatherDataSource", ws);
      setStorageValueIfChanged("openWeatherAPIKey", "");

      // Fix proxy url
      var proxuUrl = $.getApplicationProperty("openWeatherProxy", "") as String;
      if (proxuUrl.equals("https://api.castlephoto.info/owm_one")) {
        Application.Properties.setValue("openWeatherProxy", "https://owm.castlephoto.info/owm_one");  
      }
      
      setStorageValueIfChanged("openWeatherProxy", "https://owm.castlephoto.info/owm_one");
      setStorageValueIfChanged("openWeatherProxyAPIKey", "0548b3c7-61bc-4afc-b6e5-616f19d3cf23");
      Storage.setValue("openWeatherAPIVersion", $.getApplicationProperty("openWeatherAPIVersion", 1) as Number);
      Storage.setValue("testScenario", $.getApplicationProperty("testScenario", 0) as Number);

      Storage.setValue("openWeatherMaxHours", $._maxHoursForecast + 1);
      Storage.setValue("openWeatherMinutely", $._showMinuteForecast as Boolean);
      // Storage.setValue("openWeatherAlerts", $._showWeatherAlerts);

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
        // update properties
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
  hidden function initComfortSettings() as Void {
    var comfort = getComfort();

    var humMin = $.getApplicationProperty("comfortHumidityMin", 40) as Number;
    var humMax = $.getApplicationProperty("comfortHumidityMax", 60) as Number;
    comfort.humidityMin = $.min(humMin, humMax).toNumber();
    comfort.humidityMax = $.max(humMin, humMax).toNumber();

    var tempMin = $.getApplicationProperty("comfortTempMin", 19) as Number;
    var tempMax = $.getApplicationProperty("comfortTempMax", 27) as Number;
    comfort.temperatureMin = $.min(tempMin, tempMax).toNumber();
    comfort.temperatureMax = $.max(tempMin, tempMax).toNumber();
  }

  public function getServiceDelegate() as Array<System.ServiceDelegate> {
    mInBackground = true;
    return [new BackgroundServiceDelegate()] as Array<System.ServiceDelegate>;
  }

  (:typecheck(disableBackgroundCheck))
  function onBackgroundData(data) {
    System.println("Background data recieved");
    //System.println(data);

    if (data instanceof Lang.Number && data == 0) {
      System.println("Response code is 0 -> reset bg service");
      loadUserSettings();
      return;
    }

    var bgHandler = getBGServiceHandler();
    bgHandler.onBackgroundData(data); //, self, :updateBgData);

    WatchUi.requestUpdate();
  }

  // (:typecheck(disableBackgroundCheck))
  // function updateBgData(bgHandler as BGServiceHandler, data as Dictionary) as Void {
  //   // First entry hourly in OWM is current entry
  //   var bgData = toWeatherData(data, true);
  //   // $._bgData = bgData;
  //   bgHandler.setLastObservationMoment(bgData.getObservationTime());
  // }
}

function getApp() as WhatWeatherApp {
  return Application.getApp() as WhatWeatherApp;
}
