import Toybox.Time;
import Toybox.Application;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time.Gregorian;

typedef TimeValue as Number or Time.Moment;

function isDelayedFor(
  timeValue as TimeValue?,
  minutesDelayed as Number
) as Boolean {
  //! True if timevalue is later than now + minutesDelayed
  if (timeValue == null || minutesDelayed <= 0) {
    return false;
  }

  if (timeValue instanceof Lang.Number) {
    return Time.now().value() - timeValue > minutesDelayed * 60;
  } else if (timeValue instanceof Time.Moment) {
    return Time.now().compare(timeValue) > minutesDelayed * 60;
  }

  return false;
}

function getMinutesDelayed(timeValue as TimeValue?) as Number {
  if (timeValue == null) {
    return 0;
  }

  var differenceInSeconds = 0;
  if (timeValue instanceof Lang.Number) {
    differenceInSeconds = Time.now().value() - timeValue;
  } else if (timeValue instanceof Time.Moment) {
    differenceInSeconds =
      Time.now().value() - (timeValue as Time.Moment).value();
  }

  if (differenceInSeconds <= 0) {
    return 0;
  }
  return (differenceInSeconds / 60).toNumber();
}

function ensureXSecondsPassed(
  previousMomentInSeconds as Number,
  seconds as Number
) as Boolean {
  if (previousMomentInSeconds == null || previousMomentInSeconds <= 0) {
    return true;
  }
  var diff = Time.now().value() - previousMomentInSeconds;
  // System.println("ensureXSecondsPassed difference: " + diff);
  return diff >= seconds;
}

function getDateTimeString(moment as Time.Moment?) as String {
  if (moment != null && moment instanceof Time.Moment) {
    var start = Gregorian.info(moment, Time.FORMAT_SHORT);
    return Lang.format("$1$-$2$-$3$ $4$:$5$:$6$", [
      start.year,
      start.month,
      start.day,
      start.hour.format("%02d"),
      start.min.format("%02d"),
      start.sec.format("%02d"),
    ]);
  }
  return "";
}

function getTimeString(moment as Time.Moment?) as String {
  if (moment != null && moment instanceof Time.Moment) {
    var date = Gregorian.info(moment, Time.FORMAT_SHORT);
    return (
      date.hour.format("%02d") +
      ":" +
      date.min.format("%02d") +
      ":" +
      date.sec.format("%02d")
    );
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
function millisecondsToShortTimeString(
  totalMilliSeconds as Numeric?,
  template as String
) as String {
  if (totalMilliSeconds == null) {
    return "";
  }

  var totalMilliSecondsInt = totalMilliSeconds.toNumber();

  var hours = ((totalMilliSecondsInt / 3600000).toNumber() % 24).toNumber(); // (1000 * 60 * 60)
  var minutes = ((totalMilliSecondsInt / 60000).toNumber() % 60).toNumber(); // (1000 * 60)
  var seconds = ((totalMilliSecondsInt / 1000).toNumber() % 60).toNumber();
  var mseconds = (totalMilliSecondsInt.toNumber() % 1000).toNumber();

  if (template.length() == 0) {
    template = "{h}:{m}:{s}:{ms}";
  }
  var time = stringReplace(template, "{h}", hours.format("%01d"));
  time = stringReplace(time, "{m}", minutes.format("%02d"));
  time = stringReplace(time, "{s}", seconds.format("%02d"));
  time = stringReplace(time, "{ms}", mseconds.format("%03d"));

  return time;
}

// template: "{h}:{m}:{s}"
function secondsToShortTimeString(
  totalSeconds as Numeric?,
  template as String
) as String {
  if (totalSeconds == null) {
    return "";
  }
  var totalSecondsInt = totalSeconds.toNumber();

  var hours = ((totalSecondsInt / 3600).toNumber() % 24).toNumber();
  var minutes = ((totalSecondsInt / 60).toNumber() % 60).toNumber();
  var seconds = (totalSecondsInt.toNumber() % 60).toNumber();

  if (template.length() == 0) {
    template = "{h}:{m}:{s}";
  }
  var time = stringReplace(template, "{h}", hours.format("%01d"));
  time = stringReplace(time, "{m}", minutes.format("%02d"));
  time = stringReplace(time, "{s}", seconds.format("%02d"));

  return time;
}

// 1:40 or 150:40
function secondsToCompactTimeString(
  totalSeconds as Numeric?,
  template as String
) as String {
  if (totalSeconds == null) {
    return "";
  }
  // Force conversion to a standard integer Number to prevent UnexpectedTypeException
  var totalSecondsInt = totalSeconds.toNumber();

  var minutes = ((totalSecondsInt / 60).toNumber() % 60).toNumber();
  var timeString = stringReplace(template, "{m}", minutes.format("%01d"));

  var seconds = (totalSecondsInt.toNumber() % 60).toNumber();
  timeString = stringReplace(timeString, "{s}", seconds.format("%02d"));

  return timeString;
}

function getLongTimeString(moment as Time.Moment?) as String {
  if (moment != null && moment instanceof Time.Moment) {
    var date = Gregorian.info(moment, Time.FORMAT_SHORT);
    return (
      date.day.format("%02d") +
      "-" +
      date.month.format("%02d") +
      "-" +
      date.year.format("%02d") +
      " " +
      date.hour.format("%02d") +
      ":" +
      date.min.format("%02d")
    );
  }
  return "";
}
