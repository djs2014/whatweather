import Toybox.Lang;

typedef Coordinate as Lang.Array<Lang.Number>;
typedef Polygone as Lang.Array<Coordinate>;

class Point {
  var x as Lang.Number = 0;
  var y as Lang.Number = 0;
  function initialize(x as Lang.Number, y as Lang.Number?) {
    self.x = x;
    if (y != null) { self.y = y; }
  }
  function toCoordinate() as Coordinate { return [ x, y ] as Coordinate; }
  function move(x as Lang.Number, y as Lang.Number) as Point { return new Point(self.x + x, self.y + y); }
}