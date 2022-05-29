import Toybox.Time;
import Toybox.Application;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time.Gregorian;

module WhatAppBase {
  (:Utils) 
  module Utils {
    typedef TimeValue as Number or Time.Moment;

    function isDelayedFor(timevalue as TimeValue?, minutesDelayed as Number) as Boolean {
      //! True if timevalue is later than now + minutesDelayed
      if (timevalue == null || minutesDelayed <= 0) {
        return false;
      }

      if (timevalue instanceof Lang.Number) {
        return (Time.now().value() - timevalue) > (minutesDelayed * 60);
      } else if (timevalue instanceof Time.Moment) {
        return Time.now().compare(timevalue) > (minutesDelayed * 60);
      }

      return false;
    }

    function ensureXSecondsPassed(previousMomentInSeconds as Number, seconds as Number) as Boolean {
      if (previousMomentInSeconds == null || previousMomentInSeconds <= 0) {
        return true;
      }
      var diff = Time.now().value() - previousMomentInSeconds;
      System.println("ensureXSecondsPassed difference: " + diff);
      return diff >= seconds;
    }

    function getDateTimeString(moment as Time.Moment?) as String {
      if (moment != null && moment instanceof Time.Moment) {
        var date = Gregorian.info(moment, Time.FORMAT_SHORT);
        // return date.day.format("%02d") + "-" + date.month.format("%02d") + "-" +
        //        date.year.format("%d") + " " + date.hour.format("%02d") + ":" +
        //        date.min.format("%02d") + ":" + date.sec.format("%02d");
        // @@ TODO debug what is value of date
        return 
               date.year.format("%d") + " " + date.hour.format("%02d") + ":" +
               date.min.format("%02d") + ":" + date.sec.format("%02d");
      }
      return "";
    }

    function getTimeString(moment as Time.Moment?) as String {
      if (moment != null && moment instanceof Time.Moment) {
        var date = Gregorian.info(moment, Time.FORMAT_SHORT);
        return date.hour.format("%02d") + ":" + date.min.format("%02d") + ":" +
               date.sec.format("%02d");
      }
       return "";
    }

    function getShortTimeString(moment as Time.Moment?) as String {
      if (moment != null && moment instanceof Time.Moment) {
        var date = Gregorian.info(moment, Time.FORMAT_SHORT);
        return date.hour.format("%02d") + ":" + date.min.format("%02d");
      }
       return "";
    }

    // template: "{h}:{m}:{s}:{ms}"
    function millisecondsToShortTimeString(totalMilliSeconds as Number, template as String) as String {
      if (totalMilliSeconds != null && totalMilliSeconds instanceof Lang.Number) {
        var hours = (totalMilliSeconds / (1000.0 * 60 * 60)).toNumber() % 24;
        var minutes = (totalMilliSeconds / (1000.0 * 60.0)).toNumber() % 60;
        var seconds = (totalMilliSeconds / 1000.0).toNumber() % 60;
        var mseconds = (totalMilliSeconds).toNumber() % 1000;

        if (template == null) { template = "{h}:{m}:{s}:{ms}"; }
        var time = stringReplace(template,"{h}", hours.format("%01d"));
        time = stringReplace(time,"{m}", minutes.format("%02d"));
        time = stringReplace(time,"{s}", seconds.format("%02d"));
        time = stringReplace(time,"{ms}", mseconds.format("%03d"));

        return time;  
      }
      return "";
    }
    // template: "{h}:{m}:{s}"
    function secondsToShortTimeString(totalSeconds as Number, template as String) as String {
      if (totalSeconds != null && totalSeconds instanceof Lang.Number) {
        var hours = (totalSeconds / (60 * 60)).toNumber() % 24;
        var minutes = (totalSeconds / 60.0).toNumber() % 60;
        var seconds = (totalSeconds.toNumber() % 60);

        if (template == null) { template = "{h}:{m}:{s}"; }
        var time = stringReplace(template,"{h}", hours.format("%01d"));
        time = stringReplace(time,"{m}", minutes.format("%02d"));
        time = stringReplace(time,"{s}", seconds.format("%02d"));

        return time;  
      }
      return "";
    }

    // 1:40 or 150:40 
    function secondsToCompactTimeString(totalSeconds as Number, template as String) as String {
      if (totalSeconds != null && totalSeconds instanceof Lang.Number) {
        var minutes = (totalSeconds / 60.0).toNumber();
        var seconds = (totalSeconds.toNumber() % 60);

        if (template == null) { template = "{h}:{m}:{s}"; }
        var time = stringReplace(template,"{m}", minutes.format("%01d"));
        time = stringReplace(time,"{s}", seconds.format("%02d"));

        return time;  
      }
      return "";
    }

    
  }
}