import Toybox.Lang;
import Toybox.System;

class AlertHandler {
  hidden var alertUvi = 0;
  hidden var alertPrecipitationChance = 0;
  hidden var alertRainMMfirstHour = 0;
  hidden var alertWindSpeed = 0;

  var maxPrecipitationChance = 0;

  hidden var WEATHER_NEUTRAL = 0x00AAFF;  // COLOR_BLUE

  hidden const NEUTRAL = 0;
  hidden const TRIGGERED = 1;
  hidden const HANDLED = 2;

  hidden var statusUvi = NEUTRAL;
  hidden var statusPrecipitationChance = NEUTRAL;
  hidden var statusRainMMfirstHour = NEUTRAL;
  hidden var statusWeather = NEUTRAL;
  hidden var statusWindSpeed = NEUTRAL;
  hidden var allClearUvi = true;
  hidden var allClearPrecipitationChance = true;
  hidden var allClearRainMMfirstHour = true;
  hidden var allClearWeather = true;
  hidden var allClearWindSpeed = true;

  function setAlertPrecipitationChance(value) {
    alertPrecipitationChance = value;
  }

  function setAlertUVi(value) { alertUvi = value; }

  function setAlertRainMMfirstHour(value) { alertRainMMfirstHour = value; }

  //! is in beaufort

  function setAlertWindSpeed(value) { alertWindSpeed = value; }

  function infoUvi() {
    return Lang.format(
        "alerthandler alertUvi[$1$] statusUvi[$2$] allClearUvi[$3$]",
        [ alertUvi, statusUvi, allClearUvi ]);
  }

  function infoPrecipitationChance() {
    return Lang.format(
        "alerthandler alertPop[$1$] statusPop[$2$] allClearPop[$3$]", [
          alertPrecipitationChance, statusPrecipitationChance,
          allClearPrecipitationChance
        ]);
  }
  //! alert flow:
  //!  level reached --> alert triggered (display/play alert) --> (handled
  //!  displayed alert) --> reset when level below alert

  function isAnyAlertTriggered() {
    return (statusUvi == TRIGGERED) ||
           (statusPrecipitationChance == TRIGGERED) ||
           (statusRainMMfirstHour == TRIGGERED) ||
           (statusWeather == TRIGGERED) || (statusWindSpeed == TRIGGERED);
  }

  function infoHandled() {
    var info = "";
    if (statusUvi == HANDLED) {
      info = info + "U ";
    }
    if (statusPrecipitationChance == HANDLED) {
      info = info + "R% ";
    }
    if (statusRainMMfirstHour == HANDLED) {
      info = info + "R ";
    }
    if (statusWeather == HANDLED) {
      info = info + "W ";
    }
    if (statusWindSpeed == HANDLED) {
      info = info + "WS ";
    }
    return info;
  }

  function currentlyTriggeredHandled() {
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

  function resetStatus() {
    statusPrecipitationChance = NEUTRAL;
    statusUvi = NEUTRAL;
    statusRainMMfirstHour = NEUTRAL;
    statusWeather = NEUTRAL;
    statusWindSpeed = NEUTRAL;
  }

  function checkStatus() {
    maxPrecipitationChance = 0;
    if (allClearUvi) {
      statusUvi = NEUTRAL;
      allClearUvi = false;
    }
    if (allClearPrecipitationChance) {
      statusPrecipitationChance = NEUTRAL;
      allClearPrecipitationChance = false;
    }
    if (allClearRainMMfirstHour) {
      statusRainMMfirstHour = NEUTRAL;
      allClearRainMMfirstHour = false;
    }
    if (allClearWeather) {
      statusWeather = NEUTRAL;
      allClearWeather = false;
    }
    if (allClearWindSpeed) {
      statusWindSpeed = NEUTRAL;
      allClearWindSpeed = false;
    }
  }

  function processUvi(uvi) {
    if (alertUvi <= 0 || uvi == null) {
      return;
    }
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusUvi == NEUTRAL && uvi >= alertUvi) {
      statusUvi = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearUvi = allClearUvi && (statusUvi == HANDLED && uvi < alertUvi);
  }

  function processPrecipitationChance(chance) {
    if (chance == null) {
      return;
    }
    if (chance >= maxPrecipitationChance) {
      maxPrecipitationChance = chance;
    }

    if (alertPrecipitationChance <= 0) {
      return;
    }
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusPrecipitationChance == NEUTRAL &&
        chance >= alertPrecipitationChance) {
      statusPrecipitationChance = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearPrecipitationChance =
        allClearPrecipitationChance && (statusPrecipitationChance == HANDLED &&
                                        chance < alertPrecipitationChance);
  }

  function processRainMMfirstHour(mm) {
    if (alertRainMMfirstHour <= 0 || mm == null) {
      return;
    }
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusRainMMfirstHour == NEUTRAL && mm >= alertRainMMfirstHour) {
      statusRainMMfirstHour = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearRainMMfirstHour =
        allClearRainMMfirstHour &&
        (statusRainMMfirstHour == HANDLED && mm < alertRainMMfirstHour);
  }

  function processWeather(colorValue) {
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    if (statusWeather == NEUTRAL && colorValue != WEATHER_NEUTRAL) {
      statusWeather = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearWeather = allClearWeather && (statusWeather == HANDLED &&
                                          colorValue != WEATHER_NEUTRAL);
  }

  function processWindSpeed(windSpeedMs) {
    if (alertWindSpeed <= 0 || windSpeedMs == null) {
      return;
    }
    // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
    var beaufort = windSpeedToBeaufort(windSpeedMs);
    if (statusWindSpeed == NEUTRAL && beaufort >= alertWindSpeed) {
      statusWindSpeed = TRIGGERED;
    }

    // all clear again HANDLED -> NEUTRAL
    allClearWindSpeed = allClearWindSpeed && (statusWindSpeed == HANDLED &&
                                              windSpeedMs < alertWindSpeed);
  }
}