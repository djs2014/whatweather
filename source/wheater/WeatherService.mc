import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
using WhatAppBase.Utils as Utils;
using WhatAppBase.Colors as Colors;

enum WeatherSource { wsGarminFirst = 0, wsOWMFirst = 1, wsGarminOnly = 2, wsOWMOnly = 3 }

(:typecheck(disableBackgroundCheck))  
class WeatherService  {
    static function purgePastWeatherdata(data as WeatherData?) as WeatherData {
      if (data == null) { return WeatherData.initEmpty(); }
      var wData = data as WeatherData;
      var max = wData.hourly.size();
      var idxCurrent = -1;
      var forecast;
      for (var idx = 0; idx < max; idx += 1) {
        forecast = wData.hourly[idx] as WeatherHourly;
        if ($.DEBUG_DETAILS) { System.println("purgePastWeatherdata?: " + Utils.getDateTimeString(forecast.forecastTime)); }

        if (forecast.forecastTime.compare(Time.now()) < 0) {
          // Is a past forecast
          idxCurrent = idx;
          if ($.DEBUG_DETAILS) { System.println("purgePastWeatherdata past data!: " + Utils.getDateTimeString(forecast.forecastTime)); }
          wData.setChanged(true);
        }
      }
      if (idxCurrent > -1) {
        // Remove old entries, start after current hour
        forecast = wData.hourly[idxCurrent] as WeatherHourly;        
        wData.hourly = wData.hourly.slice(idxCurrent + 1, null);
        if (wData.current != null) {
          var current = wData.current as WeatherCurrent;
          current.forecastTime = forecast.forecastTime;
          current.clouds = forecast.clouds;
          current.precipitationChance = forecast.precipitationChance;
          current.condition = forecast.condition;
          current.windBearing = forecast.windBearing;
          current.windSpeed = forecast.windSpeed;
          current.relativeHumidity = forecast.relativeHumidity;
          current.temperature = forecast.temperature;
          current.uvi = forecast.uvi;
          current.weather = forecast.weather;
        }
      }
      return wData;
    }

    // For OWM first entry contains current data
    static function toWeatherData(data as Dictionary?, firstEntryIsCurrent as Boolean) as WeatherData {
      try {
        if (data == null) { return WeatherData.initEmpty(); }
        var bgData = data as Dictionary;

        var cc = new WeatherCurrent(); 
		    var hh = [] as Array<WeatherHourly>;
        var mm = new WeatherMinutely();

        var current = bgData["current"];
        var hourly = bgData["hourly"]; 
        var minutely = bgData["minutely"];
        
        if (current != null && hourly != null) {
          var bg_cc = current as Dictionary;
          var bg_hh = hourly as Array<Dictionary>;

          var currentEntry = current as Dictionary;
          if (firstEntryIsCurrent && bg_hh.size() > 0) { currentEntry = bg_hh[0]; }
          // First entry of hourly - > clouds + pop goes to current (it is the current hour) 
          cc.precipitationChance = ((Utils.getDictionaryValue(currentEntry, "pop", 0.0) as Float) * 100.0) as Number; 
          cc.forecastTime = new Time.Moment(Utils.getDictionaryValue(currentEntry, "dt", 0.0) as Number); 

          cc.lat = Utils.getDictionaryValue(bg_cc, "lat", 0.0d) as Double; 
          cc.lon = Utils.getDictionaryValue(bg_cc, "lon", 0.0d) as Double; 
          cc.observationLocationName = cc.lat + "," + cc.lon;
          cc.observationTime = new Time.Moment(Utils.getDictionaryValue(bg_cc, "dt", 0) as Number);
          
          cc.clouds = Utils.getDictionaryValue(bg_cc, "clouds", 0) as Number; 
          cc.condition = Utils.getDictionaryValue(bg_cc, "condition", 0) as Number;
          cc.windBearing = Utils.getDictionaryValue(bg_cc, "w_deg", 0) as Number;
          cc.windSpeed = Utils.getDictionaryValue(bg_cc, "w_s", 0) as Float; 
          cc.relativeHumidity = Utils.getDictionaryValue(bg_cc, "humid", 0) as Number;
          cc.temperature = Utils.getDictionaryValue(bg_cc, "temp", 0) as Number;           
          cc.uvi = Utils.getDictionaryValue(bg_cc, "uvi", 0.0) as Float;

          System.println("bgData Current: " + cc.info());   
        }

        if (hourly != null) {
          var bg_hh = hourly as Array<Dictionary>;
          var startIdx = 0;

          if (firstEntryIsCurrent) { startIdx = 1; }            	
          for (var i = startIdx; i < bg_hh.size(); i++) {
              var hf = new WeatherHourly();
              hf.forecastTime = new Time.Moment(Utils.getDictionaryValue(bg_hh[i], "dt", 0.0) as Number);  
              hf.clouds = Utils.getDictionaryValue(bg_hh[i], "clouds", 0) as Number;
              // OWM pop from o.o - 1
              hf.precipitationChance = ((Utils.getDictionaryValue(bg_hh[i], "pop", 0.0) as Float) * 100.0) as Number;
              hf.condition = Utils.getDictionaryValue(bg_hh[i], "condition", 0) as Number; 
              hf.windBearing = Utils.getDictionaryValue(bg_hh[i], "w_deg", 0) as Number;
              hf.windSpeed = Utils.getDictionaryValue(bg_hh[i], "w_s", 0) as Float; 
              hf.relativeHumidity = Utils.getDictionaryValue(bg_hh[i], "humid", 0) as Number;
              hf.temperature = Utils.getDictionaryValue(bg_hh[i], "temp", 0) as Number;                 
              hf.uvi = Utils.getDictionaryValue(bg_hh[i], "uvi", 0.0) as Float; 
              
              System.println("bgData Hourly: " + hf.info());   
              hh.add(hf);             
          }                
        }    

        if (minutely != null) {
          var bg_mm = minutely as Dictionary;
          mm.forecastTime = new Time.Moment(Utils.getDictionaryValue(bg_mm, "dt_start", 0.0) as Number);  
          var pops = bg_mm["pops"];
          if (pops != null) {
            var bg_pops = pops as Array<Number>;
            for (var i = 0; i < bg_pops.size(); i++) {
              mm.pops.add(bg_pops[i]);
            }
            System.println("Size of minutely: " + mm.pops.size()); 
          }
        }

        return new WeatherData(cc, mm, hh, cc.observationTime);     
      } catch (ex) {
        ex.printStackTrace();
        return WeatherData.initEmpty();
      }       
    }

