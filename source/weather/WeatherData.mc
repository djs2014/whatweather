import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;

(:extendedCode) 
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

(:extendedCode) 
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

(:extendedCode) 
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

(:extendedCode)
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

(:extendedCode)
class WeatherForecastAlert {
  var alertPrecipitationChance as Boolean = false;
  var alertRainMMHour as Boolean = false;

  var alertWeatherCondition as Boolean = false;
  var alertUvi as Boolean = false;
  var alertWind as Boolean = false;
  var alertDewpoint as Boolean = false;

  function initialize() {}
}
