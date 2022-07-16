import Toybox.Lang;
import Toybox.System;
using WhatAppBase.Utils as Utils;

var _Comfort as Comfort?;

(:typecheck(disableBackgroundCheck))
class Comfort {
  // perc 0 - 100;
  var humidityMin as Number = 40;
  var humidityMax as Number = 60;
  var temperatureMin as Number = 20;
  var temperatureMax as Number = 27;
//   var precipitationChanceMin as Number = 0;
//   var precipitationChanceMax as Number = 40;

  function initialize() {

  }

  static function getComfort() as Comfort {
    if ($._Comfort == null) {
      $._Comfort = new Comfort();
    }
    return $._Comfort;
  }

    
}