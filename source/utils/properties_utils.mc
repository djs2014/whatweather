// Version 1.0.1
import Toybox.Lang;
import Toybox.Application;
import Toybox.System;
import Toybox.Application.Storage;
module WhatAppBase {
  (:Utils) 
  module Utils {

    

    function getApplicationPropertyAsNumber(key as Application.PropertyKeyType, dflt as Lang.Number) as Lang.Number {
      try {
        var val = Toybox.Application.Properties.getValue(key);
        if (val != null || !(val instanceof Number)) { 
          System.println("Use default property value [" + key + "]");
          return val.toNumber();
        }
      } catch (e) {
        return dflt;
      }
      return dflt;
    }

    function getApplicationPropertyAsString(key as Application.PropertyKeyType, dflt as Lang.String) as Lang.String {
      try {
        var val = Toybox.Application.Properties.getValue(key);
        if (val != null || !(val instanceof String)) { 
          System.println("Use default property value [" + key + "]");
          return val as String;
        }
      } catch (e) {
        return dflt;
      }
      return dflt;
    }

    function getApplicationPropertyAsBoolean(key as Application.PropertyKeyType, dflt as Lang.Boolean) as Lang.Boolean {
      try {
        var val = Toybox.Application.Properties.getValue(key);
        if (val != null || !(val instanceof Boolean)) { 
          System.println("Use default property value [" + key + "]");
          return val as Boolean;
        }
      } catch (e) {
        return dflt;
      }
      return dflt;
    }

    function getApplicationProperty(key as Application.PropertyKeyType, dflt as Application.PropertyValueType) as Application.PropertyValueType {
      try {
        var val = Toybox.Application.Properties.getValue(key);
        if (val != null) { return val; }
      } catch (e) {
        return dflt;
      }
      return dflt;
    }

    function getDictionaryValue(data as Dictionary, key as String, defaultValue as Numeric?) as Numeric? {
      var value = data.get(key);
      if (value == null) { return defaultValue; }
      return value as Numeric;
    }

    function setProperty(key as PropertyKeyType, value as PropertyValueType) as Void {
      Application.Properties.setValue(key, value);
    }

    function getStorageValue(key as Application.PropertyKeyType, dflt as Application.PropertyValueType ) as Application.PropertyValueType {
      try {
        var val = Toybox.Application.Storage.getValue(key);
        if (val != null) { return val; }
      } catch (e) {
        return dflt;
      }
      return dflt;
    }

    function getNumericValue(value as Numeric?, def as Numeric?) as Numeric? {
      if (value == null) {
        return def;
      }
      return value;
    }

    function getStringValue(value as String?, def as String?) as String? {
      if (value == null) {
        return def;
      }
      return value;
    }

  }
}