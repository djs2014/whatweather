import Toybox.System;
import Toybox.Lang;

function stringReplace(str as String, oldString as String, newString as String) as String {
  var result = str;
  if (str.length() == 0 || oldString.length() == 0) {
    return str;
  }

  var index = result.find(oldString);
  var count = 0;
  while (index != null && count < 30) {
    var indexEnd = index + oldString.length();
    result = result.substring(0, index) + newString + result.substring(indexEnd, result.length());
    index = result.find(oldString);
    count = count + 1;
  }

  return result;
}

function stringLeft(str as String, marker as String, dflt as String) as String {
  if (str.length() == 0 || marker.length() == 0) {
    return dflt;
  }

  var index = str.find(marker);
  if (index == null) {
    return dflt;
  }
  return str.substring(0, index) as String;
}

function stringRight(
  str as String,
  marker as String,
  dflt as String
) as String {
  if (str.length() == 0 || marker.length() == 0) {
    return dflt;
  }

  var index = str.find(marker);
  if (index == null || index + 1 >= str.length()) {
    return dflt;
  }
  return str.substring(index + 1, str.length()) as String;
}

function stringReplaceAtInterval(str as String, nrOfChars as Number, newPart as String) as String {
  // split string in pieces of nrOfChars width
  var result = str;
  var cursor = 0;
  if (cursor + nrOfChars > str.length() || nrOfChars <= 0) {
    return result;
  }
  try {
    var part = str.substring(cursor, cursor + nrOfChars) as String;
    result = part;

    var remainingLength = str.length() - nrOfChars;
    while (remainingLength > 0) {
      cursor = cursor + nrOfChars;
      if (cursor > str.length()) {
        part = str.substring(cursor, str.length()) as String;
      } else {
        part = str.substring(cursor, cursor + nrOfChars) as String;
      }
      result = result + newPart + part;
      // System.println(result);
      remainingLength = remainingLength - nrOfChars;
      // System.println(remainingLength);
    }
  } catch (ex) {
    System.println(ex.getErrorMessage());
    ex.printStackTrace();
  }
  return result;
}
