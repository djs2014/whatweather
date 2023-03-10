import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
using WhatAppBase.Utils as Utils;

// class GarminWeather {
  function getLatestGarminWeather() as WeatherData { 
    var WEATHER_CONDITION_UNKNOWN = 53;
    try {
      var garCurrent = Weather.getCurrentConditions();
      if (garCurrent == null) { return emptyWeatherData(); }
    
      var cc = new WeatherCurrent();
      cc.precipitationChance = Utils.getNumericValue(garCurrent.precipitationChance, 0) as Lang.Number;
      cc.forecastTime = null;  //@@ needed?

      var position = garCurrent.observationLocationPosition;
      if (position != null) {
        var location = position.toDegrees();
        cc.lat = Utils.getNumericValue(location[0], 0.0d) as Lang.Double;
        cc.lon = Utils.getNumericValue(location[1], 0.0d) as Lang.Double;
      }
      cc.observationLocationName = Utils.getStringValue(garCurrent.observationLocationName, "") as Lang.String;
      // Skip after first ,
      var comma = cc.observationLocationName.find(",");
      if (comma != null) {
        var onlyName = (cc.observationLocationName as Lang.String).substring(0, comma);
        if (onlyName != null) {
          cc.observationLocationName = onlyName as Lang.String;
        }
      }

      cc.observationTime = garCurrent.observationTime;
      cc.clouds = 0;    // Not available
      cc.uvi = null;    // Not available
      cc.condition = Utils.getNumericValue(garCurrent.condition, WEATHER_CONDITION_UNKNOWN) as Lang.Number;
      cc.windBearing = garCurrent.windBearing;
      cc.windSpeed = garCurrent.windSpeed;
      cc.temperature = garCurrent.temperature;
      cc.relativeHumidity = garCurrent.relativeHumidity;      
      cc.dewPoint = calculateDewpoint(cc.temperature,cc.relativeHumidity);

      if (DEBUG_DETAILS) {
        System.println("Gar Current: " + cc.info());
      }

      var mm = new WeatherMinutely();  // Not available for Garmin

      var hh = [] as Array<WeatherHourly>;
      var garHourlyForecast = Weather.getHourlyForecast();
      if (garHourlyForecast != null) {
        for (var idx = 0; idx < garHourlyForecast.size(); idx += 1) {
          var garForecast = garHourlyForecast[idx] as Weather.HourlyForecast;
          if (garForecast.forecastTime != null) {
            var hf = new WeatherHourly();
            hf.forecastTime = garForecast.forecastTime as Time.Moment;
            hf.clouds = 0;  // Not availablelastUpdateddity;
            hf.uvi = null;  // Not available
            hf.precipitationChance = Utils.getNumericValue(garForecast.precipitationChance, 0) as Lang.Number;
            hf.condition = Utils.getNumericValue(garForecast.condition as Lang.Number?, WEATHER_CONDITION_UNKNOWN) as Lang.Number;            
            hf.windBearing = garForecast.windBearing;
            hf.windSpeed = garForecast.windSpeed;
            hf.temperature = garForecast.temperature;
            hf.relativeHumidity = garForecast.relativeHumidity;
            hf.dewPoint = calculateDewpoint(hf.temperature,hf.relativeHumidity);
            if (DEBUG_DETAILS) { System.println("Gar Hourly: " + hf.info()); }
            hh.add(hf);
          }
        }
      }

      return new WeatherData(cc, mm, hh, cc.observationTime);      
    } catch (ex) {
      ex.printStackTrace();
      return emptyWeatherData();
    }
  }

  function calculateDewpoint(temperatureCelcius as Number?, relativeHumidity as Number?) as Float {
    if (temperatureCelcius == null || relativeHumidity == null) { return 0.0; }
    // https://learnmetrics.com/dew-point-calculator-chart-formula/      
    return (temperatureCelcius as Number) - ((100 - (relativeHumidity as Number)) / 5.0);
  }
//}
