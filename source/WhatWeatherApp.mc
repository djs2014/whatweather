import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Application.Storage;
using Toybox.Position;
using WhatAppBase.Utils as Utils;

var mBGServiceHandler as BGServiceHandler?; 
var _alertHandler as AlertHandler?;
var _bgData as WeatherData?;
var _bgCounter as Number = 0; 
var _bgStatus as Number = 0;

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
    
  function getInitialView() as Array<Views or InputDelegates> ? {
    // try {
    //   if (Toybox.System has :ServiceDelegate) {
    //     Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    //   }
    // } catch (ex) {
    //   ex.printStackTrace();          
    // }   
    $._weatherDescriptions = Application.loadResource(Rez.JsonData.weatherDescriptions) as Dictionary;
    loadUserSettings();
    return [new WhatWeatherView()] as Array < Views or InputDelegates > ;
  }

  function onSettingsChanged() as Void { loadUserSettings(); }

  function getBGServiceHandler() as BGServiceHandler {
    if (mBGServiceHandler == null) {
      mBGServiceHandler = new BGServiceHandler();
    }
    return mBGServiceHandler;
  }

  function loadUserSettings() as Void {
    try {
      System.println("Loading user settings");  
      $._showCurrentForecast = Utils.getApplicationProperty("showCurrentForecast", true) as Lang.Boolean;
      $._maxMinuteForecast = Utils.getApplicationProperty("maxMinuteForecast", 60) as Lang.Number;
      $._maxHoursForecast = Utils.getApplicationProperty("maxHoursForecast", 8) as Lang.Number;
      $._alertLevelPrecipitationChance = Utils.getApplicationProperty("alertLevelPrecipitationChance", 70) as Lang.Number;
      $._showAlertLevel = Utils.getApplicationProperty("showAlertLevel", true) as Lang.Boolean;
      $._showMaxPrecipitationChance = Utils.getApplicationProperty("showMaxPrecipitationChance", true) as Lang.Boolean;
      $._dashesUnderColumnHeight = Utils.getApplicationProperty("dashesUnderColumnHeight", 2) as Lang.Number;
      $._showColumnBorder = Utils.getApplicationProperty("showColumnBorder", false) as Lang.Boolean;
      $._showObservationTime = Utils.getApplicationProperty("showObservationTime", true) as Lang.Boolean;
      $._showObservationLocationName = Utils.getApplicationProperty("showObservationLocationName", true) as Lang.Boolean;
      $._observationTimeDelayedMinutesThreshold = Utils.getApplicationProperty("observationTimeDelayedMinutesThreshold", 30) as Lang.Number;
      $._showClouds = Utils.getApplicationProperty("showClouds", true) as Lang.Boolean;
      $._showUVIndexFactor = Utils.getApplicationProperty("showUVIndexFactor", 2) as Lang.Number;
      $._hideUVIndexLowerThan = Utils.getApplicationProperty("hideUVIndexLowerThan", 4) as Lang.Number;
      $._showInfo = Utils.getApplicationProperty("showInfo", SHOW_INFO_TIME_Of_DAY) as Lang.Number;
      $._showInfo2 = Utils.getApplicationProperty("showInfo2", SHOW_INFO_AMBIENT_PRESSURE) as Lang.Number;
      $._showPrecipitationChanceAxis = Utils.getApplicationProperty("showPrecipitationChanceAxis", true) as Lang.Boolean;
      $._alertLevelUVi = Utils.getApplicationProperty("alertLevelUVi", 6) as Lang.Number;
      $._alertLevelRainMMfirstHour = Utils.getApplicationProperty("alertLevelRainMMfirstHour", 5) as Lang.Number;

      $._showWind = Utils.getApplicationProperty("showWind", SHOW_WIND_BEAUFORT) as Lang.Number;
      $._alertLevelWindSpeed = Utils.getApplicationProperty("alertLevelWindSpeed", 5) as Lang.Number;
      $._showTemperature = Utils.getApplicationProperty("showTemperature", true) as Lang.Boolean;
      $._showRelativeHumidity = Utils.getApplicationProperty("showRelativeHumidity", true) as Lang.Boolean;
      $._showComfort = Utils.getApplicationProperty("showComfort", true) as Lang.Boolean;
      $._showGlossary = Utils.getApplicationProperty("showGlossary", false) as Lang.Boolean;

      $._showWeatherCondition = Utils.getApplicationProperty("showWeatherCondition", true) as Lang.Boolean;
      
      var handler =  getBGServiceHandler();
      handler.setObservationTimeDelayedMinutes(Utils.getApplicationProperty("observationTimeDelayedMinutesThreshold", 10) as Number);
      // @@ TODO add in settings
      handler.setMinimalGPSLevel(Utils.getApplicationProperty("minimalGPSquality", 3) as Number);
      handler.setUpdateFrequencyInMinutes(Utils.getApplicationProperty("updateFrequencyWebReq", 5) as Number);
      // @@ Enable handler if show temperature or show clouds/uvi (-> use owm) 
      if ($._showClouds || $._showUVIndexFactor > 0 || $._showInfo == SHOW_INFO_TEMPERATURE || $._showInfo2 == SHOW_INFO_TEMPERATURE) {
        handler.Enable(); 
      } else {
        handler.Disable(); 
      }

      if ($._alertHandler == null) {
        $._alertHandler = new AlertHandler();
      }
      $._alertHandler.setAlertPrecipitationChance($._alertLevelPrecipitationChance);
      $._alertHandler.setAlertUVi($._alertLevelUVi);
      $._alertHandler.setAlertRainMMfirstHour($._alertLevelRainMMfirstHour);
      $._alertHandler.setAlertWindSpeed($._alertLevelWindSpeed);
      $._alertHandler.resetStatus();

      initComfortSettings();

      Storage.setValue("weatherDataSource", Utils.getApplicationProperty("weatherDataSource",0) as Number);
      Storage.setValue("openWeatherAPIKey", Utils.getApplicationProperty("openWeatherAPIKey","") as String);
      Storage.setValue("openWeatherProxy", Utils.getApplicationProperty("openWeatherProxy","") as String);
      Storage.setValue("openWeatherProxyAPIKey", Utils.getApplicationProperty("openWeatherProxyAPIKey","") as String);                    
    
      System.println("User settings loaded");
    } catch (ex) {
      ex.printStackTrace();
    }
  }
    
  function initComfortSettings() as Void {
      var humMin = Utils.getApplicationProperty("comfortHumidityMin", 40) as Lang.Number;
      var humMax = Utils.getApplicationProperty("comfortHumidityMax", 60) as Lang.Number;
      $._comfortHumidity[0] = Utils.min(humMin, humMax);
      $._comfortHumidity[1] = Utils.max(humMin, humMax);

      var tempMin = Utils.getApplicationProperty("comfortTempMin", 21) as Lang.Number;
      var tempMax = Utils.getApplicationProperty("comfortTempMax", 27) as Lang.Number;
      $._comfortTemperature[0] = Utils.min(tempMin, tempMax);
      $._comfortTemperature[1] = Utils.max(tempMin, tempMax);

      var popMin = Utils.getApplicationProperty("comfortPopMin", 0) as Lang.Number;
      var popMax = Utils.getApplicationProperty("comfortPopMax", 40) as Lang.Number;
      $._comfortPrecipitationChance[0] = Utils.min(popMin, popMax);
      $._comfortPrecipitationChance[1] = Utils.max(popMin, popMax);
    }

  public function getServiceDelegate() as Array<System.ServiceDelegate> {
    return [new BackgroundServiceDelegate()] as Array<System.ServiceDelegate>;
  }

  function onBackgroundData(data) {
    System.println("Background data recieved background");    
    if(data instanceof Number) {
      var responseCode = data as Number;
      $._bgStatus = responseCode;
      if (responseCode > 0) {
        // setErrorMessage("HTTP error: " + responseCode);                            
        // System.println("Error webrequest responsecode: " + data);
      } else {
        // setErrorMessage(getCommunicationError(responseCode));
        //System.println("Error webrequest responsecode: " + Helpers.getCommunicationError(responseCode));
      }
    } else {
      // First entry hourly in OWM is current entry
      $._bgData = WeatherBG.toWeatherData(data, true);
      $._bgStatus = 200;
      $._bgCounter = $._bgCounter + 1;      
      // Storage.setValue("OWMResult", data);        	            
    }
                      
    WatchUi.requestUpdate();
  }
}

function getApp() as WhatWeatherApp {
  return Application.getApp() as WhatWeatherApp;
}

