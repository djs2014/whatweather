import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Application.Storage;
using Toybox.Position;
using WhatAppBase.Utils as Utils;

var _BGServiceHandler as BGServiceHandler?; 
var _alertHandler as AlertHandler?;
var _bgData as WeatherData?;

(:background)
var _mostRecentData as WeatherData?;
(:background)
var _weatherDescriptions as Lang.Dictionary = {};

(:background)
class WhatWeatherApp extends Application.AppBase {
  function initialize() {
    AppBase.initialize();       
  }

  function onStart(state as Dictionary?) as Void {    }

  function onStop(state as Dictionary?) as Void {    }

 (:typecheck(disableBackgroundCheck))  
  function getInitialView() as Array<Views or InputDelegates> ? {    
    $._weatherDescriptions = Application.loadResource(Rez.JsonData.weatherDescriptions) as Dictionary;
    loadUserSettings();
    return [new WhatWeatherView()] as Array < Views or InputDelegates > ;
  }

  function onSettingsChanged() as Void { loadUserSettings(); }

  (:typecheck(disableBackgroundCheck))
  function getBGServiceHandler() as BGServiceHandler {
    if ($._BGServiceHandler == null) {
      $._BGServiceHandler = new BGServiceHandler();
    }
    return $._BGServiceHandler;
  }

  (:typecheck(disableBackgroundCheck))
  function getAlertHandler() as AlertHandler {
    if ($._alertHandler == null) {
      $._alertHandler = new AlertHandler();
    }
    return $._alertHandler;
  }

  (:typecheck(disableBackgroundCheck))
  function loadUserSettings() as Void {
    try {
      System.println("Loading user settings");  
      $._showCurrentForecast = Utils.getApplicationPropertyAsBoolean("showCurrentForecast", true);
      $._maxMinuteForecast = Utils.getApplicationPropertyAsNumber("maxMinuteForecast", 0);
      $._maxHoursForecast = Utils.getApplicationPropertyAsNumber("maxHoursForecast", 8);
      $._alertLevelPrecipitationChance = Utils.getApplicationPropertyAsNumber("alertLevelPrecipitationChance", 70);
      $._showAlertLevel = Utils.getApplicationPropertyAsBoolean("showAlertLevel", true);      
      $._dashesUnderColumnHeight = Utils.getApplicationPropertyAsNumber("dashesUnderColumnHeight", 2);
      $._showColumnBorder = Utils.getApplicationPropertyAsBoolean("showColumnBorder", false);
      $._showObservationTime = Utils.getApplicationPropertyAsBoolean("showObservationTime", true);
      $._showObservationLocationName = Utils.getApplicationPropertyAsBoolean("showObservationLocationName", true);
      $._observationTimeDelayedMinutesThreshold = Utils.getApplicationPropertyAsNumber("observationTimeDelayedMinutesThreshold", 30);
      $._showClouds = Utils.getApplicationPropertyAsBoolean("showClouds", true);
      $._showUVIndexFactor = Utils.getApplicationPropertyAsNumber("showUVIndexFactor", 2);
      $._hideUVIndexLowerThan = Utils.getApplicationPropertyAsNumber("hideUVIndexLowerThan", 4);
      $._showInfo = Utils.getApplicationPropertyAsNumber("showInfo", SHOW_INFO_TIME_Of_DAY);
      $._showInfo2 = Utils.getApplicationPropertyAsNumber("showInfo2", SHOW_INFO_AMBIENT_PRESSURE);
      $._showPrecipitationChanceAxis = Utils.getApplicationPropertyAsBoolean("showPrecipitationChanceAxis", true);
      $._alertLevelUVi = Utils.getApplicationPropertyAsNumber("alertLevelUVi", 6);
      $._alertLevelRainMMfirstHour = Utils.getApplicationPropertyAsNumber("alertLevelRainMMfirstHour", 5);

      $._showWind = Utils.getApplicationPropertyAsNumber("showWind", SHOW_WIND_BEAUFORT);
      $._alertLevelWindSpeed = Utils.getApplicationPropertyAsNumber("alertLevelWindSpeed", 5);
      $._showTemperature = Utils.getApplicationPropertyAsBoolean("showTemperature", true);
      $._showRelativeHumidity = Utils.getApplicationPropertyAsBoolean("showRelativeHumidity", true);
      $._showComfort = Utils.getApplicationPropertyAsBoolean("showComfort", true);
      $._showGlossary = Utils.getApplicationPropertyAsBoolean("showGlossary", false);

      $._showWeatherCondition = Utils.getApplicationPropertyAsBoolean("showWeatherCondition", true);
      
      var bgHandler =  getBGServiceHandler();
      bgHandler.setObservationTimeDelayedMinutes(Utils.getApplicationPropertyAsNumber("observationTimeDelayedMinutesThreshold", 10));
      // @@ TODO add in settings
      bgHandler.setMinimalGPSLevel(Utils.getApplicationPropertyAsNumber("minimalGPSquality", 3));
      bgHandler.setUpdateFrequencyInMinutes(Utils.getApplicationPropertyAsNumber("updateFrequencyWebReq", 5));
      // @@ Enable handler if show temperature or show clouds/uvi (-> use owm) 
      if ($._showClouds || $._showUVIndexFactor > 0 || $._showInfo == SHOW_INFO_TEMPERATURE || $._showInfo2 == SHOW_INFO_TEMPERATURE) {
        bgHandler.Enable(); 
      } else {
        bgHandler.Disable(); 
      }

      System.println("Alerthandler");
      var alertHandler = getAlertHandler();     
      alertHandler.setAlertPrecipitationChance($._alertLevelPrecipitationChance);
      System.println("Alerthandler 1");
      alertHandler.setAlertUVi($._alertLevelUVi);
      System.println("Alerthandler 2");
      alertHandler.setAlertRainMMfirstHour($._alertLevelRainMMfirstHour);
      System.println("Alerthandler 3");
      alertHandler.setAlertWindSpeed($._alertLevelWindSpeed);
      System.println("Alerthandler 4");
      alertHandler.resetStatus();

      initComfortSettings();
      System.println("Comfort settings");

      var ws =  Utils.getApplicationPropertyAsNumber("weatherDataSource", 0);
      $._weatherDataSource = ws as WeatherSource;
      Storage.setValue("weatherDataSource", ws);
      Storage.setValue("openWeatherAPIKey", Utils.getApplicationPropertyAsString("openWeatherAPIKey",""));
      Storage.setValue("openWeatherProxy", Utils.getApplicationPropertyAsString("openWeatherProxy",""));
      Storage.setValue("openWeatherProxyAPIKey", Utils.getApplicationPropertyAsString("openWeatherProxyAPIKey",""));                    
    
      System.println("User settings loaded");
    } catch (ex) {
      ex.printStackTrace();
      System.println(ex.getErrorMessage());
    }
  }

