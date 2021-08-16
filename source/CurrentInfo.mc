import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Sensor;
//using Toybox.SensorHistory;

class CurrentInfo {
  var lat = 0;
  var lon = 0;

  hidden var _actiInfo as Info ? ;
  hidden var _posnInfo as Info ? ;
  function initialize() { }

  function hasLocation() { return self.lat != 0 && self.lon != 0; }

  function infoLocation() {
    return Lang.format("current($1$,$2$)",
                       [ lat.format("%.4f"), lon.format("%.4f") ]);
  }
  function getPosition(info as Activity.Info) {
    try {
      _actiInfo = info;
      var location = getNewLocation(info.currentLocation);
      if (location == null) {
        _posnInfo = Position.getInfo();
        if (_posnInfo has :position && _posnInfo.position != null) {
          location = getNewLocation(_posnInfo.position);
        }
      }
      if (location != null) {
        self.lat = location[0];
        self.lon = location[1];
      }

    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function getNewLocation(position as Position.Location) {
    if (position == null) {
      return null;
    }
    var location = position.toDegrees();
    var lat = location[0];
    var lon = location[1];
    if (lat.toNumber() != 0 && lon.toNumber() != 0 && self.lat != lat &&
        self.lon != lon) {
      return location;
    }
    return null;
  }

  function compassDirection() {
    var direction = null;
    var SensorInfo = Sensor.Info;
    if (SensorInfo != null && SensorInfo has :heading && SensorInfo.heading != null) {
      direction = getCompassDirection(rad2deg(SensorInfo.heading));
    } else if (_actiInfo != null && _actiInfo.currentHeading != null) {
      direction = getCompassDirection(rad2deg(_actiInfo.currentHeading));
    } else if (_posnInfo != null && _posnInfo.heading != null) {
      direction = getCompassDirection(rad2deg(_posnInfo.heading));
    }
    return direction;
  }

  function altitude() {
    var SensorInfo = Sensor.Info;
    if (SensorInfo != null && SensorInfo has
        : altitude && SensorInfo.altitude != null) {
      return SensorInfo.altitude;
    } else if (_actiInfo != null && _actiInfo has :altitude && _actiInfo.altitude != null) {
      return _actiInfo.altitude;
    } else if (_posnInfo != null && _posnInfo has :altitude) {
      return _posnInfo.altitude;
    }
    return null;
  }

  function elapsedDistance() {
    var distance = null;    
    if (_actiInfo != null && _actiInfo has :elapsedDistance) {
      distance = _actiInfo.elapsedDistance;
    }
    return distance;
  }

  function heartRate() {
    var SensorInfo = Sensor.Info;
    if (SensorInfo != null && SensorInfo has :heartRate && SensorInfo.heartRate != null) {
      return SensorInfo.heartRate;
    } else if (_actiInfo != null && _actiInfo has :currentHeartRate) {
      return _actiInfo.currentHeartRate;
    }
    return null;
  }

  function ambientPressure() {
    var pressure = null;
    var SensorInfo = Sensor.Info;
    if (SensorInfo != null && SensorInfo has :pressure && SensorInfo.pressure != null) {
      pressure = SensorInfo.pressure;
    } else if (_actiInfo != null && _actiInfo has :ambientPressure) {
      pressure = _actiInfo.ambientPressure;
    }
    return pressure;
  }

  function temperature() {
    var SensorInfo = Sensor.Info;
    if (SensorInfo != null && SensorInfo has :temperature && SensorInfo.temperature != null) {
      return SensorInfo.temperature;
    }
    return null;
    //return getLatestTemperatureHistory();
  }

  // hidden function getLatestTemperatureHistory() {
  //   if ((Toybox has :SensorHistory) && (SensorHistory has :getTemperatureHistory)) {
	//       var temperatureHistory = SensorHistory.getTemperatureHistory({:period =>1, :order => SensorHistory.ORDER_NEWEST_FIRST});
	//       return temperatureHistory.next().data;
	//   }
	//   return null;
  // }
  
}