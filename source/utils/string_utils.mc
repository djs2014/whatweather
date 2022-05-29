import Toybox.System;
import Toybox.Lang;

module WhatAppBase {
  (:Utils) 
  module Utils {

    function stringReplace(str as String, oldString as String, newString as String) as String {
      var result = str;
      if (str == null || oldString == null || newString == null) { return str; }

      var index = result.find(oldString);
      var count = 0;
      while (index != null && count < 30)
      {
        var indexEnd = index + oldString.length();
        result = result.substring(0, index) + newString + result.substring(indexEnd, result.length());
        index = result.find(oldString);
        count = count + 1;
      }

      return result;
    } 

  }
}