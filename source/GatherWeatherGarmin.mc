import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
using Toybox.Time.Gregorian as Calendar;

class GarminWeather {
  static function getLatestGarminWeather() {
    try {
      if ($._mostRecentData == null) {
        $._mostRecentData = new WeatherData();
      }
      var garCurrent = Weather.getCurrentConditions();
      if (garCurrent == null) {
        $._mostRecentData = new WeatherData();
        $._mostRecentData.lastUpdated = Time.now();
        return;
      }

      // if (!$._alwaysUpdateGarminWeather || $._mostRecentData.valid()) {
      //   var newData = garCurrent.observationTime != null &&
      //                 garCurrent.observationTime.greaterThan(
      //                     $._mostRecentData.lastUpdated);

      //   if (DEBUG_DETAILS) {
      //     System.println(Lang.format(
      //         "Check garmin obs[$1$] last updated[$2$] is new data[$3$]", [
      //           getDateTimeString(garCurrent.observationTime),
      //           getDateTimeString($._mostRecentData.lastUpdated),
      //           garCurrent.observationTime.greaterThan(
      //               $._mostRecentData.lastUpdated)
      //         ]));
      //   }
      //   if (!newData) {
      //     return;
      //   }
      // }

      var cc = new CurrentConditions();
      cc.precipitationChance = getValue(garCurrent.precipitationChance, 0);
      cc.forecastTime = null;  //@@ needed?

      var position = garCurrent.observationLocationPosition;
      if (position != null) {
        var location = position.toDegrees();
        cc.lat = getValue(location[0], 0);
        cc.lon = getValue(location[1], 0);
      }
      cc.observationLocationName =
          getValue(garCurrent.observationLocationName, "");
      // Skip after first ,
      var comma = cc.observationLocationName.find(",");
      if (comma != null) {
        cc.observationLocationName =
            cc.observationLocationName.substring(0, comma);
      }

      cc.observationTime = garCurrent.observationTime;
      cc.clouds = 0;    // Not available
      cc.uvi = null;    // Not available
      cc.weather = "";  // @@ map condition
      cc.condition = getValue(garCurrent.condition, Weather.CONDITION_CLEAR);
      cc.windBearing = garCurrent.windBearing;
      cc.windSpeed = garCurrent.windSpeed;
      cc.temperature = garCurrent.temperature;
      cc.relativeHumidity = garCurrent.relativeHumidity;

      if (DEBUG_DETAILS) {
        System.println("Gar Current: " + cc.info());
      }

      var mm = new MinutelyForecast();  // Not available

      var hh = [];
      var garHourlyForecast = Weather.getHourlyForecast();
      if (garHourlyForecast != null) {
        for (var idx = 0; idx < garHourlyForecast.size(); idx += 1) {
          var garForecast = garHourlyForecast[idx];
          var hf = new HourlyForecast();
          hf.forecastTime = garForecast.forecastTime;
          hf.clouds = 0;  // Not available
          hf.uvi = null;  // Not available
          hf.precipitationChance = getValue(garForecast.precipitationChance, 0);
          hf.weather = "";  // @@ map condition
          hf.condition =
              getValue(garForecast.condition, Weather.CONDITION_CLEAR);
          hf.windBearing = garForecast.windBearing;
          hf.windSpeed = garForecast.windSpeed;
          hf.temperature = garForecast.temperature;
          hf.relativeHumidity = garForecast.relativeHumidity;
          if (DEBUG_DETAILS) {
            System.println("Gar Hourly: " + hf.info());
          }
          hh.add(hf);
        }
      }

      $._mostRecentData.current = cc;
      $._mostRecentData.hourly = hh;
      $._mostRecentData.minutely = mm;
      $._mostRecentData.lastUpdated = cc.observationTime;
    } catch (ex) {
      ex.printStackTrace();
    }
  }
}
