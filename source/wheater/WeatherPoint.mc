import Toybox.Lang;

class WeatherPoint {
  var x as Lang.Number = 0;
  var value as Lang.Numeric = 0;
  var isHidden as Lang.Boolean;
  
  function initialize(x as Lang.Number, value as Lang.Numeric?, hideIfLowerThanValue as Lang.Number) {
    self.x = x;
    if (value != null) { self.value = value; }
    self.isHidden = self.value < hideIfLowerThanValue;
  }  
}