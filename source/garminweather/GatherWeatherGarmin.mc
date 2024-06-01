import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// class GarminWeather {
function getLatestGarminWeather() as WeatherData {
  var WEATHER_CONDITION_UNKNOWN = 53;
  try {
    var garCurrent = Weather.getCurrentConditions();
    if (garCurrent == null) {
      return emptyWeatherData();
    }

    var cc = new WeatherCurrent();
    cc.precipitationChance = $.getNumericValue(garCurrent.precipitationChance, 0) as Lang.Number;
    cc.forecastTime = null; //@@ needed?

    var position = garCurrent.observationLocationPosition;
    if (position != null) {
      var location = position.toDegrees();
      cc.lat = $.getNumericValue(location[0], 0.0d) as Lang.Double;
      cc.lon = $.getNumericValue(location[1], 0.0d) as Lang.Double;
    }
    cc.observationLocationName = $.getStringValue(garCurrent.observationLocationName, "") as Lang.String;
    // Skip after first ,
    var comma = cc.observationLocationName.find(",");
    if (comma != null) {
      var onlyName = (cc.observationLocationName as Lang.String).substring(0, comma);
      if (onlyName != null) {
        cc.observationLocationName = onlyName as Lang.String;
      }
    }

    cc.observationTime = garCurrent.observationTime;
    cc.clouds = 0; // Not available
    cc.uvi = null; // Not available
    cc.condition = $.getNumericValue(garCurrent.condition, WEATHER_CONDITION_UNKNOWN) as Lang.Number;
    cc.windBearing = garCurrent.windBearing;
    cc.windSpeed = garCurrent.windSpeed;
    cc.temperature = garCurrent.temperature;
    cc.relativeHumidity = garCurrent.relativeHumidity;
    cc.dewPoint = calculateDewpoint(cc.temperature, cc.relativeHumidity);

    // TEST
    // cc.windGust = 15.0;

    if (DEBUG_DETAILS) {
      System.println("Gar Current: " + cc.info());
    }

    var mm = new WeatherMinutely(); // Not available for Garmin
    // TEST
    // mm.pops = [ 0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,  0.12,  0.159,  0.198,  0.237,  0.9188,  1.6006,  2.2824,  2.9642,  3.646,  3.4636,  3.2812,  3.0988,  2.9164,  2.734,  2.5972,  2.4604,  2.3236,  2.1868,  2.05,  2.05,  2.05,  2.05,  2.05,  2.05,  2.1136,  2.1772,  2.2408,  2.3044,  2.368,  2.4412,  2.5144,  2.5876,  2.6608,  2.734,  2.734,  2.734,  2.734,  2.734,  2.734,  2.6608,  2.5876,  2.5144,  2.4412] as Array<Float>;

    var hh = [] as Array<WeatherHourly>;
    var garHourlyForecast = Weather.getHourlyForecast();
    if (garHourlyForecast != null) {
      for (var idx = 0; idx < garHourlyForecast.size(); idx += 1) {
        var garForecast = garHourlyForecast[idx] as Weather.HourlyForecast;
        if (garForecast.forecastTime != null) {
          var hf = new WeatherHourly();
          hf.forecastTime = garForecast.forecastTime as Time.Moment;
          hf.clouds = 0; // Not availablelastUpdateddity;
          hf.uvi = null; // Not available
          hf.precipitationChance = $.getNumericValue(garForecast.precipitationChance, 0) as Lang.Number;
          hf.condition =
            $.getNumericValue(garForecast.condition as Lang.Number?, WEATHER_CONDITION_UNKNOWN) as Lang.Number;
          hf.windBearing = garForecast.windBearing;
          hf.windSpeed = garForecast.windSpeed;
          hf.temperature = garForecast.temperature;
          hf.relativeHumidity = garForecast.relativeHumidity;
          hf.dewPoint = calculateDewpoint(hf.temperature, hf.relativeHumidity);

          // TEST
          // hf.windGust = 5.0;

          if (DEBUG_DETAILS) {
            System.println("Gar Hourly: " + hf.info());
          }
          hh.add(hf);
        }
      }
    }

    // @@ TEST, check server code about repeating alerts.
    // var alerts = [];
    // var wa = new WeatherAlert();
    // wa.event = "Moderate snow warning 5";
    // //wa.description = "First alert message. Risk of slippery roads due to (earlier) sleet/snowfall.";
    // wa.description =
    //   "* WHERE...Portions of east central and northeast Kansas and\ncentral, north central, northeast, northwest and west central\nMissouri.\n\n* WHEN...Until 10 AM CDT this morning.\n* IMPACTS...Frost and freeze conditions will kill crops, other\nsensitive vegetation and\npossibly damage unprotected outdoor plumbing.";

    // wa.description = $.stringReplace(wa.description, "\n", " ");
    // wa.description = $.stringReplace(wa.description, "\r", " ");

    // wa.tags = ["Snow/Ice"] as Lang.Array<String>;
    // //  cc.observationTime = new Time.Moment($.getDictionaryValue(bg_cc, "dt", 0) as Number);
    // wa.start = new Time.Moment(1678474800);
    // wa.end = new Time.Moment(1678528800);
    // alerts.add(wa);
    // return new WeatherData(cc, mm, hh, alerts as Array<WeatherAlert>, cc.observationTime);

    // "sender_name": "KNMI Koninklijk Nederlands Meteorologisch Instituut",

    return new WeatherData(cc, mm, hh, [] as Array<WeatherAlert>, cc.observationTime);
  } catch (ex) {
    ex.printStackTrace();
    return emptyWeatherData();
  }
}

function calculateDewpoint(temperatureCelcius as Numeric?, relativeHumidity as Number?) as Float {
  if (temperatureCelcius == null || relativeHumidity == null) {
    return 0.0;
  }
  // https://learnmetrics.com/dew-point-calculator-chart-formula/
  return (temperatureCelcius as Number) - (100 - (relativeHumidity as Number)) / 5.0;
}
//}
