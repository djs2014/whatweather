import Toybox.Lang;
import Toybox.System;


var _Comfort as Comfort?;

(:typecheck(disableBackgroundCheck))
class Comfort {
  // perc 0 - 100;
  var humidityMin as Number = 40;
  var humidityMax as Number = 60;
  var temperatureMin as Number = 20;
  var temperatureMax as Number = 27;

  function initialize() {
  }
}

(:typecheck(disableBackgroundCheck))
function getComfort() as Comfort {
    if ($._Comfort == null) {
      $._Comfort = new Comfort();
    }
    return $._Comfort as Comfort;
}

    