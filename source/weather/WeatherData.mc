import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;

class GarminWeatherCheck {
  public var observationTime as Time.Moment? = null;
  public var lat as Lang.Double = 0.0d;
  public var lon as Lang.Double = 0.0d;

  // Checks if the weather data has changed compared to the latest Garmin data
  public function changed() as Boolean {
    var new_lat = 0.0d;
    var new_lon = 0.0d;
    var new_observationTime = null;

    var garCurrent = Weather.getCurrentConditions();
    if (garCurrent != null) {
      var position = garCurrent.observationLocationPosition;
      if (position != null) {
        var location = position.toDegrees();
        new_lat = $.getNumericValueOrDefault(location[0], 0.0d) as Lang.Double;
        new_lon = $.getNumericValueOrDefault(location[1], 0.0d) as Lang.Double;
      }
      new_observationTime = garCurrent.observationTime;
    }

    try {
      if (lat != new_lat || lon != new_lon) {
        return true;
      }
      if (observationTime == null || new_observationTime == null) {
        return true;
      }

      // :-/
      return (
        (observationTime as Time.Moment).compare(
          new_observationTime as Time.Moment
        ) != 0
      );
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      return true;
    }
  }

  public function update() {
    var garCurrent = Weather.getCurrentConditions();
    if (garCurrent != null) {
      var position = garCurrent.observationLocationPosition;
      if (position != null) {
        var location = position.toDegrees();
        lat = $.getNumericValueOrDefault(location[0], 0.0d) as Lang.Double;
        lon = $.getNumericValueOrDefault(location[1], 0.0d) as Lang.Double;
      }
      observationTime = garCurrent.observationTime;
    } else {
      lat = 0.0d;
      lon = 0.0d;
      observationTime = null;
    }
  }
}

function getWeatherDataSize(data as Dictionary?) as Number {
  if (data == null) {
    return 0;
  }
  if (data.keys().size() == 0) {
    return 0;
  }
  if (!data.hasKey(:hr_dt)) {
    return 0;
  }
  var hourly = data[:hr_dt] as Array<Time.Moment>;
  return hourly.size();
}

function getWeatherDataAlerts(data as Dictionary?) as Array<WeatherAlert> {
  if (data == null) {
    return [] as Array<WeatherAlert>;
  }
  if (data.keys().size() == 0) {
    return [] as Array<WeatherAlert>;
  }
  if (!data.hasKey(:alerts)) {
    return [] as Array<WeatherAlert>;
  }
  
  System.println(["alerts", data[:alerts]]);

  return data[:alerts] as Array<WeatherAlert>;

  // var alerts = data[:alerts] as Array<Dictionary>;
  // var result = [] as Array<WeatherAlert>;
  // for (var i = 0; i < alerts.size(); i++) {
  //   var alertDict = alerts[i];
  //   var alert = new WeatherAlert();
  //   alert.event = alertDict[:event] as String;
  //   alert.description = alertDict[:description] as String;
  //   alert.start = alertDict[:start] as Time.Moment?;
  //   alert.end = alertDict[:end] as Time.Moment?;
  //   result.add(alert);
  // }
  // return result;
}
class WeatherObservation {
  var lat as Lang.Double = 0.0d;
  var lon as Lang.Double = 0.0d;
  var observationLocationName as Lang.String = "";
  var observationTime as Time.Moment? = null;

  function info() as Lang.String {
    return (
      "WeatherObservation:lat[" +
      lat +
      "]lon[" +
      lon +
      "]obsname[" +
      observationLocationName +
      "]obstime[" +
      $.getDateTimeString(observationTime) +
      "]"
    );
  }
}

class WeatherMinutely {
  var forecastTime as Time.Moment? = null;
  var max as Float = 0.0f;
  var pops as Array<Float> = [] as Array<Float>;
}

// TODO use
// var flatData = { :lat => 3636 etc ..

