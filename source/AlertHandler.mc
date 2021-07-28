import Toybox.Lang;
import Toybox.System;

class AlertHandler {
    hidden var alertUvi = 0;
    hidden var alertPrecipitationChance = 0;
    hidden var alertRainMMfirstHour = 0;
    
    public var maxPrecipitationChance = 0;

    hidden var WEATHER_NEUTRAL = 0x00AAFF; // COLOR_BLUE

    hidden const NEUTRAL = 0;
    hidden const TRIGGERED = 1;
    hidden const HANDLED = 2;

    hidden var statusUvi = NEUTRAL;
    hidden var statusPrecipitationChance = NEUTRAL;
    hidden var statusRainMMfirstHour = NEUTRAL;
    hidden var statusWeather = NEUTRAL;
    hidden var allClearUvi = true;
    hidden var allClearPrecipitationChance = true;
    hidden var allClearRainMMfirstHour = true;
    hidden var allClearWeather = true;

    public const ALERT_UVI = "Uv";
    public const ALERT_PRECIPITATION_CHANCE = "P%";
    public const ALERT_RAIN_FIRST_HOUR = "Rain";
    public const ALERT_WEATHER = "Weather"; // @@ type of weather

    public function setAlertPrecipitationChance(value) {
        alertPrecipitationChance = value; 
    }

    public function setAlertUVi(value) {
        alertUvi = value;
    }

    public function setAlertRainMMfirstHour(value) {
        alertRainMMfirstHour = value;
    }

    public function infoUvi() {
        return Lang.format("alerthandler alertUvi[$1$] statusUvi[$2$] allClearUvi[$3$]",[alertUvi, statusUvi, allClearUvi]);
    }
    public function infoPrecipitationChance() {
        return Lang.format("alerthandler alertPop[$1$] statusPop[$2$] allClearPop[$3$]",[alertPrecipitationChance, statusPrecipitationChance, allClearPrecipitationChance]);
    }
    //! alert flow:
    //!  level reached --> alert triggered (display/play alert) --> (handled displayed alert) --> reset when level below alert
    public function isAnyAlertTriggered() {        
        return (statusUvi == TRIGGERED) || (statusPrecipitationChance == TRIGGERED) 
        || (statusRainMMfirstHour == TRIGGERED) ||(statusWeather == TRIGGERED);         
    }

    public function infoHandled() {
        var info = "";
        if (statusUvi == HANDLED) {info = info + "U ";}   
        if (statusPrecipitationChance == HANDLED) {info = info + "P ";}   
        if (statusRainMMfirstHour == HANDLED) {info = info + "R ";}   
        if (statusWeather == HANDLED) {info = info + "W ";}   
        return info;        
    }

    public function currentlyTriggeredHandled() {
        if (statusUvi == TRIGGERED) {statusUvi = HANDLED; allClearUvi = true;}
        if (statusPrecipitationChance == TRIGGERED) {statusPrecipitationChance = HANDLED; allClearPrecipitationChance = true;}
        if (statusRainMMfirstHour == TRIGGERED) {statusRainMMfirstHour = HANDLED; allClearRainMMfirstHour = true;}
        if (statusWeather == TRIGGERED) {statusWeather = HANDLED; allClearWeather = true;}        
    }

    public function resetStatus() {
        statusPrecipitationChance = NEUTRAL;
        statusUvi = NEUTRAL;
        statusRainMMfirstHour = NEUTRAL;
        statusWeather = NEUTRAL;
    }

    public function checkStatus() {
        maxPrecipitationChance = 0;
        if (allClearUvi) {statusUvi = NEUTRAL; allClearUvi = false;}
        if (allClearPrecipitationChance) {statusPrecipitationChance = NEUTRAL; allClearPrecipitationChance = false;}
        if (allClearRainMMfirstHour) {statusRainMMfirstHour = NEUTRAL; allClearRainMMfirstHour = false;}
        if (allClearWeather) {statusWeather = NEUTRAL; allClearWeather = false;}
    }

    public function processUvi(uvi) {
        if (alertUvi <= 0 || uvi == null) {return;}
        // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
        if (statusUvi == NEUTRAL && uvi > alertUvi) { statusUvi = TRIGGERED;}

        // all clear again HANDLED -> NEUTRAL
        allClearUvi = allClearUvi && (statusUvi == HANDLED && uvi <= alertUvi);
    }

    public function processPrecipitationChance(chance) {
        if (chance == null) {return;}
        if (chance > maxPrecipitationChance) {maxPrecipitationChance = chance;}

        if (alertPrecipitationChance <= 0) {return;}
        // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
        if (statusPrecipitationChance == NEUTRAL && chance > alertPrecipitationChance) { statusPrecipitationChance = TRIGGERED;}

        // all clear again HANDLED -> NEUTRAL
        allClearPrecipitationChance = allClearPrecipitationChance && (statusPrecipitationChance == HANDLED && chance <= alertPrecipitationChance);
    }

    public function processRainMMfirstHour(mm) {
        if (alertRainMMfirstHour <= 0 || mm == null) {return;}
        // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
        if (statusRainMMfirstHour == NEUTRAL && mm > alertRainMMfirstHour) { statusRainMMfirstHour = TRIGGERED;}

        // all clear again HANDLED -> NEUTRAL
        allClearRainMMfirstHour = allClearRainMMfirstHour && (statusRainMMfirstHour == HANDLED && mm <= alertRainMMfirstHour);
    }

    public function processWeather(colorValue) {
        // level reached NEUTRAL -> TRIGGERED  (skip if already HANDLED)
        if (statusWeather == NEUTRAL && colorValue != WEATHER_NEUTRAL) { statusWeather = TRIGGERED;}

        // all clear again HANDLED -> NEUTRAL
        allClearWeather = allClearWeather && (statusWeather == HANDLED && colorValue != WEATHER_NEUTRAL);
    }

}