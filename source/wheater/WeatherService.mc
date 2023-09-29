import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

using WhatAppBase.Colors as Colors;

(:background)
enum WeatherSource { wsGarminFirst = 0, wsOWMFirst = 1, wsGarminOnly = 2, wsOWMOnly = 3 }

(:background)
enum apiVersion { owmOneCall25 = 0, owmOneCall30 = 1 }

(:typecheck(disableBackgroundCheck))  
//class WeatherService  {
    function purgePastWeatherdata(data as WeatherData?) as WeatherData {
      if (data == null) { return emptyWeatherData(); }
      var wData = data as WeatherData;
      var max = wData.hourly.size();
      var idxCurrent = -1;
      var forecast;
      for (var idx = 0; idx < max; idx += 1) {
        forecast = wData.hourly[idx] as WeatherHourly;
        if ($.DEBUG_DETAILS) { System.println("purgePastWeatherdata?: " + $.getDateTimeString(forecast.forecastTime)); }

        if (forecast.forecastTime.compare(Time.now()) < 0) {
          // Is a past forecast
          idxCurrent = idx;
          if ($.DEBUG_DETAILS) { System.println("purgePastWeatherdata past data!: " + $.getDateTimeString(forecast.forecastTime)); }
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
        }
      }
      return wData;
    }

    // For OWM first entry contains current data
    (:typecheck(disableBackgroundCheck))  
    function toWeatherData(data as Dictionary?, firstEntryIsCurrent as Boolean) as WeatherData {
      try {
        if (data == null) { return emptyWeatherData(); }
        var bgData = data as Dictionary;

        var cc = new WeatherCurrent(); 
		    var hh = [] as Array<WeatherHourly>;
        var mm = new WeatherMinutely();
        var al = [] as Array<WeatherAlert>;

        var current = bgData["current"];
        var hourly = bgData["hourly"]; 
        var minutely = bgData["minutely"];
        var alerts = bgData["alerts"];

        if (current != null && hourly != null) {
          var bg_cc = current as Dictionary;
          var bg_hh = hourly as Array<Array<Numeric>>;

          cc.lat = ($.getDictionaryValue(bg_cc, "lat", 0.0d) as Double).toDouble();
          cc.lon = ($.getDictionaryValue(bg_cc, "lon", 0.0d) as Double).toDouble();
          cc.observationLocationName = cc.lat + "," + cc.lon;
          cc.observationTime = new Time.Moment($.getDictionaryValue(bg_cc, "dt", 0) as Number);

          var carr = $.getDictionaryValue(bg_cc, "data", [] as Array<Numeric>) as Array<Numeric>;                   
          var firstHour = carr;
          if (firstEntryIsCurrent && bg_hh.size() > 0) { firstHour = bg_hh[0] as Array<Numeric>; }
          // First entry of hourly - > clouds + pop goes to current (it is the current hour) 
          // @@ todo, fix proxy to get pop value from daily
          cc.forecastTime = new Time.Moment(($.getNumericValue(firstHour[0], 0.0) as Number).toNumber()); 
          cc.clouds = ($.getNumericValue(firstHour[1], 0) as Number).toNumber(); 
          cc.precipitationChance = (($.getNumericValue(firstHour[2], 0.0) as Float) * 100.0).toNumber(); 
          
          cc.condition = ($.getNumericValue(carr[3], 0) as Number).toNumber();
          cc.uvi = ($.getNumericValue(carr[4], 0.0) as Float).toFloat();
          cc.windSpeed = ($.getNumericValue(carr[5], 0) as Float).toFloat(); 
          cc.windBearing = ($.getNumericValue(carr[6], 0) as Number).toNumber();
          cc.temperature = ($.getNumericValue(carr[7], 0) as Number).toNumber(); // as Float;
          cc.pressure = ($.getNumericValue(carr[8], 0) as Number).toNumber();
          cc.relativeHumidity = ($.getNumericValue(carr[9], 0) as Number).toNumber();
          cc.dewPoint = ($.getNumericValue(carr[10], 0.0) as Float).toFloat();
          cc.rain1hr= ($.getNumericValue(carr[11], 0.0) as Float).toFloat();
          cc.snow1hr= ($.getNumericValue(carr[12], 0.0) as Float).toFloat();

          System.println("bgData Current: " + cc.info());   
        }

        if (hourly != null) {
          // there are only values in array to compress the payload
          var bg_hh = hourly as Array<Array>;
          var startIdx = 0;

          if (firstEntryIsCurrent) { startIdx = 1; }            	
          for (var i = startIdx; i < bg_hh.size(); i++) {
              var hf = new WeatherHourly();
              var arr = bg_hh[i] as Array<Numeric>;
              hf.forecastTime = new Time.Moment(($.getNumericValue(arr[0], 0) as Number).toNumber());  
              hf.clouds = ($.getNumericValue(arr[1] , 0) as Number).toNumber();
              // OWM pop from o.o - 1
              hf.precipitationChance = (($.getNumericValue(arr[2], 0.0) as Float) * 100.0).toNumber();
              hf.condition = ($.getNumericValue(arr[3], 0) as Number).toNumber(); 
              hf.uvi = ($.getNumericValue(arr[4], 0.0) as Float).toFloat(); 
              hf.windSpeed = ($.getNumericValue(arr[5], 0) as Float).toFloat();
              hf.windBearing = ($.getNumericValue(arr[6], 0) as Number).toNumber();
              hf.temperature = ($.getNumericValue(arr[7], 0) as Number).toNumber();                 
              hf.pressure = ($.getNumericValue(arr[8], 0) as Number).toNumber();
              hf.relativeHumidity = ($.getNumericValue(arr[9], 0) as Number).toNumber();
              hf.dewPoint = ($.getNumericValue(arr[10], 0.0) as Float).toFloat();
              hf.rain1hr= ($.getNumericValue(arr[11], 0.0) as Float).toFloat();
              hf.snow1hr= ($.getNumericValue(arr[12], 0.0) as Float).toFloat();

              System.println("bgData Hourly: " + hf.info());   
              hh.add(hf);             
          }                
        }    

        if (minutely != null) {
          var bg_mm = minutely as Dictionary;
          mm.forecastTime = new Time.Moment($.getDictionaryValue(bg_mm, "dt_start", 0.0) as Number);  
          mm.max = $.getDictionaryValue(bg_mm, "max", 0.0) as Float;
          var pops = bg_mm["pops"];
          if (pops != null) {
            var bg_pops = pops as Array<Float>;
            for (var i = 0; i < bg_pops.size(); i++) {
              mm.pops.add(bg_pops[i] as Float);
            }
            System.println("Size of minutely: " + mm.pops.size()); 
          }
        }

        if (alerts != null) {
          var bg_al = alerts as Array<Array>;
          for (var i = 0; i < bg_al.size(); i++) {
              var wal = new WeatherAlert();
              var warr = bg_al[i] as Array<Numeric or String>;
              wal.event = $.getStringValue(warr[0] as String, "") as String;
              wal.start = new Time.Moment(($.getNumericValue(warr[1] as Number, 0.0) as Number).toNumber());  
              wal.end = new Time.Moment(($.getNumericValue(warr[2] as Number, 0.0) as Number).toNumber());  
              wal.description = $.getStringValue(warr[3] as String, "") as String;
              System.println("bgData Alert: " + wal.info());   
              al.add(wal); 
          }
        }
        var wd = new WeatherData(cc, mm, hh, al, cc.observationTime);     
        wd.setChanged(true);
        return wd;
      } catch (ex) {
        ex.printStackTrace();
        return emptyWeatherData();
      }       
    }
    (:typecheck(disableBackgroundCheck))  
    function mergeWeatherData(garminData as WeatherData, bgData as WeatherData, source as WeatherSource) as WeatherData {
      try {
        var wData = garminData;
        switch(source) {
          case wsGarminFirst:           
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
        // @@TODO Only merge if changed 


        
        switch(source) {
          case wsGarminFirst:
            wData.current.precipitationChanceOther = bgData.current.precipitationChance; 
            wData.current.conditionOther = bgData.current.condition; 
            if (wData.current.uvi == null) { wData.current.uvi = bgData.current.uvi; }
            if (wData.current.clouds == null) { wData.current.clouds = bgData.current.clouds; }  
            if (wData.current.dewPoint == null) { wData.current.dewPoint = bgData.current.dewPoint; }
            if (wData.current.pressure == null) { wData.current.pressure = bgData.current.pressure; }  
            if (wData.current.rain1hr == null) { wData.current.rain1hr = bgData.current.rain1hr; }  
            if (wData.current.snow1hr == null) { wData.current.rain1hr = bgData.current.snow1hr; }  

            wData.minutely = bgData.minutely; 
            wData.alerts = bgData.alerts;
            if (bgData.changed) { wData.changed = true; }
           break;
          case wsOWMFirst:
            wData.current.precipitationChanceOther = garminData.current.precipitationChance; 
            wData.current.conditionOther = garminData.current.condition;             
           break;          
        }

        // We assume start hour is for both set the same! Past hours will be purged.
        var maxH = garminData.hourly.size();
        var maxBgH = bgData.hourly.size();          
        for (var h = 0; h < maxH; h += 1) {
          if (h < maxBgH) {
            switch(source) {
              case wsGarminFirst:
                wData.hourly[h].precipitationChanceOther = bgData.hourly[h].precipitationChance; 
                wData.hourly[h].conditionOther = bgData.hourly[h].condition; 
                if (wData.hourly[h].uvi == null) { wData.hourly[h].uvi =  bgData.hourly[h].uvi; }
                if (wData.hourly[h].clouds == null) { wData.hourly[h].clouds =  bgData.hourly[h].clouds; }
                if (wData.hourly[h].dewPoint == null) { wData.hourly[h].dewPoint = bgData.hourly[h].dewPoint; }
                if (wData.hourly[h].pressure == null) { wData.hourly[h].pressure = bgData.hourly[h].pressure; }  
                if (wData.hourly[h].rain1hr == null) { wData.hourly[h].rain1hr = bgData.hourly[h].rain1hr; }  
                if (wData.hourly[h].snow1hr == null) { wData.hourly[h].snow1hr = bgData.hourly[h].snow1hr; }  
                break;
              case wsOWMFirst:
                wData.hourly[h].precipitationChanceOther = garminData.hourly[h].precipitationChance; 
                wData.hourly[h].conditionOther = garminData.hourly[h].condition; 
                break;              
            }
          }
        }                  
        return wData;      
      } catch (ex) {
        ex.printStackTrace();
        return emptyWeatherData();
      }        
    }
    (:typecheck(disableBackgroundCheck))  
    function isWeatherDataChanged(current as WeatherDataCheck, newData as WeatherData?) as Boolean {

      if (newData == null) { return true; }            
      var newWeatherData = new WeatherDataCheck(newData);

      var nD = newData as WeatherData;        
      return nD.changed || !current.isEqual(newWeatherData);        
    }
    (:typecheck(disableBackgroundCheck))  
    function setWeatherDataChanged(data as WeatherData?, changed as Boolean) as WeatherData? {
      if (data == null) { return data; }
      var d = data as WeatherData;
      d.setChanged(changed);
      return d;
    }
// }

(:typecheck(disableBackgroundCheck))  
class WeatherDataCheck {
  var time as String = "";
  var lat as String = "";
  var lon as String = "";
  var name as String = "";

  function initialize(data as WeatherData?) {
    if (data != null) {
      var d = data as WeatherData;  
      time = $.getShortTimeString(d.current.observationTime);
      lat = getDoubleAsStringValue(d.current.lat);
      lon = getDoubleAsStringValue(d.current.lon);
      if (data.current.observationLocationName != null) { 
        name = data.current.observationLocationName;
      }
    }
  } 

  function isEqual(item as WeatherDataCheck) as Boolean {

    System.println("self [" + self.toString() + "]");
    System.println("item [" + item.toString() + "]");
      
    return time.equals(item.time) && lat.equals(item.lat) && lon.equals(item.lon) && name.equals(item.name);
  }

  hidden function getDoubleAsStringValue(item as Double?) as String {
    if (item == null) { return ""; }
    return (item as Double).toString();
  }

  function toString() as String {
    return "Time[" + time + "]lat[" + lat + "]lon[" + lon +"]name[" + name + "]";
  }
}