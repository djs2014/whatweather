import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
using WhatAppBase.Utils as Utils;

class WeatherBG  {
    static function purgePastWeatherdata(data as WeatherData?) as WeatherData {
      if (data == null || data.hourly == null) { return data; }
      var max = data.hourly.size();
      var idxCurrent = -1;
      var forecast;
      for (var idx = 0; idx < max; idx += 1) {
        forecast = data.hourly[idx] as WeatherHourly;
        if ($.DEBUG_DETAILS) { System.println("purgePastWeatherdata?: " + Utils.getDateTimeString(forecast.forecastTime)); }

        if (forecast.forecastTime.compare(Time.now()) < 0) {
          // Is a past forecast
          idxCurrent = idx;
          if ($.DEBUG_DETAILS) { System.println("purgePastWeatherdata past data!: " + Utils.getDateTimeString(forecast.forecastTime)); }
        }
      }
      if (idxCurrent > -1) {
        // Remove old entries, start after current hour
        forecast = data.hourly[idxCurrent] as WeatherHourly;        
        data.hourly = data.hourly.slice(idxCurrent + 1, null);
        if (data.current != null) {
          var current = data.current as WeatherCurrent;
          current.forecastTime = forecast.forecastTime;
          current.clouds = forecast.clouds;
          current.precipitationChance = forecast.precipitationChance;
          current.condition = forecast.condition;
          current.windBearing = forecast.windBearing;
          current.windSpeed = forecast.windSpeed;
          current.relativeHumidity = forecast.relativeHumidity;
          current.temperature = forecast.temperature;
          current.uvi = forecast.uvi;
          // current.weather = forecast.weather;
        }
      }
      return data;
    }

    // For OWM first entry contains current data
    static function toWeatherData(bgData as Dictionary, firstEntryIsCurrent as Boolean) as WeatherData {
      try {
        if (bgData == null) { return new WeatherData(null, null, null, Time.now()); }

        var cc = new WeatherCurrent(); 
		    var hh = [];
        var mm = new WeatherMinutely();

        var current = bgData["current"];
        var hourly = bgData["hourly"];
        var minutely = bgData["minutely"];
        
        if (current != null && hourly != null) {
          if (firstEntryIsCurrent && hourly.size() > 0) {			
            // First entry of hourly - > clouds + pop goes to current (it is the current hour) // @@ TODO in node proxy?
            cc.precipitationChance = ((Utils.getDictionaryValue(hourly[0], "pop", 0.0) as Float) * 100.0) as Number; 
            cc.forecastTime = new Time.Moment(Utils.getDictionaryValue(hourly[0], "dt", 0.0) as Number); 
          } else {
            cc.precipitationChance = ((Utils.getDictionaryValue(current, "pop", 0.0) as Float) * 100.0) as Number; 
            cc.forecastTime = new Time.Moment(Utils.getDictionaryValue(current, "dt", 0.0) as Number); 
          }
          cc.lat = Utils.getDictionaryValue(current, "lat", 0.0d) as Double; 
          cc.lon = Utils.getDictionaryValue(current, "lon", 0.0d) as Double; 
          cc.observationLocationName = cc.lat + "," + cc.lon;
          cc.observationTime = new Time.Moment(Utils.getDictionaryValue(current, "dt", 0) as Number);
          
          cc.clouds = Utils.getDictionaryValue(current, "clouds", 0) as Number; 
          cc.condition = Utils.getDictionaryValue(current, "weather", 0) as Number;
          //         var windBearing as Lang.Number? = null;
          // var windSpeed as Lang.Float? = null;
          // var relativeHumidity as Lang.Number? = null;
          // var temperature as Lang.Number? = null;
          // var weather as Lang.String = "";
          cc.uvi = Utils.getDictionaryValue(current, "uvi", 0.0) as Float;
          // -> not needed cc.weather = getValue(current["weather"], "");
          System.println("bgData Current: " + cc.info());   
        }

        if (hourly != null) {
          var startIdx = 0;
          if (firstEntryIsCurrent) { startIdx = 1; }
            	// Skip first entry, is current @@ -> check it
            for (var i = startIdx; i < hourly.size(); i++) {
                var hf = new WeatherHourly();
                hf.forecastTime = new Time.Moment(Utils.getDictionaryValue(hourly[i], "dt", 0.0) as Number);  
                hf.clouds = Utils.getDictionaryValue(hourly[i], "clouds", 0) as Number;
                // OWM pop from o.o - 1
                hf.precipitationChance = ((Utils.getDictionaryValue(hourly[i], "pop", 0.0) as Float) * 100.0) as Number;
                hf.condition = Utils.getDictionaryValue(hourly[i], "weather", 0) as Number; 
                //hf.weather = getValue(current["weather"], "");
                hf.uvi = Utils.getDictionaryValue(hourly[i], "uvi", 0.0) as Float; 
                
                System.println("OWM Hourly: " + hf.info());   
                hh.add(hf);             
            }                
          }    

          if (minutely != null) {
            mm.forecastTime = new Time.Moment(Utils.getDictionaryValue(minutely, "dt_start", 0.0) as Number);  
            var pops = minutely["pops"];
            if (pops != null) {
              for (var i = 0; i < pops.size(); i++) {
                mm.pops.add(pops[i]);
              }
              System.println("Size of minutely: " + mm.pops.size()); 
            }
          }

          return new WeatherData(cc, mm, hh, cc.observationTime);     
      } catch (ex) {
        ex.printStackTrace();
        return new WeatherData(null, null, null, Time.now());
      }       
    }

    static function mergeWeather(garminData as WeatherData, bgData as WeatherData) as WeatherData {
      try {
        if (bgData == null) { return garminData; }

        var current = bgData.current;
        var hourly = bgData.hourly;
        var minutely = bgData.minutely;

        // @@TODO Only merge if changed 


        // Add uvi data
        // Add cloud data
        // Add minutes
        // Prefer Pop / Weather 

        if (current != null) {
          if (garminData.current == null) { garminData.current = new WeatherCurrent(); }
            // @@ check valid time
          garminData.current.uvi = bgData.current.uvi;
          garminData.current.clouds = bgData.current.clouds;
        }

        if (hourly != null) {
          if (garminData.hourly == null) { garminData.hourly = []; }
          // We assume start hour is for both set the same! Past hours will be purged.
          var maxH = garminData.hourly.size();
          var maxBgH = hourly.size();
            
          for (var h = 0; h < maxH; h += 1) {
            if (h < maxBgH) {
              garminData.hourly[h].uvi =  hourly[h].uvi;
              garminData.hourly[h].clouds =  hourly[h].clouds;
            }
          }

        }
            
        return garminData;      
      } catch (ex) {
        ex.printStackTrace();
        return new WeatherData(null, null, null, Time.now());
      }        
    }
}