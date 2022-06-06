import Toybox.Lang;
import Toybox.System;
using WhatAppBase.Utils as Utils;

enum ActiveAlert {
  aaUvi,
  aaRain1stHour,
  aaPrecChance,
  aaWind,
  aaWeather
}

class AlertHandler {
  hidden var alertUvi as Lang.Number = 0;
  hidden var alertPrecipitationChance as Lang.Number = 0;
  hidden var alertRainMMfirstHour as Lang.Number = 0;
  hidden var alertWindSpeed as Lang.Number = 0;

  var maxUvi as Lang.Float = 0.0;
  var maxPrecipitationChance as Lang.Number = 0;
  var maxRainMMfirstHour as Lang.Number = 0;
  var maxWindSpeed as Lang.Float = 0.0;
  
  hidden var WEATHER_NEUTRAL as Lang.Number = 0x00AAFF;  // COLOR_BLUE

  hidden const NEUTRAL = 0;
  hidden const TRIGGERED = 1;
  hidden const HANDLED = 2;

  hidden var statusUvi as Lang.Number = NEUTRAL;
  hidden var statusPrecipitationChance as Lang.Number = NEUTRAL;
  hidden var statusRainMMfirstHour as Lang.Number = NEUTRAL;
  hidden var statusWeather as Lang.Number = NEUTRAL;
  hidden var statusWindSpeed as Lang.Number = NEUTRAL;

  hidden var allClearUvi as Lang.Boolean = true;
  hidden var allClearPrecipitationChance as Lang.Boolean = true;
  hidden var allClearRainMMfirstHour as Lang.Boolean = true;
  hidden var allClearWeather as Lang.Boolean = true;
  hidden var allClearWindSpeed as Lang.Boolean = true;

  
  function setAlertPrecipitationChance(value as Lang.Number) as Void {
    alertPrecipitationChance = value;
  }

  function setAlertUVi(value as Lang.Number) as Void { alertUvi = value; }

  function setAlertRainMMfirstHour(value as Lang.Number) as Void { alertRainMMfirstHour = value; }

  //! is in beaufort

  function setAlertWindSpeed(value as Lang.Number) as Void { alertWindSpeed = value; }

  function infoUvi() as Lang.String {
    return Lang.format(
        "alerthandler alertUvi[$1$] statusUvi[$2$] allClearUvi[$3$]",
        [ alertUvi, statusUvi, allClearUvi ]);
  }

  function infoPrecipitationChance() as Lang.String {
    return Lang.format(
        "alerthandler alertPop[$1$] statusPop[$2$] allClearPop[$3$]", [
          alertPrecipitationChance, statusPrecipitationChance,
          allClearPrecipitationChance
        ]);
  }
  //! alert flow:
  //!  level reached --> alert triggered (display/play alert) --> (handled
  //!  displayed alert) --> reset when level below alert

  function isAnyAlertTriggered() as Lang.Boolean {
    return (statusUvi == TRIGGERED) ||
           (statusPrecipitationChance == TRIGGERED) ||
           (statusRainMMfirstHour == TRIGGERED) ||
           (statusWeather == TRIGGERED) || (statusWindSpeed == TRIGGERED);
  }

  function infoHandledShort() as Lang.String {
    var info = "";
    if (statusUvi == HANDLED) {
      info = info + " Uv";
    }
    if (statusPrecipitationChance == HANDLED) {
      info = info + " R%";
    }
    if (statusRainMMfirstHour == HANDLED) {
      info = info + " R";
    }
    if (statusWeather == HANDLED) {
      info = info + " W";
    }
    if (statusWindSpeed == HANDLED) {      
      info = info + " Ws";
    }
    return info;
  }

  function infoHandled() as Lang.String {
    var info = "";
    if (statusUvi == HANDLED) {
      info = info + " Uv" + maxUvi.format("%.1f");
    }
    if (statusPrecipitationChance == HANDLED) {
      info = info + " R%" + maxPrecipitationChance.format("%d");
    }
    if (statusRainMMfirstHour == HANDLED) {
      info = info + " R" + maxRainMMfirstHour.format("%d");
    }
    if (statusWeather == HANDLED) {
      info = info + " W";
    }
    if (statusWindSpeed == HANDLED) {
      var beaufort = Utils.windSpeedToBeaufort(maxWindSpeed);
      info = info + " Ws" + beaufort.format("%d");
    }
    return info;
  }

  function activeAlerts() as Array {
    var info = [];
    if (statusUvi == HANDLED) {
      info.add(aaUvi);      
    }
    if (statusPrecipitationChance == HANDLED) {
      info.add(aaPrecChance);          
    }
    if (statusRainMMfirstHour == HANDLED) {
      info.add(aaRain1stHour);                
    }
    if (statusWeather == HANDLED) {
      info.add(aaWeather);                
    }
    if (statusWindSpeed == HANDLED) {
      info.add(aaWind);                
    }
    // info.add(aaUvi);  
    // info.add(aaWind);   
    return info;    
  }

