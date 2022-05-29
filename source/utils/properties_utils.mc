import Toybox.Lang;
import Toybox.Application;
import Toybox.System;
import Toybox.Application.Storage;
module WhatAppBase {
  (:Utils) 
  module Utils {

    function getApplicationProperty(key as Application.PropertyKeyType, dflt as Application.PropertyValueType ) as Application.PropertyValueType {
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