import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Position;

module WhatAppBase {
  (:Utils) 
  module Utils {
    class CurrentLocation {
      hidden var mLocation as Location?; 
      hidden var mAccuracy as Quality? = Position.QUALITY_NOT_AVAILABLE;

      function initialize() {}

      function hasLocation() as Boolean { 
        if ( mLocation == null) { return false; }
        var currentLocation = mLocation as Location;
        var degrees = currentLocation.toDegrees();
        return degrees[0] != 0.0 && degrees[1] != 0.0;
      } 

      function infoLocation() as String {
        if (!hasLocation()) { return "No location"; }
        var currentLocation = mLocation as Location;
        var degrees = currentLocation.toDegrees();
        var latCurrent = degrees[0];
        var lonCurrent = degrees[1];
        return "Current location: [" + latCurrent.format("%04d") + "," + lonCurrent.format("%04d") + "]";
      }

      function getAccuracy() as Quality {
        if (mAccuracy == null) { return Position.QUALITY_NOT_AVAILABLE; }
        return mAccuracy;
      }
      
      function getLocation() as Location? {
        return mLocation;
      }

      function onCompute(info as Activity.Info) as Void {
        try {
          var location = null;
          mAccuracy = Position.QUALITY_NOT_AVAILABLE;
          if (info != null) {
            if (info has :currentLocation && info.currentLocation != null) {
              location = info.currentLocation as Location;
              if (info has :currentLocationAccuracy && info.currentLocationAccuracy != null) {
                mAccuracy = info.currentLocationAccuracy;
              }
              if (locationChanged(location)) {
                System.println("Activity location lat/lon: " + location.toDegrees() + " accuracy: " + mAccuracy);
              }
            }
          }
          if (location == null) {
            var posnInfo = Position.getInfo();
            if (posnInfo != null && posnInfo has :position && posnInfo.position != null) {              
              location = posnInfo.position as Location;
              if (posnInfo has :accuracy && posnInfo.accuracy != null) {
                mAccuracy = posnInfo.accuracy;                
              }
              if (locationChanged(location)) {
                System.println("Position location lat/lon: " + location.toDegrees() + " accuracy: " + mAccuracy);
              }
            }
          }
          if (location != null) {
            mLocation = location;
          } else if (mLocation != null) {
            mAccuracy = Position.QUALITY_LAST_KNOWN;
          }
        } catch (ex) {
          ex.printStackTrace();
        }
      }     

      hidden function locationChanged(location as Location?) as Boolean {
        if (location == null) {
          if (mLocation == null) { return false;
          } else { return true; }
        }
        if (mLocation == null) {
          if (location == null) { return false;
          } else { return true; }
        }
        // This will crash the compiler when on strict level
        // if (mLocation == null && location == null ){ return false; }
        // if ( (mLocation != null && location == null) || (mLocation == null && location != null) ){ return true; }

        var currentLocation = mLocation as Location;
        var currentDegrees = currentLocation.toDegrees();

        var newLocation = location as Location;
        var degrees = newLocation.toDegrees();
        
        return degrees[0] != currentDegrees[0] && degrees[1] != currentDegrees[1];        
      }

      function getRelativeToObservation(latObservation as Double, lonObservation as Double) as String {
        if (!hasLocation() || latObservation == 0.0 || lonObservation == 0.0 ) {
          return "";
        }

        var currentLocation = mLocation as Location;
        var degrees = currentLocation.toDegrees();
        var latCurrent = degrees[0];
        var lonCurrent = degrees[1];

        var distanceMetric = "km";
        var distance = Utils.getDistanceFromLatLonInKm(latCurrent, lonCurrent, latObservation, lonObservation);

        var deviceSettings = System.getDeviceSettings();
        if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
          distance = Utils.kilometerToMile(distance);
          distanceMetric = "m";
        }
        var bearing = Utils.getRhumbLineBearing(latCurrent, lonCurrent, latObservation, lonObservation);
        var compassDirection = Utils.getCompassDirection(bearing);

        return format("$1$ $2$ ($3$)",[ distance.format("%.2f"), distanceMetric, compassDirection ]);
      }
    }
  }
}
