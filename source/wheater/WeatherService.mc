import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

using WhatAppBase.Colors as Colors;

(:background)
enum WeatherSource {
  wsGarminFirst = 0,
  wsOWMFirst = 1,
  wsGarminOnly = 2,
  wsOWMOnly = 3,
}

(:background)
enum apiVersion {
  owmOneCall25 = 0,
  owmOneCall30 = 1,
}

// Remove forecasts from past hour
(:typecheck(disableBackgroundCheck))
function purgePastWeatherdata(data as WeatherData?) as WeatherData {
  if (data == null) {
    return emptyWeatherData();
  }

  // Get start of the hour, minus 1 hour
  var nowSeconds = Time.now().value() - 3600;
  var cutOffTime = new Time.Moment(nowSeconds);
  if (DEBUG_DETAILS) {
    System.println("purgePastWeatherdata cutOffTime: " + $.getDateTimeString(cutOffTime));
  }  
  var wData = data as WeatherData;
  var newIdx = -1;
  var max = wData.hourly.size();
  for (var idx = 0; idx < max; idx += 1) {
    var weatherHourly = wData.hourly[idx] as WeatherHourly;
    if (DEBUG_DETAILS) {
      System.println("purgePastWeatherdata?: " + $.getDateTimeString(weatherHourly.forecastTime));
    }

    if (weatherHourly.forecastTime.lessThan(cutOffTime)) {
      // Is a past hour
      if (DEBUG_DETAILS) {
        System.println("purgePastWeatherdata past hour!: " + $.getDateTimeString(weatherHourly.forecastTime));
      }
      newIdx = idx;
      wData.setChanged(true);
    }
  }
  if (newIdx > -1) {
    wData.hourly = wData.hourly.slice(newIdx + 1, null);
  }
  return wData;
}

