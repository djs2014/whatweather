import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
using Toybox.Position;
using WhatAppBase.Utils as Utils;

var _mostRecentData as WeatherData?;

class WhatWeatherApp extends Application.AppBase {
  function initialize() {
    AppBase.initialize();    
    $._weatherDescriptions = Application.loadResource(Rez.JsonData.weatherDescriptions) as Dictionary;
  }

  function onStart(state as Dictionary?) as Void {    }

  function onStop(state as Dictionary?) as Void {    }

    //! Return the initial view of your application here
  function getInitialView() as Array<Views or InputDelegates> ? {
    loadUserSettings();
    return [new WhatWeatherView()] as Array < Views or InputDelegates > ;
  }

  function onSettingsChanged() as Void { loadUserSettings(); }

  function loadUserSettings() as Void {
    try {
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
      $._alwaysUpdateGarminWeather = Utils.getApplicationProperty("alwaysUpdateGarminWeather", false) as Lang.Boolean;

      $._alertHandler.setAlertPrecipitationChance($._alertLevelPrecipitationChance);
      $._alertHandler.setAlertUVi($._alertLevelUVi);
      $._alertHandler.setAlertRainMMfirstHour($._alertLevelRainMMfirstHour);
      $._alertHandler.setAlertWindSpeed($._alertLevelWindSpeed);
      $._alertHandler.resetStatus();

      initComfortSettings();
      System.println("Settings loaded");
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
}

function getApp() as WhatWeatherApp {
  return Application.getApp() as WhatWeatherApp;
}