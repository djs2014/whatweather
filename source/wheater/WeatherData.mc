import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

class WeatherCheck {
  public var observationTime as Time.Moment? = null;
  public var lat as Lang.Double = 0.0d;
  public var lon as Lang.Double = 0.0d;

  public function changed(lat as Lang.Double, lon as Lang.Double, observationTime as Time.Moment?) as Boolean {
    try {
      if (self.lat != lat || self.lon != lon) {
        return true;
      }
      if (self.observationTime == null || observationTime == null) {
        return true;
      }

      // :-/
      return (self.observationTime as Time.Moment).compare(observationTime as Time.Moment) != 0;
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      return true;
    }
  }
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
  var max as Float = 0.0;
  var pops as Array<Float> = [] as Array<Float>;
}

class WeatherHourly {
  var forecastTime as Time.Moment = Time.now();
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
  var tags as Array<String> = [] as Array<String>;
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

class WeatherData {
  
  public var observation as WeatherObservation;
  public var minutely as WeatherMinutely;  
  public var hourly as Lang.Array<WeatherHourly>;
  public var alerts as Lang.Array<WeatherAlert>;
  public var lastUpdated as Time.Moment?;
  public var changed as Lang.Boolean = false;

  function initialize(
    observation as WeatherObservation,
    minutely as WeatherMinutely,
    hourly as Array<WeatherHourly>,
    alerts as Array<WeatherAlert>,
    lastUpdated as Time.Moment?
  ) {
    self.observation = observation;
    self.minutely = minutely;
    self.hourly = hourly;
    self.alerts = alerts;
    self.lastUpdated = lastUpdated;
    self.changed = false;
  }

  function valid() as Lang.Boolean {
    return hourly.size() > 0;
  }

  function getObservationTime() as Time.Moment? {
    return (self.observation as WeatherObservation).observationTime;
  }
  function getLat() as Double {
    return (self.observation as WeatherObservation).lat;
  }
  function getLon() as Double {
    return (self.observation as WeatherObservation).lon;
  }
  public function setChanged(changed as Boolean) as Void {
    self.changed = changed;
  }
}

function emptyWeatherData() as WeatherData {
  var wd = new WeatherData(
    new WeatherObservation(),
    new WeatherMinutely(),
    [] as Array<WeatherHourly>,
    [] as Array<WeatherAlert>,
    Time.now()
  );
  wd.setChanged(true);
  return wd;
}
