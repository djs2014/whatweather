import Toybox.Lang;
import Toybox.System;

(:background)
enum WeatherSource {
  wsGarminFirst = 0,
  wsOWMFirst = 1,
  wsGarminOnly = 2,
  wsOWMOnly = 3,
}

(:background)
enum apiVersion {
  owmOneCall25 = 0,
  owmOneCall30 = 1,
}
