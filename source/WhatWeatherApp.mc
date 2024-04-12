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

(:typecheck(disableBackgroundCheck))
var _weatherDescriptions as Lang.Array = []; // Lang.Dictionary = {};

(:background)
class WhatWeatherApp extends Application.AppBase {
  function initialize() {
    AppBase.initialize();
  }

  function onStart(state as Dictionary?) as Void {}

  function onStop(state as Dictionary?) as Void {}

  (:typecheck(disableBackgroundCheck))
  function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
    $._weatherDescriptions = Application.loadResource(Rez.JsonData.weatherDescriptions) as Array;
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
      var reset = Storage.getValue("resetDefaults");
      if (reset == null || (reset as Boolean)) {
        Storage.setValue("resetDefaults", false);

        Storage.setValue("showCurrentForecast", true);
        Storage.setValue("showMinuteForecast", true);
        Storage.setValue("maxHoursForecast", 8);
        Storage.setValue("showClouds", true);
        Storage.setValue("showCurrentWind", true);
        Storage.setValue("showRelativeWind", true);
        Storage.setValue("showWind", SHOW_WIND_BEAUFORT);
        Storage.setValue("showUVIndex", true);
        Storage.setValue("showTemperature", true);
        Storage.setValue("showRelativeHumidity", true);
        Storage.setValue("showPressure", true);
        Storage.setValue("showDewpoint", true);
        Storage.setValue("showComfortZone", true);
        Storage.setValue("showWeatherCondition", true);

        Storage.setValue("showInfoOneField", SHOW_INFO_NOTHING);
        Storage.setValue("showInfoLargeField", SHOW_INFO_NOTHING);
        Storage.setValue("showInfoWideField", SHOW_INFO_RELATIVE_WIND);
        Storage.setValue("showInfoSmallField", SHOW_INFO_RELATIVE_WIND);

        Storage.setValue("alertLevelPrecipitationChance", 70);
        Storage.setValue("alertLevelUVi", 6);
        Storage.setValue("alertLevelRainMMfirstHour", 0.2f);
        Storage.setValue("alertLevelRainMMHour", 0.2f);
        Storage.setValue("alertLevelWindSpeed", 5);
        Storage.setValue("alertLevelDewpoint", 19);

        Storage.setValue("maxUVIndex", 20);
        Storage.setValue("maxTemperature", 50);
        Storage.setValue("minPressure", 870);
        Storage.setValue("maxPressure", 1080);

        Storage.setValue("comfortHumidityMin", 40);
        Storage.setValue("comfortHumidityMax", 60);
        Storage.setValue("comfortTempMin", 19);
        Storage.setValue("comfortTempMax", 27);
      }

      // $.gDebug = $.getStorageValue("debug", $.gDebug) as Boolean;

      // showweather
      $._weatherDataSource = $.getStorageValue("weatherDataSource", $._weatherDataSource) as WeatherSource;

      $._showCurrentForecast = $.getStorageValue("showCurrentForecast", $._showCurrentForecast) as Boolean;
      $._showMinuteForecast = $.getStorageValue("showMinuteForecast", $._showMinuteForecast) as Boolean;
      $._maxHoursForecast = $.getStorageValue("maxHoursForecast", $._maxHoursForecast) as Number;
      $._showClouds = $.getStorageValue("showClouds", $._showClouds) as Boolean;
      $._showCurrentWind = $.getStorageValue("showCurrentWind", $._showCurrentWind) as Boolean;
      $._showRelativeWindFirst = $.getStorageValue("showRelativeWind", $._showRelativeWindFirst) as Boolean;
      $._showWind = $.getStorageValue("showWind", $._showWind) as Number;
      $._showUVIndex = $.getStorageValue("showUVIndex", $._showUVIndex) as Boolean;
      $._showTemperature = $.getStorageValue("showTemperature", $._showTemperature) as Boolean;
      $._showRelativeHumidity = $.getStorageValue("showRelativeHumidity", $._showRelativeHumidity) as Boolean;
      $._showPressure = $.getStorageValue("showPressure", $._showPressure) as Boolean;
      $._showDewpoint = $.getStorageValue("showDewpoint", $._showDewpoint) as Boolean;
      $._showComfortZone = $.getStorageValue("showComfortZone", $._showComfortZone) as Boolean;
      $._showWeatherCondition = $.getStorageValue("showWeatherCondition", $._showWeatherCondition) as Boolean;

      $._showInfoOneField = $.getStorageValue("showInfoOneField", SHOW_INFO_NOTHING) as Number;
      $._showInfoLargeField = $.getStorageValue("showInfoLargeField", SHOW_INFO_NOTHING) as Number;
      $._showInfoWideField = $.getStorageValue("showInfoWideField", SHOW_INFO_NOTHING) as Number;
      $._showInfoSmallField = $.getStorageValue("showInfoSmallField", SHOW_INFO_TIME_Of_DAY) as Number;

      $._alertLevelPrecipitationChance = $.getStorageValue("alertLevelPrecipitationChance", 70) as Number;
      $._alertLevelUVi = $.getStorageValue("alertLevelUVi", 6) as Number;
      $._alertLevelRainMMfirstHour = $.getStorageValue("alertLevelRainMMfirstHour", 0.2f) as Float;
      $._alertLevelRainMMHour = $.getStorageValue("alertLevelRainMMHour", 0.2f) as Float;
      $._alertLevelWindSpeed = $.getStorageValue("alertLevelWindSpeed", 5) as Number;
      $._alertLevelDewpoint = $.getStorageValue("alertLevelDewpoint", 19) as Number;

      $._maxUVIndex = $.getStorageValue("maxUVIndex", 20) as Number;
      $._maxTemperature = $.getStorageValue("maxTemperature", 50) as Number;
      $._maxPressure = $.getStorageValue("maxPressure", 1080) as Number;
      $._minPressure = $.getStorageValue("minPressure", 870) as Number;
      if ($._minPressure > $._maxPressure) {
        $._minPressure = 870;
        $._maxPressure = 1080;
      }

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
      if (
        $._weatherDataSource == wsOWMFirst ||
        $._weatherDataSource == wsOWMOnly ||
        $._weatherDataSource == wsGarminFirst
      ) {
        bgHandler.Enable();
      } else {
        bgHandler.Disable();
      }

      var alertHandler = $.getAlertHandler();
      alertHandler.setAlertPrecipitationChance($._alertLevelPrecipitationChance);
      alertHandler.setAlertUVi($._alertLevelUVi);
      alertHandler.setAlertRainMMfirstHour($._alertLevelRainMMfirstHour);
      alertHandler.setAlertRainMMHour($._alertLevelRainMMHour);
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
      Storage.setValue("openWeatherAPIVersion", $.getStorageValue("openWeatherAPIVersion", 1) as Number);
      Storage.setValue("testScenario", $.getStorageValue("testScenario", 0) as Number);

      Storage.setValue("openWeatherMaxHours", $._maxHoursForecast + 1);
      Storage.setValue("openWeatherMinutely", $._showMinuteForecast as Boolean);

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
    return [new BackgroundServiceDelegate()];
  }

  (:typecheck(disableBackgroundCheck))
  function onBackgroundData(data as Application.PersistableType) as Void {
    System.println("Background data recieved");
    //System.println(data);

    if (data instanceof Lang.Number && data == 0) {
      System.println("Response code is 0 -> reset bg service");
      loadUserSettings();
      return;
    }

    var bgHandler = $.getBGServiceHandler();
    bgHandler.onBackgroundData(data as Dictionary or Number or Null);

    WatchUi.requestUpdate();
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
