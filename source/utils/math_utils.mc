import Toybox.System;
import Toybox.Lang;
using Toybox.Math;
module WhatAppBase {
  (:Utils)
  module Utils {
    function min(a as Numeric, b as Numeric) as Numeric {
      if (a <= b) {
        return a;
      } else {
        return b;
      }
    }

    function max(a as Numeric, b as Numeric) as Numeric {
      if (a >= b) {
        return a;
      } else {
        return b;
      }
    }

    function compareTo(numberA as Numeric, numberB as Numeric) as Numeric{
      if (numberA > numberB) {
        return 1;
      } else if (numberA < numberB) {
        return -1;
      } else {
        return 0;
      }
    }

    function percentageOf(value as Numeric?, max as Numeric?) as Numeric{
      if (value == null || max == null) {
        return 0.0f;
      }
      if (max <= 0) { return 0.0f; }
      return value / (max / 100.0);
    }

    function valueOfPercentage(percentage as Numeric?, maxValue as Numeric?) as Numeric {
      if (percentage == null || maxValue == null) { return maxValue;}
      return (maxValue * (percentage / 100.0));
    }

    // straight line formula y = slope * x + b;
    function slopeOfLine(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric) as Numeric {
      var rise_deltaY = y2 - y1;
      var run_deltaX = x2 - x1;
      if (run_deltaX == 0.0) {
        return 0.0f;
      }
      // integer division  * 1.0
      return (rise_deltaY.toFloat() / run_deltaX.toFloat());
    }

    function angleInDegreesBetweenXaxisAndLine(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric) as Numeric {
      var angleRadians = Math.atan2(y2 - y1, x2 - x1);
      return rad2deg(angleRadians);
    }
  }
}