  function currentlyTriggeredHandled() as Void{
    if (statusUvi == TRIGGERED) {
      statusUvi = HANDLED;
      allClearUvi = true;
    }
    if (statusPrecipitationChance == TRIGGERED) {
      statusPrecipitationChance = HANDLED;
      allClearPrecipitationChance = true;
    }
    if (statusRainMMfirstHour == TRIGGERED) {
      statusRainMMfirstHour = HANDLED;
      allClearRainMMfirstHour = true;
    }
    if (statusWeather == TRIGGERED) {
      statusWeather = HANDLED;
      allClearWeather = true;
    }
    if (statusWindSpeed == TRIGGERED) {
      statusWindSpeed = HANDLED;
      allClearWindSpeed = true;
    }
  }

  function resetStatus() as Void {
    statusPrecipitationChance = NEUTRAL;
    statusUvi = NEUTRAL;
    statusRainMMfirstHour = NEUTRAL;
    statusWeather = NEUTRAL;
    statusWindSpeed = NEUTRAL;

    maxUvi = 0.0;
    maxPrecipitationChance = 0;
    maxRainMMfirstHour = 0;
    maxWindSpeed = 0.0;
  }

  function checkStatus() as Void {
    //maxPrecipitationChance = 0; ??
    if (allClearUvi) {
      statusUvi = NEUTRAL;      
    }
    if (allClearPrecipitationChance) {
      statusPrecipitationChance = NEUTRAL;      
    }
    if (allClearRainMMfirstHour) {
      statusRainMMfirstHour = NEUTRAL;      
    }
    if (allClearWeather) {
      statusWeather = NEUTRAL;      
    }
    if (allClearWindSpeed) {
      statusWindSpeed = NEUTRAL;      
    }
    resetAllClear();
  }

  hidden function resetAllClear() as Void {
    allClearUvi = true;
    allClearPrecipitationChance = true;
    allClearRainMMfirstHour = true;
    allClearWeather = true;
    allClearWindSpeed = true;
  }

  function processUvi(uvi as Lang.Float?) as Void {
    if (alertUvi <= 0 || uvi == null) {
      return;
    }
    maxUvi = Utils.max(maxUvi, uvi) as Float;    
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusUvi == NEUTRAL && uvi >= alertUvi) {
      statusUvi = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearUvi = allClearUvi && (statusUvi == HANDLED && uvi < alertUvi);
  }

  function processPrecipitationChance(chance as Lang.Number?) as Void {
    if (chance == null) {
      return;
    }
   
    maxPrecipitationChance = Utils.max(maxPrecipitationChance, chance) as Number;
   
    if (alertPrecipitationChance <= 0) {
      return;
    }
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusPrecipitationChance == NEUTRAL && chance >= alertPrecipitationChance) {
      statusPrecipitationChance = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearPrecipitationChance = allClearPrecipitationChance && (statusPrecipitationChance == HANDLED &&
                                        chance < alertPrecipitationChance);
  }

  function processRainMMfirstHour(mm as Lang.Number?) as Void {
    if (alertRainMMfirstHour <= 0 || mm == null) {
      return;
    }

    maxRainMMfirstHour = Utils.max(maxRainMMfirstHour, mm) as Number;    
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusRainMMfirstHour == NEUTRAL && mm >= alertRainMMfirstHour) {
      statusRainMMfirstHour = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearRainMMfirstHour =
        allClearRainMMfirstHour &&
        (statusRainMMfirstHour == HANDLED && mm < alertRainMMfirstHour);
  }

  function processWeather(colorValue as Lang.Number?) as Void{
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusWeather == NEUTRAL && colorValue != WEATHER_NEUTRAL) {
      statusWeather = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearWeather = allClearWeather && (statusWeather == HANDLED &&
                                          colorValue == WEATHER_NEUTRAL);
  }

  function processWindSpeed(windSpeedMs as Lang.Float?) as Void {
    if (alertWindSpeed <= 0 || windSpeedMs == null) {
      return;
    }
    maxWindSpeed = Utils.max(maxWindSpeed, windSpeedMs) as Float;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    var beaufort = Utils.windSpeedToBeaufort(windSpeedMs);
    if (statusWindSpeed == NEUTRAL && beaufort >= alertWindSpeed) {
      statusWindSpeed = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearWindSpeed = allClearWindSpeed && (statusWindSpeed == HANDLED &&
                                              beaufort < alertWindSpeed);    
  }
}