    static function mergeWeather(garminData as WeatherData, bgData as WeatherData, source as WeatherSource) as WeatherData {
      try {
        var wData;
        switch(source) {
          case wsGarminFirst:
            wData = garminData;
            break;
          case wsOWMFirst:
            wData = bgData;
            break;
          case wsGarminOnly:
            return garminData;          
          case wsOWMOnly:
            return bgData;          
        }

        if (garminData.hourly.size() == 0) {
          // No garmin data
          return bgData;
        }
        if (bgData.hourly.size() == 0) {
          // No bgData data
          return garminData;
        }
        // var current = bgData.current;
        // var hourly = bgData.hourly;
        // var minutely = bgData.minutely;

        // @@TODO Only merge if changed 


        
        switch(source) {
          case wsGarminFirst:
            wData.current.precipitationChanceOther = bgData.current.precipitationChance; 
            wData.current.conditionOther = bgData.current.condition;             
            wData.current.uvi = bgData.current.uvi;
            wData.current.clouds = bgData.current.clouds;  
            wData.minutely = bgData.minutely;    
           break;
          case wsOWMFirst:
            wData.current.precipitationChanceOther = garminData.current.precipitationChance; 
            // garminData.current.precipitationChance = current.precipitationChance; 
            wData.current.conditionOther = garminData.current.condition; 
            // garminData.current.condition = current.condition; 
           break;
          // case wsGarminOnly:
          //   garminData.current.precipitationChanceOther = 0; 
          //   garminData.current.conditionOther = 0;  
          //  break;
          // case wsOWMOnly:
          //   garminData.current.precipitationChance = current.precipitationChance; 
          //   garminData.current.precipitationChanceOther = 0; 
          //   garminData.current.condition = current.condition; 
          //   garminData.current.conditionOther = 0; 
          //  break; 
        }

        // We assume start hour is for both set the same! Past hours will be purged.
        var maxH = garminData.hourly.size();
        var maxBgH = bgData.hourly.size();          
        for (var h = 0; h < maxH; h += 1) {
          if (h < maxBgH) {
            // garminData.hourly[h].precipitationChanceOther = 0;
            switch(source) {
              case wsGarminFirst:
                wData.hourly[h].precipitationChanceOther = bgData.hourly[h].precipitationChance; 
                wData.hourly[h].conditionOther = bgData.hourly[h].condition; 
                wData.hourly[h].uvi =  bgData.hourly[h].uvi;
                wData.hourly[h].clouds =  bgData.hourly[h].clouds;
                break;
              case wsOWMFirst:
                wData.hourly[h].precipitationChanceOther = garminData.hourly[h].precipitationChance; 
                // wData.hourly[h].precipitationChance = bgData.hourly[h].precipitationChance; 
                wData.hourly[h].conditionOther = garminData.hourly[h].condition; 
                // wData.hourly[h].condition = bgData.hourly[h].condition; 
                break;
              // case wsGarminOnly:
              //   garminData.hourly[h].precipitationChanceOther = 0; 
              //   garminData.hourly[h].conditionOther = 0;  
              // break;
              // case wsOWMOnly:
              //   garminData.hourly[h].precipitationChance = hourly[h].precipitationChance; 
              //   garminData.hourly[h].precipitationChanceOther = 0; 
              //   garminData.hourly[h].condition = hourly[h].condition; 
              //   garminData.hourly[h].conditionOther = 0; 
              // break; 
            }
          }
        }
            
        
        return wData;      
      } catch (ex) {
        ex.printStackTrace();
        return WeatherData.initEmpty();
      }        
    }
}