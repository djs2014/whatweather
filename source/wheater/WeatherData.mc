import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
using WhatAppBase.Utils as Utils;

class WeatherData {
  var current as WeatherCurrent;
  var minutely as WeatherMinutely;
  var hourly as Lang.Array<WeatherHourly>;
  var lastUpdated as Time.Moment?;
  var changed as Boolean = false;

  function initialize(current as WeatherCurrent, minutely as WeatherMinutely, hourly as Lang.Array<WeatherHourly>, lastUpdated as Time.Moment?) {    
    self.current = current;
    self.minutely = minutely;
    self.hourly = hourly;
    self.lastUpdated = lastUpdated;    
    self.changed = false;
  }

  static function initEmpty() as WeatherData {
    var wd = new WeatherData(new WeatherCurrent(), new WeatherMinutely(), [] as Array<WeatherHourly>, Time.now());
    wd.setChanged(true);
    return wd;
  }

  function valid() as Lang.Boolean {
    return hourly.size() > 0;
  }

  function getObservationTime() as Time.Moment? {
    if (self.current == null) { return null; }
    return (self.current as WeatherCurrent).observationTime;
  }

  function setChanged(changed as Boolean) as Void {
    self.changed = changed;
  }
}

class WeatherCurrent {
  var lat as Lang.Double = 0.0d;
  var lon as Lang.Double = 0.0d;
  var observationLocationName as Lang.String = "";
  var observationTime as Time.Moment? = null;
  var forecastTime as Time.Moment? = null;
  var clouds as Lang.Number = 0; // %
  var precipitationChance as Lang.Number = 0; // %
  var precipitationChanceOther as Lang.Number = 0; // %
  var condition as Lang.Number = 0; 
  var conditionOther as Lang.Number = 0;
  var windBearing as Lang.Number? = null; // degrees
  var windSpeed as Lang.Float? = null; // m/sec
  var relativeHumidity as Lang.Number? = null; // %
  var temperature as Lang.Number? = null; // celcius
  var uvi as Lang.Float? = null;
  var pressure as Lang.Number? = null; // hPa
  var dewPoint as Lang.Float? = null; // celcius

  function getDewPoint() as Lang.Number? {
    if (dewPoint == null) { return null; }
    return (dewPoint as Float).toNumber();
  }
  function info() as Lang.String {
    return "WeatherCurrent:lat[" + lat + "]lon[" + lon + "]obsname[" +
           observationLocationName + "]obstime[" +
           Utils.getDateTimeString(observationTime) + "]time[" +
           Utils.getDateTimeString(forecastTime) + "]pop[" + precipitationChance +
           "]clouds[" + clouds + "]condition[" + condition + "]uvi[" + uvi + "]windBearing[" + windBearing +
           "]windSpeed[" + windSpeed + "]temperature[" + temperature +
           "]humidity[" + relativeHumidity + "]pressure[" + pressure + "]dewPoint[" + dewPoint + "]";
  }
}

class WeatherMinutely {
  var forecastTime as Time.Moment? = null;
  var pops as Array<Number> = [] as Array<Number>;
}

class WeatherHourly {
  var forecastTime as Time.Moment = Time.now();
  var clouds as Lang.Number = 0;
  var precipitationChance as Lang.Number = 0;
  var condition as Lang.Number = 0;
  var precipitationChanceOther as Lang.Number = 0; // @nD
  var conditionOther as Lang.Number = 0;
  var windBearing as Lang.Number? = null;
  var windSpeed as Lang.Float? = null;
  var relativeHumidity as Lang.Number? = null;
  var temperature as Lang.Number? = null;
  var uvi as Lang.Float? = null;
  var pressure as Lang.Number? = null; // hPa
  var dewPoint as Lang.Float? = null; // celcius

  function getDewPoint() as Lang.Number? {
    if (dewPoint == null) { return null; }
    return (dewPoint as Float).toNumber();
  }

  function info() as Lang.String {
    return "WeatherHourly:time[" + Utils.getDateTimeString(forecastTime) + "]pop[" +
           precipitationChance + "]clouds[" + clouds + "]condition[" +
           condition + "]uvi[" + uvi + "]windBearing[" +
           windBearing + "]windSpeed[" + windSpeed + "]temperature[" +
           temperature + "]humidity[" + relativeHumidity + "]pressure[" + pressure + "]dewPoint[" + dewPoint + "]";
  }
}