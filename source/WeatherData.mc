import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

class WeatherData {
  var current as CurrentConditions;
  var minutely as MinutelyForecast;
  var hourly as Lang.Array;
  var lastUpdated;  // as Time.Moment;

  function initialize() {
    current = new CurrentConditions();
    minutely = new MinutelyForecast();
    hourly = [];
    lastUpdated = new Time.Moment(0);
    System.println("WeatherData initialize");
  }
}

class CurrentConditions {
  var lat = 0;
  var lon = 0;
  var observationLocationName = "";
  var observationTime = null;
  var forecastTime = null;
  var clouds = 0;
  var precipitationChance = 0;
  var condition = 0;
  var windBearing = null;
  var windSpeed = null;
  var relativeHumidity = null;
  var temperature = null;
  var weather = "";
  var uvi = 0;

  function info() {
    return "Current:lat[" + lat + "]lon[" + lon + "]obsname[" +
           observationLocationName + "]obstime[" +
           getDateTimeString(observationTime) + "]time[" +
           getDateTimeString(forecastTime) + "]pop[" + precipitationChance +
           "]clouds[" + clouds + "]condition[" + condition + "]weather[" +
           weather + "]uvi[" + uvi + "]windBearing[" + windBearing +
           "]windSpeed[" + windSpeed + "]temperature[" + temperature +
           "]humidity[" + relativeHumidity + "]";
  }
}

class MinutelyForecast {
  var forecastTime;
  var pops = [];
}

class HourlyForecast {
  var forecastTime;
  var precipitationChance = 0;
  var clouds = 0;
  var condition = 0;
  var windBearing = null;
  var windSpeed = null;
  var relativeHumidity = null;
  var temperature = null;
  var weather = "";
  var uvi = 0;

  function info() {
    return "HourlyForecast:time[" + getDateTimeString(forecastTime) + "]pop[" +
           precipitationChance + "]clouds[" + clouds + "]condition[" +
           condition + "]weather[" + weather + "]uvi[" + uvi + "]windBearing[" +
           windBearing + "]windSpeed[" + windSpeed + "]temperature[" +
           temperature + "]humidity[" + relativeHumidity + "]";
  }
}