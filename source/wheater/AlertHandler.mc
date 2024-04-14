import Toybox.Lang;
import Toybox.System;

class AlertHandler {
  hidden var alertUvi as Lang.Number = 0;
  hidden var alertPrecipitationChance as Lang.Number = 0;
  hidden var alertRainMMfirstHour as Lang.Float = 0.0f;
  hidden var alertRainMMHour as Lang.Float = 0.0f;
  hidden var alertWindSpeed as Lang.Number = 0;
  hidden var alertWindGust as Lang.Number = 0;
  hidden var alertDewpoint as Lang.Number = 0;

  var maxUvi as Lang.Float = 0.0;
  var maxPrecipitationChance as Lang.Number = 0;
  var maxRainMMfirstHour as Lang.Number = 0;
  var maxRainMMHour as Lang.Number = 0;
  var maxWindSpeed as Lang.Float = 0.0;
  var maxWindGust as Lang.Number = 0;
  var maxDewpoint as Lang.Float = 0.0;

  hidden var CONDITION_NEUTRAL as Lang.Number = 0x00aaff; // COLOR_BLUE

  hidden const NEUTRAL = 0;
  hidden const TRIGGERED = 1;
  hidden const HANDLED = 2;

  hidden var statusUvi as Lang.Number = NEUTRAL;
  hidden var statusPrecipitationChance as Lang.Number = NEUTRAL;
  hidden var statusRainMMfirstHour as Lang.Number = NEUTRAL;
  hidden var statusRainMMHour as Lang.Number = NEUTRAL;
  hidden var statusCondition as Lang.Number = NEUTRAL;
  hidden var statusWindSpeed as Lang.Number = NEUTRAL;
  hidden var statusWindGust as Lang.Number = NEUTRAL;
  hidden var statusDewpoint as Lang.Number = NEUTRAL;
  hidden var statusOWMAlert as Lang.Number = NEUTRAL;

  hidden var allClearUvi as Lang.Boolean = true;
  hidden var allClearPrecipitationChance as Lang.Boolean = true;
  hidden var allClearRainMMfirstHour as Lang.Boolean = true;
  hidden var allClearRainMMHour as Lang.Boolean = true;
  hidden var allClearCondition as Lang.Boolean = true;
  hidden var allClearWindSpeed as Lang.Boolean = true;
  hidden var allClearWindGust as Lang.Boolean = true;
  hidden var allClearDewpoint as Lang.Boolean = true;
  hidden var allClearOWMAlert as Lang.Boolean = true;

  function setAlertPrecipitationChance(value as Lang.Number) as Void {
    alertPrecipitationChance = value;
  }
  function setAlertUVi(value as Lang.Number) as Void {
    alertUvi = value;
  }
  function setAlertRainMMfirstHour(value as Lang.Float) as Void {
    alertRainMMfirstHour = value;
  }
  function setAlertRainMMHour(value as Lang.Float) as Void {
    alertRainMMHour = value;
  }
  //! is in beaufort
  function setAlertWindSpeed(value as Lang.Number) as Void {
    alertWindSpeed = value;
  }
  // level 1,2,3
  function setAlertWindGust(value as Lang.Number) as Void {
    alertWindGust = value;
  }
  function setAlertDewpoint(value as Lang.Number) as Void {
    alertDewpoint = value;
  }

  function infoUvi() as Lang.String {
    return Lang.format("alerthandler alertUvi[$1$] statusUvi[$2$] allClearUvi[$3$]", [
      alertUvi,
      statusUvi,
      allClearUvi,
    ]);
  }

  function infoPrecipitationChance() as Lang.String {
    return Lang.format("alerthandler alertPop[$1$] statusPop[$2$] allClearPop[$3$]", [
      alertPrecipitationChance,
      statusPrecipitationChance,
      allClearPrecipitationChance,
    ]);
  }
  //! alert flow:
  //!  level reached --> alert triggered (display/play alert) --> (handled
  //!  displayed alert) --> reset when level below alert

  function isAnyAlertTriggered() as Lang.Boolean {
    return (
      statusUvi == TRIGGERED ||
      statusPrecipitationChance == TRIGGERED ||
      statusRainMMfirstHour == TRIGGERED ||
      statusRainMMHour == TRIGGERED ||
      statusCondition == TRIGGERED ||
      statusWindSpeed == TRIGGERED ||
      statusWindGust == TRIGGERED ||
      statusDewpoint == TRIGGERED ||
      statusOWMAlert == TRIGGERED
    );
  }