  (:typecheck(disableBackgroundCheck))  
  hidden function initComfortSettings() as Void {
      var humMin = Utils.getApplicationPropertyAsNumber("comfortHumidityMin", 40);
      var humMax = Utils.getApplicationPropertyAsNumber("comfortHumidityMax", 60);
      $._comfortHumidity[0] = Utils.min(humMin, humMax);
      $._comfortHumidity[1] = Utils.max(humMin, humMax);

      var tempMin = Utils.getApplicationPropertyAsNumber("comfortTempMin", 21);
      var tempMax = Utils.getApplicationPropertyAsNumber("comfortTempMax", 27);
      $._comfortTemperature[0] = Utils.min(tempMin, tempMax);
      $._comfortTemperature[1] = Utils.max(tempMin, tempMax);

      var popMin = Utils.getApplicationPropertyAsNumber("comfortPopMin", 0);
      var popMax = Utils.getApplicationPropertyAsNumber("comfortPopMax", 40);
      $._comfortPrecipitationChance[0] = Utils.min(popMin, popMax);
      $._comfortPrecipitationChance[1] = Utils.max(popMin, popMax);
    }

  public function getServiceDelegate() as Array<System.ServiceDelegate> {
    return [new BackgroundServiceDelegate()] as Array<System.ServiceDelegate>;
  }

  (:typecheck(disableBackgroundCheck))
  function onBackgroundData(data) {
    System.println("Background data recieved");
    var bgHandler = getBGServiceHandler();
    bgHandler.onBackgroundData(data, self, :updateBgData);
                      
    WatchUi.requestUpdate();
  }

  (:typecheck(disableBackgroundCheck))
  function updateBgData(bgHandler as BGServiceHandler, data as Dictionary) as Void {
    // First entry hourly in OWM is current entry
    var bgData = WeatherService.toWeatherData(data, true);
    $._bgData = bgData;
    bgHandler.setLastObservationMoment(bgData.getObservationTime());    
  }
}

function getApp() as WhatWeatherApp {
  return Application.getApp() as WhatWeatherApp;
}

