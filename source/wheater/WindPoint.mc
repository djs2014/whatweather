import Toybox.Lang;

class WindPoint {
    var x as Lang.Number = 0;
    var bearing as Lang.Number = 0;
    var speed as Lang.Float = 0.0;
    var gust as Lang.Float = 0.0;

    // TODO, calc y and arrow in onupdate 
    // var y as Lang.Number = 0;
    // var arrow as Polygon = [];
    
    function initialize(x as Lang.Number, bearing as Lang.Number?, speed as Lang.Float?, gust as Lang.Float?) {
        self.x = x;
        if (bearing != null) {
            self.bearing = bearing;
        }
        if (speed != null) {
            self.speed = speed;
        }
        if (gust != null) {
            self.gust = gust;
        }
    }
}