  function hasAlertsHandled() as Lang.Boolean {
    return (
      statusUvi == HANDLED ||
      statusPrecipitationChance == HANDLED ||
      statusRainMMfirstHour == HANDLED ||
      statusRainMMHour == HANDLED ||
      statusCondition == HANDLED ||
      statusWindSpeed == HANDLED ||
      statusWindGust == HANDLED ||
      statusDewpoint == HANDLED ||
      statusOWMAlert == HANDLED
    );
  }

  function infoHandledShort() as Array<String> {
    var info = [] as Array<String>;
    if (statusUvi == HANDLED) {
      info.add("Uv");
    }
    if (statusPrecipitationChance == HANDLED) {
      info.add("R%");
    }
    if (statusRainMMfirstHour == HANDLED) {
      info.add("Rf");
    }
    if (statusRainMMHour == HANDLED) {
      info.add("R");
    }
    if (statusCondition == HANDLED) {
      info.add("C");
    }
    if (statusWindSpeed == HANDLED) {
      info.add("Ws");
    }
    if (statusWindGust == HANDLED) {
      info.add("Wg");
    }
    if (statusDewpoint == HANDLED) {
      info.add("Dp");
    }
    if (statusOWMAlert == HANDLED) {
      info.add("A");
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
      info = info + " Rf" + maxRainMMfirstHour.format("%d");
    }
    if (statusRainMMHour == HANDLED) {
      info = info + " R" + maxRainMMfirstHour.format("%d");
    }
    if (statusCondition == HANDLED) {
      info = info + " C";
    }
    if (statusWindSpeed == HANDLED) {
      var beaufort = $.windSpeedToBeaufort(maxWindSpeed);
      info = info + " Ws" + beaufort.format("%d");
    }
    if (statusWindGust == HANDLED) {
      info = info + " Wg" + maxWindGust.format("%d");
    }
    if (statusDewpoint == HANDLED) {
      info = info + " Dp" + maxDewpoint.format("%.1f");
    }
    if (statusOWMAlert == HANDLED) {
      info = info + " A";
    }
    return info;
  }

  function currentlyTriggeredHandled() as Void {
    if (statusUvi == TRIGGERED) {
      statusUvi = HANDLED;
    }
    if (statusPrecipitationChance == TRIGGERED) {
      statusPrecipitationChance = HANDLED;
    }
    if (statusRainMMfirstHour == TRIGGERED) {
      statusRainMMfirstHour = HANDLED;
    }
    if (statusRainMMHour == TRIGGERED) {
      statusRainMMHour = HANDLED;
    }
    if (statusCondition == TRIGGERED) {
      statusCondition = HANDLED;
    }
    if (statusWindSpeed == TRIGGERED) {
      statusWindSpeed = HANDLED;
    }
    if (statusWindGust == TRIGGERED) {
      statusWindGust = HANDLED;
    }
    if (statusDewpoint == TRIGGERED) {
      statusDewpoint = HANDLED;
    }
    if (statusOWMAlert == TRIGGERED) {
      statusOWMAlert = HANDLED;
    }
  }

  function resetStatus() as Void {
    statusPrecipitationChance = NEUTRAL;
    statusUvi = NEUTRAL;
    statusRainMMfirstHour = NEUTRAL;
    statusRainMMHour = NEUTRAL;
    statusRainMMHour = NEUTRAL;
    statusCondition = NEUTRAL;
    statusWindSpeed = NEUTRAL;
    statusWindGust = NEUTRAL;
    statusDewpoint = NEUTRAL;
    statusOWMAlert = NEUTRAL;

    maxPrecipitationChance = 0;
    maxUvi = 0.0;
    maxRainMMfirstHour = 0;
    maxRainMMHour = 0;
    maxWindSpeed = 0.0;
    maxWindGust = 0;
    maxDewpoint = 0.0;
  }

  function resetAllClear() as Void {
    allClearUvi = true;
    allClearPrecipitationChance = true;
    allClearRainMMfirstHour = true;
    allClearRainMMHour = true;
    allClearCondition = true;
    allClearWindSpeed = true;
    allClearWindGust = true;
    allClearDewpoint = true;
    allClearOWMAlert = true;
  }

  function checkStatus() as Void {
    // all clear again HANDLED -> NEUTRAL
    if (allClearUvi) {
      statusUvi = NEUTRAL;
    }
    if (allClearPrecipitationChance) {
      statusPrecipitationChance = NEUTRAL;
    }
    if (allClearRainMMfirstHour) {
      statusRainMMfirstHour = NEUTRAL;
    }
    if (allClearRainMMHour) {
      statusRainMMHour = NEUTRAL;
    }
    if (allClearCondition) {
      statusCondition = NEUTRAL;
    }
    if (allClearWindSpeed) {
      statusWindSpeed = NEUTRAL;
    }
    if (allClearWindGust) {
      statusWindGust = NEUTRAL;
    }
    if (allClearDewpoint) {
      statusDewpoint = NEUTRAL;
    }
    if (allClearOWMAlert) {
      statusOWMAlert = NEUTRAL;
    }
  }

