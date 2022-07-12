import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.Application.Storage;
using Toybox.System;
using WhatAppBase.Utils as Utils;

class CurrentInfo {
  var lat as Lang.Double = 0.0d;
  var lon as Lang.Double = 0.0d;

  hidden var _actiInfo as Activity.Info? ;
  hidden var _posnInfo as Position.Info? ;
  function initialize() { }

  function hasLocation() as Lang.Boolean { return self.lat != 0 && self.lon != 0; }

  function infoLocation()as Lang.String {
    return Lang.format("current($1$,$2$)", [ lat.format("%.4f"), lon.format("%.4f") ]);
  }

  function getPosition(info as Activity.Info) as Void {
    try {
      _actiInfo = info;
      var location = getNewLocation(info.currentLocation);
      if (location == null) {
        _posnInfo = Position.getInfo();
        if (_posnInfo != null) {
          if (_posnInfo has :position && _posnInfo.position != null) {
            location = getNewLocation((_posnInfo as Position.Info).position);
          }
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

  hidden function getNewLocation(location as Position.Location?) as Lang.Array<Lang.Double>? {
    if (location == null) {
      return null;
    }
    var _location = location.toDegrees();
    var lat = _location[0];
    var lon = _location[1];
    if (lat.toNumber() != 0 && lon.toNumber() != 0 && self.lat != lat &&
        self.lon != lon) {
      Storage.setValue("latest_latlng", _location); // [lat,lng]
      return _location;
    }
    return null;
  }

  function compassDirection() as Lang.String? {
    var direction = null;

    if (_actiInfo != null) {
      var info = _actiInfo as Activity.Info;
      if (info has :currentHeading && info.currentHeading != null) {
        direction = Utils.getCompassDirection(Utils.rad2deg(info.currentHeading));
        return direction;
      }
    } 
    if (_posnInfo != null) {
      var info = _posnInfo as Position.Info;
      if (info has :heading && _posnInfo.heading != null) {
        direction = Utils.getCompassDirection(Utils.rad2deg(_posnInfo.heading));
        return direction;
      }
    }
    return direction;
  }

  function ambientPressure() as Lang.Float? {
    if (_actiInfo != null) {
      var info = _actiInfo as Activity.Info;
      if (info has :ambientPressure && info.ambientPressure != null) {
        return info.ambientPressure;
      }
    } 

    return null;
  }

  function meanSeaLevelPressure () as Lang.Float? {
    if (_actiInfo != null) {
      var info = _actiInfo as Activity.Info;
      if (info has :meanSeaLevelPressure  && info.meanSeaLevelPressure  != null) {
        return info.meanSeaLevelPressure ;
      }
    } 

    return null;
  }

  // Distance in km
  function elapsedDistance() as Lang.Float?{
    var distance = null;    
    if (_actiInfo != null) {
      var info = _actiInfo as Activity.Info;
      if (info has :elapsedDistance && info.elapsedDistance != null) {      
        distance = info.elapsedDistance as Float / 1000.0;
      }
    }
    return distance;
  }

  function temperature() as Lang.Float? {
    return Utils.getStorageValue("Temperature", null) as Lang.Float?;
  }  
  
}