(:typecheck(disableBackgroundCheck))
function toWeatherData(data as Dictionary?) as WeatherData {
  try {
    if (data == null) {
      return emptyWeatherData();
    }
    var bgData = data as Dictionary;

    var wo = new WeatherObservation();
    var hh = [] as Array<WeatherHourly>;
    var mm = new WeatherMinutely();
    var al = [] as Array<WeatherAlert>;

    var current = bgData["current"];
    var hourly = bgData["hourly"];
    var minutely = bgData["minutely"];
    var alerts = bgData["alerts"];

    if (current != null) {
      var bg_cc = current as Dictionary;
      var bg_hh = hourly as Array<Array<Numeric> >;

      wo.lat = ($.getDictionaryValue(bg_cc, "lat", 0.0d) as Double).toDouble();
      wo.lon = ($.getDictionaryValue(bg_cc, "lon", 0.0d) as Double).toDouble();
      wo.observationLocationName = wo.lat + "," + wo.lon;
      wo.observationTime = new Time.Moment($.getDictionaryValue(bg_cc, "dt", 0) as Number);

      System.println("OWM Observation: " + wo.info());
    }

    if (hourly != null) {
      var bg_hh = hourly as Array<Array>;
      /*
      // Get only the hours we need, start from current hour
      var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

      var todayStartOfhour = Gregorian.moment({
        :year => today.year,
        :month => today.month,
        :day => today.day,
        :hour => today.hour,
        :minute => 0,
        :second => 0,
      });

      var oneHour = Gregorian.duration({ :hours => 1 });
      var startTime = todayStartOfhour.subtract(oneHour);
      System.println(["OWM start time forecast hourly:", $.getDateTimeString(startTime)]);
*/
      // Get start of the hour, minus 1 hour
      var nowSeconds = Time.now().value() - 3600;
      var cutOffTime = new Time.Moment(nowSeconds);
      System.println("OWM cutOffTime: " + $.getDateTimeString(cutOffTime));

      // Plus 1, for handling hour change. Not showing empty column
      var maxHoursDisplayed = ($.getStorageValue("openWeatherMaxHours", 1) as Number) + 1;

      var max = bg_hh.size();

      // There are only values in array to compress the payload
      for (var idx = 0; idx < max; idx++) {
        if (bg_hh.size() > maxHoursDisplayed) {
          System.println(["OWM skip forecast:", idx, "max display:", maxHoursDisplayed]);
          continue;
        }

        var hf = new WeatherHourly();
        var arr = bg_hh[idx] as Array<Numeric>;
        var fcTime = new Time.Moment(($.getNumericValueOrDefault(arr[0], 0) as Number).toNumber());

        // Skip forecast of different days/previous hours
        if (fcTime.lessThan(cutOffTime)) {
          System.println(["OWM skip forecast hour:", $.getDateTimeString(fcTime)]);
          continue;
        }

        hf.forecastTime = fcTime;
        var today = Gregorian.info(fcTime, Time.FORMAT_MEDIUM);
        hf.hour = today.hour;
        hf.clouds = ($.getNumericValueOrDefault(arr[1], 0) as Number).toNumber();
        // OWM pop from o.o - 1
        hf.precipitationChance = (($.getNumericValueOrDefault(arr[2], 0.0) as Float) * 100.0).toNumber();
        hf.condition = ($.getNumericValueOrDefault(arr[3], 0) as Number).toNumber();
        hf.uvi = ($.getNumericValueOrDefault(arr[4], 0.0) as Float).toFloat();
        hf.windSpeed = ($.getNumericValueOrDefault(arr[5], 0) as Float).toFloat();
        hf.windBearing = ($.getNumericValueOrDefault(arr[6], 0) as Number).toNumber();
        hf.temperature = ($.getNumericValueOrDefault(arr[7], 0) as Number).toNumber();
        hf.pressure = ($.getNumericValueOrDefault(arr[8], 0) as Number).toNumber();
        hf.relativeHumidity = ($.getNumericValueOrDefault(arr[9], 0) as Number).toNumber();
        hf.dewPoint = ($.getNumericValueOrDefault(arr[10], 0.0) as Float).toFloat();
        hf.rain1hr = ($.getNumericValueOrDefault(arr[11], 0.0) as Float).toFloat();
        hf.snow1hr = ($.getNumericValueOrDefault(arr[12], 0.0) as Float).toFloat();
        hf.windGust = ($.getNumericValueOrDefault(arr[12], 0.0) as Float).toFloat();

        System.println("OWM Hourly: " + hf.info());
        hh.add(hf);
      }
    }

    if (minutely != null) {
      var bg_mm = minutely as Dictionary;
      mm.forecastTime = new Time.Moment($.getDictionaryValue(bg_mm, "dt_start", 0.0) as Number);
      mm.max = $.getDictionaryValue(bg_mm, "max", 0.0) as Float;
      // System.println("bgData minutely max: " + mm.max.format("%.1f"));
      var pops = bg_mm["pops"];
      if (pops != null) {
        var bg_pops = pops as Array<Float>;
        for (var i = 0; i < bg_pops.size(); i++) {
          mm.pops.add(bg_pops[i] as Float);
          // System.println("bgData minutely " + i.format("%d") + ": " +  (bg_pops[i] as Float).format("%.1f"));
        }
        System.println("OWM size of minutely: " + mm.pops.size());
      }
    }

    if (alerts != null) {
      var bg_al = alerts as Array<Array>;
      for (var i = 0; i < bg_al.size(); i++) {
        var wal = new WeatherAlert();
        var warr = bg_al[i] as Array<Numeric or String>;
        wal.event = $.getStringValueOrDefault(warr[0] as String, "") as String;
        wal.start = new Time.Moment(($.getNumericValueOrDefault(warr[1] as Number, 0.0) as Number).toNumber());
        wal.end = new Time.Moment(($.getNumericValueOrDefault(warr[2] as Number, 0.0) as Number).toNumber());
        wal.description = $.getStringValueOrDefault(warr[3] as String, "") as String;
        wal.description = $.stringReplace(wal.description, "\n", " ");
        wal.description = $.stringReplace(wal.description, "\r", " ");
        System.println("OWM Alert: " + wal.info());
        al.add(wal);
      }
    }
    var wd = new WeatherData(wo, mm, hh, al, wo.observationTime);
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
    switch (source) {
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

    switch (source) {
      case wsGarminFirst:
        // Not available in garmin data (yet)
        wData.minutely = bgData.minutely;
        wData.alerts = bgData.alerts;
        if (bgData.changed) {
          wData.changed = true;
        }
        break;
    }

    // We assume start hour is for both set the same! Past hours will be purged.
    var maxH = garminData.hourly.size();
    var maxBgH = bgData.hourly.size();
    for (var h = 0; h < maxH; h += 1) {
      if (h < maxBgH) {
        switch (source) {
          case wsGarminFirst:
            wData.hourly[h].precipitationChanceOther = bgData.hourly[h].precipitationChance;
            wData.hourly[h].conditionOther = bgData.hourly[h].condition;
            if (wData.hourly[h].uvi == 0) {
              wData.hourly[h].uvi = bgData.hourly[h].uvi;
            }
            if (wData.hourly[h].clouds == 0) {
              wData.hourly[h].clouds = bgData.hourly[h].clouds;
            }
            if (wData.hourly[h].dewPoint == 0) {
              wData.hourly[h].dewPoint = bgData.hourly[h].dewPoint;
            }
            if (wData.hourly[h].pressure == 0) {
              wData.hourly[h].pressure = bgData.hourly[h].pressure;
            }
            if (wData.hourly[h].rain1hr == 0) {
              wData.hourly[h].rain1hr = bgData.hourly[h].rain1hr;
            }
            if (wData.hourly[h].snow1hr == 0) {
              wData.hourly[h].snow1hr = bgData.hourly[h].snow1hr;
            }
            if (wData.hourly[h].windGust == 0) {
              wData.hourly[h].windGust = bgData.hourly[h].windGust;
            }
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
  if (newData == null) {
    return true;
  }
  var newWeatherData = new WeatherDataCheck(newData);

  var nD = newData as WeatherData;
  return nD.changed || !current.isEqual(newWeatherData);
}
(:typecheck(disableBackgroundCheck))
function setWeatherDataChanged(data as WeatherData?, changed as Boolean) as WeatherData? {
  if (data == null) {
    return data;
  }
  var d = data as WeatherData;
  d.setChanged(changed);
  return d;
}

(:typecheck(disableBackgroundCheck))
class WeatherDataCheck {
  var time as String = "";
  var lat as String = "";
  var lon as String = "";
  var name as String = "";

  function initialize(data as WeatherData?) {
    if (data != null) {
      var d = data as WeatherData;
      time = $.getShortTimeString(d.observation.observationTime);
      lat = getDoubleAsStringValue(d.observation.lat);
      lon = getDoubleAsStringValue(d.observation.lon);
      name = data.observation.observationLocationName;
    }
  }

  function isEqual(item as WeatherDataCheck) as Boolean {
    System.println("self [" + self.toString() + "]");
    System.println("item [" + item.toString() + "]");

    return time.equals(item.time) && lat.equals(item.lat) && lon.equals(item.lon) && name.equals(item.name);
  }

  hidden function getDoubleAsStringValue(item as Double?) as String {
    if (item == null) {
      return "";
    }
    return (item as Double).toString();
  }

  function toString() as String {
    return "Time[" + time + "]lat[" + lat + "]lon[" + lon + "]name[" + name + "]";
  }
}