  function processUvi(uvi as Lang.Float?) as Void {
    if (alertUvi <= 0 || uvi == null) {
      return;
    }
    maxUvi = $.max(maxUvi, uvi) as Float;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusUvi == NEUTRAL && uvi >= alertUvi) {
      statusUvi = TRIGGERED;
    }
    if (uvi >= alertUvi) {
      allClearUvi = false;
    }
  }

  function processPrecipitationChance(chance as Lang.Number?) as Void {
    if (chance == null) {
      return;
    }

    maxPrecipitationChance = $.max(maxPrecipitationChance, chance) as Number;

    if (alertPrecipitationChance <= 0) {
      return;
    }
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusPrecipitationChance == NEUTRAL && chance >= alertPrecipitationChance) {
      statusPrecipitationChance = TRIGGERED;
    }
    if (chance >= alertPrecipitationChance) {
      allClearPrecipitationChance = false;
    }
  }

  function processRainMMfirstHour(mm as Lang.Float?) as Void {
    if (alertRainMMfirstHour <= 0 || mm == null) {
      return;
    }

    maxRainMMfirstHour = $.max(maxRainMMfirstHour, mm) as Number;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusRainMMfirstHour == NEUTRAL && mm >= alertRainMMfirstHour) {
      statusRainMMfirstHour = TRIGGERED;
    }
    if (mm >= alertRainMMfirstHour) {
      allClearRainMMfirstHour = false;
    }
  }

  function processRainMMHour(mm as Lang.Float?) as Void {
    if (alertRainMMHour <= 0 || mm == null) {
      return;
    }

    maxRainMMHour = $.max(maxRainMMHour, mm) as Number;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusRainMMHour == NEUTRAL && mm >= alertRainMMHour) {
      statusRainMMfirstHour = TRIGGERED;
    }
    if (mm >= alertRainMMHour) {
      allClearRainMMHour = false;
    }
  }

  function processWeather(colorValue as Lang.Number?) as Void {
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusCondition == NEUTRAL && colorValue != CONDITION_NEUTRAL) {
      statusCondition = TRIGGERED;
    }
    if (colorValue != CONDITION_NEUTRAL) {
      allClearCondition = false;
    }
  }

  function processWindSpeed(windSpeedMs as Lang.Float?) as Void {
    if (alertWindSpeed <= 0 || windSpeedMs == null) {
      return;
    }
    maxWindSpeed = $.max(maxWindSpeed, windSpeedMs) as Float;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    var beaufort = $.windSpeedToBeaufort(windSpeedMs);
    if (statusWindSpeed == NEUTRAL && beaufort >= alertWindSpeed) {
      statusWindSpeed = TRIGGERED;
    }
    if (beaufort >= alertWindSpeed) {
      allClearWindSpeed = false;
    }
  }

  function processWindGust(windSpeedMs as Lang.Float?, windGustMs as Lang.Float?) as Void {
    if (alertWindGust <= 0 || windSpeedMs == null || windGustMs == null) {
      return;
    }
    var level = $.getWindGustLevel(windSpeedMs, windGustMs);    
    maxWindGust = $.max(maxWindGust, level) as Number;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusWindGust == NEUTRAL && level >= alertWindGust) {
      statusWindGust = TRIGGERED;
    }
    if (level >= alertWindGust) {
      allClearWindGust = false;
    }
  }
  function processDewpoint(dewPoint as Lang.Float?) as Void {
    if (alertDewpoint <= 0 || dewPoint == null) {
      return;
    }
    maxDewpoint = $.max(maxDewpoint, dewPoint) as Float;
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusDewpoint == NEUTRAL && dewPoint >= alertDewpoint) {
      statusDewpoint = TRIGGERED;
    }
    if (dewPoint >= alertDewpoint) {
      allClearDewpoint = false;
    }
  }

   function processOWMAlert(hasOWMAlert as Boolean) as Void {
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusOWMAlert == NEUTRAL && hasOWMAlert) {
      statusOWMAlert = TRIGGERED;
    }
    if (hasOWMAlert) {
      allClearCondition = false;
    }
  }
}

function getWindGustLevel(windSpeedMs as Lang.Float, windGustMs as Lang.Float) as Number {
  var windGustDiff = 0;
  var level = 0;
  if (windGustMs > 0) {
    windGustDiff = windGustMs - windSpeedMs;
    if (windGustDiff > 12.8) {
      level = 3;
    } else if (windGustDiff > 7.7) {
      level = 2;
    } else if (windGustDiff > 5.1) {
      level = 1;
    }
  }
  // System.println("gust: " + level)
  return level;
}
