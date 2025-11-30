import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

function getLatestGarminWeather() as WeatherData {
  try {
    var garCurrent = Weather.getCurrentConditions();
    if (garCurrent == null) {
      return emptyWeatherData();
    }
    var wo = new WeatherObservation();
    var position = garCurrent.observationLocationPosition;
    if (position != null) {
      var location = position.toDegrees();
      wo.lat = $.getNumericValueOrDefault(location[0], 0.0d) as Lang.Double;
      wo.lon = $.getNumericValueOrDefault(location[1], 0.0d) as Lang.Double;
    }
    wo.observationLocationName = "G" + wo.lat + "," + wo.lon;
    wo.observationTime = garCurrent.observationTime;
    if (DEBUG_DETAILS) {
      System.println("Gar Observation: " + wo.info());
    }

    // Not available for Garmin, rain first hour.
    var mm = new WeatherMinutely();
    // @@ TEST weather minutely
    // mm.pops = [ 0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,  0.12,  0.159,  0.198,  0.237,  0.9188,  1.6006,  2.2824,  2.9642,  3.646,  3.4636,  3.2812,  3.0988,  2.9164,  2.734,  2.5972,  2.4604,  2.3236,  2.1868,  2.05,  2.05,  2.05,  2.05,  2.05,  2.05,  2.1136,  2.1772,  2.2408,  2.3044,  2.368,  2.4412,  2.5144,  2.5876,  2.6608,  2.734,  2.734,  2.734,  2.734,  2.734,  2.734,  2.6608,  2.5876,  2.5144,  2.4412] as Array<Float>;
    // mm.max = 2.0;
    // mm.pops = [ 0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,  0.12,  0.159,  0.198,  0.237,  0.9188,  0.6006,  0.2824,  0.9642,  0.646,  0.4636,  0.2812,  0.0988,  0.9164,  0.734,  0.5972,  0.4604,  0.3236,  0.1868,  0.05,  0.05,  0.05,  0.05,  0.05,  0.05,  0.1136,  0.1772,  0.2408,  0.3044,  0.368,  0.4412,  0.5144,  0.5876,  0.6608,  0.734,  0.734,  0.734,  0.734,  0.734,  0.734,  0.6608,  0.5876,  0.5144,  0.4412] as Array<Float>;
    // mm.max = 0.8;

    var hh = [] as Array<WeatherHourly>;
    // Note: hourly forecast from garmin starts at next hour, currentconditions contains first hour.
    // Ex. now is 025-11-30 10:10:00, hourlyforecast starts with 025-11-30 11:00:00
    var hf1 = $.getGarminHourly(wo.observationTime, garCurrent);
    hh.add(hf1);

    var garHourlyForecast = Weather.getHourlyForecast();

    if (garHourlyForecast == null) {
      return new WeatherData(wo, mm, hh, [] as Array<WeatherAlert>, wo.observationTime);
    }

    // Get only the hours we need, start from current hour
    var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

    var now = new Time.Moment(Time.now().value());
    var oneHour = Gregorian.duration({ :hours => 1 });
    var startTime = now.subtract(oneHour);

    // Plus 1, for handling hour change. Not showing empty column
    var maxHoursDisplayed = ($.getStorageValue("openWeatherMaxHours", 1) as Number) + 1;

    var max = garHourlyForecast.size();
    for (var idx = 0; idx < max; idx += 1) {
      if (hh.size() > maxHoursDisplayed) {
        System.println(["Gar skip forecast:", idx, "max display:", maxHoursDisplayed]);
        continue;
      }

      var garForecast = garHourlyForecast[idx] as Weather.HourlyForecast;
      if (garForecast.forecastTime == null) {
        continue;
      }
      // Skip forecast of different days/previous hours
      var fcTime = garForecast.forecastTime as Time.Moment;
      if (fcTime.lessThan(startTime)) {
        System.println(["Gar skip forecast hour:", $.getDateTimeString(fcTime)]);
        continue;
      }

      // Should be current hour or next ..
      var infoFcTime = Gregorian.info(fcTime, Time.FORMAT_MEDIUM);
      if (infoFcTime.hour < today.hour) {
        System.println(["Gar skip forecast hour:", infoFcTime.hour]);
        continue;
      }

      var hf = $.getGarminHourly(fcTime, garForecast);

      // TEST
      // hf.windGust = 5.0;

      if (DEBUG_DETAILS) {
        System.println("Gar Hourly: " + hf.info());
      }

      hh.add(hf);
    } // for garHourlyForecast

    return new WeatherData(wo, mm, hh, [] as Array<WeatherAlert>, wo.observationTime);
  } catch (ex) {
    ex.printStackTrace();
    return emptyWeatherData();
  }
}

function getGarminHourly(forecastTime as Moment, forecast as CurrentConditions or HourlyForecast) as WeatherHourly {
  var WEATHER_CONDITION_UNKNOWN = 53;
  var hf = new WeatherHourly();

  hf.forecastTime = forecastTime;
  var infoFcTime = Gregorian.info(hf.forecastTime, Time.FORMAT_MEDIUM);
  hf.hour = infoFcTime.hour;
  if (forecast has :cloudCover) {
    hf.clouds = $.getNumericValueOrDefault(forecast.cloudCover, 0) as Lang.Number;
  } else {
    hf.clouds = 0;
  }

  if (forecast has :uvIndex) {
    hf.uvi = $.getNumericValueOrDefault(forecast.uvIndex, 0.0f) as Lang.Float;
  } else {
    hf.uvi = 0.0f;
  }

  hf.precipitationChance = $.getNumericValueOrDefault(forecast.precipitationChance, 0) as Lang.Number;
  hf.condition = $.getNumericValueOrDefault(forecast.condition as Lang.Number?, WEATHER_CONDITION_UNKNOWN) as Lang.Number;
  hf.windBearing = $.getNumericValueOrDefault(forecast.windBearing, 0) as Lang.Number;
  hf.windSpeed = $.getNumericValueOrDefault(forecast.windSpeed, 0.0f) as Lang.Float;
  hf.temperature = $.getNumericValueOrDefault(forecast.temperature, 0.0f) as Lang.Numeric;
  hf.relativeHumidity = $.getNumericValueOrDefault(forecast.relativeHumidity, 0) as Lang.Number;
  if (forecast has :dewPoint) {
    hf.dewPoint = $.getNumericValueOrDefault(forecast.dewPoint, 0.0f) as Lang.Float;
  } else {
    hf.dewPoint = calculateDewpoint(hf.temperature, hf.relativeHumidity);
  }
  if (forecast has :pressure) {
    var pascal = $.getNumericValueOrDefault(forecast.pressure, 0) as Lang.Number;
    hf.pressure = pascal / 100;
  }

  // TEST
  // hf.windGust = 5.0;
  return hf;
}

function calculateDewpoint(temperatureCelcius as Numeric?, relativeHumidity as Number?) as Float {
  if (temperatureCelcius == null || relativeHumidity == null) {
    return 0.0;
  }
  // https://learnmetrics.com/dew-point-calculator-chart-formula/
  return (temperatureCelcius as Number) - (100 - (relativeHumidity as Number)) / 5.0;
}
