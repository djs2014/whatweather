import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.Application.Storage;
using Toybox.System;

class CurrentInfo {
  hidden var _actiInfo as Activity.Info?;
  function initialize() {}

  // @@ cleanup
  function onCompute(info as Activity.Info) as Void {
    _actiInfo = info;
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

  function meanSeaLevelPressure() as Lang.Float? {
    if (_actiInfo != null) {
      var info = _actiInfo as Activity.Info;
      if (info has :meanSeaLevelPressure && info.meanSeaLevelPressure != null) {
        return info.meanSeaLevelPressure;
      }
    }

    return null;
  }

  // Distance in km
  function elapsedDistance() as Lang.Float? {
    var distance = null;
    if (_actiInfo != null) {
      var info = _actiInfo as Activity.Info;
      if (info has :elapsedDistance && info.elapsedDistance != null) {
        distance = (info.elapsedDistance as Float) / 1000.0;
      }
    }
    return distance;
  }

  function temperature() as Lang.Float? {
    return $.getStorageValue("Temperature", null) as Lang.Float?;
  }

  function activityIsPaused() as Boolean {
    if (_actiInfo != null) {
      if (_actiInfo has :timerState) {
        return _actiInfo.timerState == Activity.TIMER_STATE_PAUSED || _actiInfo.timerState == Activity.TIMER_STATE_OFF;
      }
    }
    return true;
  }
}