class WeatherHourly {
  var forecastTime as Time.Moment = Time.now();
  var hour as Number = 0;
  var clouds as Lang.Number = 0;
  var precipitationChance as Lang.Number = 0;
  var precipitationChanceOther as Lang.Number = 0;
  var condition as Lang.Number = 0;
  var conditionOther as Lang.Number = 0;
  var windBearing as Lang.Number = 0;
  var windSpeed as Lang.Float = 0.0f;
  var windGust as Lang.Float = 0.0f;
  var relativeHumidity as Lang.Number = 0;
  var temperature as Lang.Numeric = 0;
  var uvi as Lang.Float = 0.0f;
  var pressure as Lang.Number = 0; // hPa
  var dewPoint as Lang.Float = 0.0f;
  var rain1hr as Lang.Float = 0.0f; // mm / hour
  var snow1hr as Lang.Float = 0.0f; // mm / hour

  function info() as Lang.String {
    return (
      "WeatherHourly:time[" +
      $.getDateTimeString(forecastTime) +
      "]pop[" +
      precipitationChance +
      "]clouds[" +
      clouds +
      "]condition[" +
      condition +
      "]uvi[" +
      uvi +
      "]windBearing[" +
      windBearing +
      "]windSpeed[" +
      windSpeed +
      "]windGust[" +
      windGust +
      "]temperature[" +
      temperature +
      "]humidity[" +
      relativeHumidity +
      "]pressure[" +
      pressure +
      "]dewPoint[" +
      dewPoint +
      "] rain[" +
      rain1hr +
      "] snow[" +
      snow1hr +
      "]"
    );
  }
}

class WeatherAlert {
  var event as String = "";
  var start as Time.Moment?;
  var end as Time.Moment?;
  var description as String = "";
  // var tags as Array<String> = [] as Array<String>;
  var handled as Boolean = false;

  function info() as Lang.String {
    return (
      "WeatherAlert:[" +
      event +
      "] start[" +
      $.getDateTimeString(start) +
      "]end[" +
      $.getDateTimeString(end) +
      "] [" +
      description +
      "] handled[" +
      handled +
      "]"
    );
  }
}

// class WeatherData {
//   public var observation as WeatherObservation;
//   public var minutely as WeatherMinutely;
//   public var hourly as Lang.Array<WeatherHourly>;
//   public var alerts as Lang.Array<WeatherAlert>;
//   public var lastUpdated as Time.Moment?;
//   public var changed as Lang.Boolean = false;

//   function initialize(
//     observation as WeatherObservation,
//     minutely as WeatherMinutely,
//     hourly as Array<WeatherHourly>,
//     alerts as Array<WeatherAlert>,
//     lastUpdated as Time.Moment?
//   ) {
//     self.observation = observation;
//     self.minutely = minutely;
//     self.hourly = hourly;
//     self.alerts = alerts;
//     self.lastUpdated = lastUpdated;
//     self.changed = false;
//   }

//   function valid() as Lang.Boolean {
//     return hourly.size() > 0;
//   }

//   function getObservationTime() as Time.Moment? {
//     return (self.observation as WeatherObservation).observationTime;
//   }
//   function getLat() as Double {
//     return (self.observation as WeatherObservation).lat;
//   }
//   function getLon() as Double {
//     return (self.observation as WeatherObservation).lon;
//   }
//   public function setChanged(changed as Boolean) as Void {
//     self.changed = changed;
//   }
// }

// function emptyWeatherData() as WeatherData {
//   var wd = new WeatherData(
//     new WeatherObservation(),
//     new WeatherMinutely(),
//     [] as Array<WeatherHourly>,
//     [] as Array<WeatherAlert>,
//     Time.now()
//   );
//   wd.setChanged(true);
//   return wd;
// }

class WeatherForecastAlert {
  var alertPrecipitationChance as Boolean = false;
  var alertRainMMHour as Boolean = false;

  var alertWeatherCondition as Boolean = false;
  var alertUvi as Boolean = false;
  var alertWind as Boolean = false;
  var alertDewpoint as Boolean = false;

  function initialize() {}
}
