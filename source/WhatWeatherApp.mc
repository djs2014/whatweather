import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
using Toybox.Position;

var _mostRecentData = null;

class WhatWeatherApp extends Application.AppBase {
  function initialize() {
    AppBase.initialize();
    $._mostRecentData = new WeatherData();        
    $._weatherDescriptions = Application.loadResource(Rez.JsonData.weatherDescriptions);
  }

  // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates> ? {
      loadUserSettings();
      return [new WhatWeatherView()] as Array < Views or InputDelegates > ;
    }

    function onSettingsChanged() { loadUserSettings(); }

    function loadUserSettings() {
      try {
        $._showCurrentForecast =
            getBooleanProperty("showCurrentForecast", true);
        $._maxMinuteForecast = getNumberProperty("maxMinuteForecast", 60);
        $._maxHoursForecast = getNumberProperty("maxHoursForecast", 8);
        $._alertLevelPrecipitationChance =
            getNumberProperty("alertLevelPrecipitationChance", 70);
        $._showAlertLevel = getBooleanProperty("showAlertLevel", true);
        $._showMaxPrecipitationChance =
            getBooleanProperty("showMaxPrecipitationChance", true);
        $._dashesUnderColumnHeight =
            getNumberProperty("dashesUnderColumnHeight", 2);
        $._showColumnBorder = getBooleanProperty("showColumnBorder", false);
        $._showObservationTime =
            getBooleanProperty("showObservationTime", true);
        $._showObservationLocationName =
            getBooleanProperty("showObservationLocationName", true);
        $._observationTimeDelayedMinutesThreshold =
            getNumberProperty("observationTimeDelayedMinutesThreshold", 30);
        $._showClouds = getBooleanProperty("showClouds", true);
        $._showUVIndexFactor = getBooleanProperty("showUVIndexFactor", 2);
        $._hideUVIndexLowerThan = getNumberProperty("hideUVIndexLowerThan", 4);
        $._showInfo = getNumberProperty("showInfo", SHOW_INFO_TIME_Of_DAY);
        $._showInfo2 = getNumberProperty("showInfo2", SHOW_INFO_AMBIENT_PRESSURE);
        $._showPrecipitationChanceAxis =
            getBooleanProperty("showPrecipitationChanceAxis", true);
        $._alertLevelUVi = getNumberProperty("alertLevelUVi", 6);
        $._alertLevelRainMMfirstHour =
            getNumberProperty("alertLevelRainMMfirstHour", 5);

        $._showWind = getNumberProperty("showWind", SHOW_WIND_BEAUFORT);
        $._alertLevelWindSpeed = getNumberProperty("alertLevelWindSpeed", 5);
        $._showTemperature = getBooleanProperty("showTemperature", true);        
        $._showRelativeHumidity = getBooleanProperty("showRelativeHumidity", true);
        $._showComfort = getBooleanProperty("showComfort", true);
        $._showGlossary = getBooleanProperty("showGlossary", false);
  
        $._showWeatherCondition = getBooleanProperty("showWeatherCondition", true);
        $._alwaysUpdateGarminWeather = getBooleanProperty("alwaysUpdateGarminWeather", false);

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

    
    function initComfortSettings() {
      var humMin = getNumberProperty("comfortHumidityMin", 40);
      var humMax = getNumberProperty("comfortHumidityMax", 60);
      $._comfortHumidity[0] = min(humMin, humMax);
      $._comfortHumidity[1] = max(humMin, humMax);

      var tempMin = getNumberProperty("comfortTempMin", 21);
      var tempMax = getNumberProperty("comfortTempMax", 27);
      $._comfortTemperature[0] = min(tempMin, tempMax);
      $._comfortTemperature[1] = max(tempMin, tempMax);

      var popMin = getNumberProperty("comfortPopMin", 0);
      var popMax = getNumberProperty("comfortPopMax", 40);
      $._comfortPrecipitationChance[0] = min(popMin, popMax);
      $._comfortPrecipitationChance[1] = max(popMin, popMax);
    }
}

function getApp() as WhatWeatherApp {
  return Application.getApp() as WhatWeatherApp;
}