import Toybox.Lang;
import Toybox.Application;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Activity;
import Toybox.Application.Properties;

function getApplicationProperty(
  key as Application.PropertyKeyType,
  dflt as Application.PropertyValueType
) as Application.PropertyValueType {
 try {
    var val = Properties.getValue(key);
    if (val != null) {
      return val;
    }
  } catch (e) {
    return dflt;
  }
  return dflt;
}

function getDictionaryValue(data as Dictionary, key as String, defaultValue as Object?) as Object? {
  var value = data.get(key);
  if (value == null) {
    return defaultValue;
  }
  return value as Numeric;
}

// function getStorageValue(
//   key as Application.PropertyKeyType,
//   dflt as Application.PropertyValueType
// ) as Application.PropertyValueType {
//   try {
//     var val = Toybox.Application.Storage.getValue(key);
//     if (val != null) {
//       return val;
//     }
//   } catch (e) {
//     return dflt;
//   }
//   return dflt;
// }

function getNumericValueOrDefault(value as Numeric?, def as Numeric?) as Numeric? {
  if (value == null) {
    return def;
  }
  return value;
}

function getStringValueOrDefault(value as String?, def as String?) as String? {
  if (value == null) {
    return def;
  }
  return value;
}

function getActivityValue(
  info as Activity.Info?,
  symbol as Symbol,
  dflt as Lang.Object
) as Lang.Object {
  if (info == null) {
    return dflt;
  }
  var ainfo = info as Activity.Info;

  if (ainfo has symbol) {
    if (ainfo[symbol] != null) {
      return ainfo[symbol] as Lang.Object;
    }
  }
  return dflt;
}

// Note key contains `storageKey|index` or `storageKey`
function getStorageValue(
  key as Application.PropertyKeyType,
  dflt as Application.PropertyValueType
) as Application.PropertyValueType {
  try {
    // Check if key contains index (for array)
    var idx = $.stringRight(key, "|", "").toNumber();
    System.println(["getStorageValue key -> idx", key, idx]);
    if (idx == null || idx == "") {
      var val = Toybox.Application.Storage.getValue(key);
      if (val != null) {
        return val;
      }
      return dflt;
    }

    // Get the value from the stored array
    var storageKey = $.stringLeft(key, "|", key);
    System.println(["getStorageValue storageKey", storageKey]);
    var array = Toybox.Application.Storage.getValue(storageKey);
    if (array != null) {
      if (idx > -1 && idx < array.size()) {
        return array[idx];
      }
    }
  } catch (ex) {
    return dflt;
  }
  return dflt;
}

// Save a number value in array and save to storage
// Note key contains `storageKey|index` or `storageKey`
function setStorageValueOrArray(
  key as String,
  value as Application.PropertyValueType
) as Void {
  if (key == "") {
    return;
  }

  // Extract selected storage key and index
  var storageKey = $.stringLeft(key, "|", key);
  var idx = $.stringRight(key, "|", "").toNumber();
  System.println(["setStorageValueOrArray storageKey|idx", storageKey, idx]);
  if (idx == null || idx == "") {
    Storage.setValue(storageKey, value);
    return;
  }

  System.println(["setStorageValueArray:", storageKey, idx, value]);

  // Get current array
  var array =
    $.getStorageValue(storageKey, []) as Array<Application.PropertyValueType>;
  if (idx > -1 && idx < array.size()) {
    // Update array
    array[idx] = value;
    Storage.setValue(
      storageKey,
      array //as Lang.Array<Application.PropertyValueType>
    );
  }
}

// Objects are passed by reference
function ensureArraySize(
  array as Array<Application.PropertyValueType>,
  size as Number,
  value as Application.PropertyValueType
) as Boolean {
  var changed = false;
  while (array.size() < size) {
    array.add(value);
    changed = true;
  }
  return changed;
}