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
  var mInBackground as Boolean = false;
  function initialize() {
    AppBase.initialize();       
  }

  function onStart(state as Dictionary?) as Void {    }

  function onStop(state as Dictionary?) as Void {  
    if (!mInBackground) {
      System.println("deleteTemporalEvent");
      Background.deleteTemporalEvent();
    }
  }

  (:typecheck(disableBackgroundCheck))  
  function getInitialView() as Array<Views or InputDelegates> ? {    
    $._weatherDescriptions = Application.loadResource(Rez.JsonData.weatherDescriptions) as Dictionary;
    loadUserSettings();
    return [new WhatWeatherView()] as Array < Views or InputDelegates > ;
  }

  (:typecheck(disableBackgroundCheck))
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
      $._showDetailsWhenPaused = Utils.getApplicationPropertyAsBoolean("showDetailsWhenPaused", true);      
      $._dashesUnderColumnHeight = Utils.getApplicationPropertyAsNumber("dashesUnderColumnHeight", 2);
      // $._showColumnBorder = Utils.getApplicationPropertyAsBoolean("showColumnBorder", false);
      $._showObservationTime = Utils.getApplicationPropertyAsBoolean("showObservationTime", true);
      $._showObservationLocationName = Utils.getApplicationPropertyAsBoolean("showObservationLocationName", true);
      $._observationTimeDelayedMinutesThreshold = Utils.getApplicationPropertyAsNumber("observationTimeDelayedMinutesThreshold", 30);
      $._showClouds = Utils.getApplicationPropertyAsBoolean("showClouds", true);
      
      $._showUVIndex = Utils.getApplicationPropertyAsBoolean("showUVIndex", true);
      $._maxUVIndex = Utils.getApplicationPropertyAsNumber("maxUVIndex", 20);
      $._hideUVIndexLowerThan = Utils.getApplicationPropertyAsNumber("hideUVIndexLowerThan", 4);

      $._showInfoSmallField = Utils.getApplicationPropertyAsNumber("showInfoSmallField", SHOW_INFO_TIME_Of_DAY);
      $._showInfoLargeField = Utils.getApplicationPropertyAsNumber("showInfoLargeField", SHOW_INFO_NOTHING);      
      $._alertLevelUVi = Utils.getApplicationPropertyAsNumber("alertLevelUVi", 6);
      $._alertLevelRainMMfirstHour = Utils.getApplicationPropertyAsNumber("alertLevelRainMMfirstHour", 5);
      $._alertLevelDewpoint = Utils.getApplicationPropertyAsNumber("alertLevelDewpoint", 19);

      $._showWind = Utils.getApplicationPropertyAsNumber("showWind", SHOW_WIND_BEAUFORT);
      $._alertLevelWindSpeed = Utils.getApplicationPropertyAsNumber("alertLevelWindSpeed", 5);
      $._showTemperature = Utils.getApplicationPropertyAsBoolean("showTemperature", true);
      $._showRelativeHumidity = Utils.getApplicationPropertyAsBoolean("showRelativeHumidity", true);
      $._showPressure = Utils.getApplicationPropertyAsBoolean("showPressure", true);
      $._showDewpoint = Utils.getApplicationPropertyAsBoolean("showDewpoint", true);
      $._showComfort = Utils.getApplicationPropertyAsBoolean("showComfort", true);
      // $._showGlossary = Utils.getApplicationPropertyAsBoolean("showGlossary", false);

      $._hideTemperatureLowerThan = Utils.getApplicationPropertyAsNumber("hideTemperatureLowerThan", 8);
      $._showActualWeather = Utils.getApplicationPropertyAsBoolean("showActualWeather", false);

      $._showWeatherCondition = Utils.getApplicationPropertyAsBoolean("showWeatherCondition", true);
      
      var bgHandler =  getBGServiceHandler();
      bgHandler.setObservationTimeDelayedMinutes(Utils.getApplicationPropertyAsNumber("observationTimeDelayedMinutesThreshold", 10));
      // @@ TODO add in settings
      bgHandler.setMinimalGPSLevel(Utils.getApplicationPropertyAsNumber("minimalGPSquality", 3));
      bgHandler.setUpdateFrequencyInMinutes(Utils.getApplicationPropertyAsNumber("updateFrequencyWebReq", 5));

      var ws =  Utils.getApplicationPropertyAsNumber("weatherDataSource", 0);
      $._weatherDataSource = ws as WeatherSource;
      // @@ Enable handler if show temperature or show clouds/uvi (-> use owm) 
      if ($._showClouds || $._showUVIndex || $._showInfoSmallField == SHOW_INFO_TEMPERATURE || $._showInfoLargeField == SHOW_INFO_TEMPERATURE 
      || $._weatherDataSource == wsOWMFirst || $._weatherDataSource == wsOWMOnly) {
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
      Storage.setValue("openWeatherAPIKey", Utils.getApplicationPropertyAsString("openWeatherAPIKey",""));
      Storage.setValue("openWeatherProxy", Utils.getApplicationPropertyAsString("openWeatherProxy",""));
      Storage.setValue("openWeatherProxyAPIKey", Utils.getApplicationPropertyAsString("openWeatherProxyAPIKey",""));                    
      Storage.setValue("openWeatherMaxHours", $._maxHoursForecast + 1);                    
    
      System.println("User settings loaded");
    } catch (ex) {
      ex.printStackTrace();
      System.println(ex.getErrorMessage());
    }
  }

  (:typecheck(disableBackgroundCheck))  
  hidden function initComfortSettings() as Void {
      var comfort = Comfort.getComfort();

      var humMin = Utils.getApplicationPropertyAsNumber("comfortHumidityMin", 40);
      var humMax = Utils.getApplicationPropertyAsNumber("comfortHumidityMax", 60);
      comfort.humidityMin = Utils.min(humMin, humMax).toNumber();
      comfort.humidityMax = Utils.max(humMin, humMax).toNumber();
    
      var tempMin = Utils.getApplicationPropertyAsNumber("comfortTempMin", 21);
      var tempMax = Utils.getApplicationPropertyAsNumber("comfortTempMax", 27);
      comfort.temperatureMin = Utils.min(tempMin, tempMax).toNumber();
      comfort.temperatureMax = Utils.max(tempMin, tempMax).toNumber();

      var popMin = Utils.getApplicationPropertyAsNumber("comfortPopMin", 0);
      var popMax = Utils.getApplicationPropertyAsNumber("comfortPopMax", 40);
      comfort.precipitationChanceMin = Utils.min(popMin, popMax).toNumber();
      comfort.precipitationChanceMax = Utils.max(popMin, popMax).toNumber();
    }

  public function getServiceDelegate() as Array<System.ServiceDelegate> {
    mInBackground = true;
    return [new BackgroundServiceDelegate()] as Array<System.ServiceDelegate>;
  }

  (:typecheck(disableBackgroundCheck))
  function onBackgroundData(data) {
    System.println("Background data recieved");

    if (data instanceof Lang.Number && data == 0) {
      System.println("Response code is 0 -> reset bg service");
      loadUserSettings();
      return;
    }
    
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

