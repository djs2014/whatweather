import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Position;
import Toybox.Weather;
import Toybox.Time;

module WhatAppBase {
  (:Utils) 
  module Utils {
    class CurrentLocation {
      hidden var mLocation as Location?; 
      hidden var mAccuracy as Quality? = Position.QUALITY_NOT_AVAILABLE;

      hidden var mSunrise as Moment?;
      hidden var mSunset as Moment?;

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
                setSunRiseAndSunSet(location);
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
                setSunRiseAndSunSet(location);
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

      hidden function setSunRiseAndSunSet(location as Location?) as Void {
          if (location == null) { return; }
          mSunrise = Weather.getSunrise(location as Location, Time.now()); // ex: 13-6-2022 05:20:43
          mSunset = Weather.getSunset(location as Location, Time.now()); // ex: 13-6-2022 22:02:25     
          System.println("Sunrise:" + Utils.getShortTimeString(mSunrise) + " sunset: " + Utils.getShortTimeString(mSunset) );     
      }

      function isAtDaylightTime(time as Moment?, defValue as Boolean) as Boolean {
        if (time == null || mSunrise == null || mSunset == null ) { return defValue; }

        // System.println("Sunrise:" + Utils.getShortTimeString(mSunrise) + "test: " +  Utils.getShortTimeString(time) + " sunset: " + Utils.getShortTimeString(mSunset) );  
        return (mSunrise as Moment).value() <= (time as Moment).value() && (time as Moment).value() <= (mSunset as Moment).value();        
      }

      function isAtNightTime(time as Moment?, defValue as Boolean) as Boolean {
        // mSunrise < mSunset 
        return !isAtDaylightTime(time, defValue);
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
