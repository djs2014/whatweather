import Toybox.Lang;
import Toybox.Graphics;

typedef Polygone as Lang.Array<Point2D>;

class Point {
  var x as Lang.Number = 0;
  var y as Lang.Number = 0;
  function initialize(x as Lang.Number, y as Lang.Number?) {
    self.x = x;
    if (y != null) { self.y = y; }
  }
  function toPoint2D() as Point2D { return [ x, y ] as Point2D; }
  function move(x as Lang.Number, y as Lang.Number) as Point { return new Point(self.x + x, self.y + y); }
}