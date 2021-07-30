using Toybox.System;
using Toybox.Math;
using Toybox.Lang;

function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
    return 0;
  }

  var R = 6371;                     // Radius of the earth in km
  var dLat = deg2rad(lat2 - lat1);  // deg2rad below
  var dLon = deg2rad(lon2 - lon1);
  var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
          Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  var d = R * c;  // Distance in km
  return d;
}

function deg2rad(deg) { return deg * (Math.PI / 180); }

function rad2deg(rad) { return rad * 180 / Math.PI; }

// http://www.dougv.com/2009/07/13/calculating-the-bearing-and-compass-rose-direction-between-two-latitude-longitude-coordinates-in-php/
function getRhumbLineBearing(lat1, lon1, lat2, lon2) {
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
    return 0;
  }

  // difference in longitudinal coordinates
  var dLon = deg2rad(lon2) - deg2rad(lon1);
  // difference in the phi of latitudinal coordinates
  var dPhi = Math.log(Math.tan(deg2rad(lat2) / 2 + Math.PI / 4) /
                          Math.tan(deg2rad(lat1) / 2 + Math.PI / 4),
                      Math.E);

  // we need to recalculate dLon if it is greater than pi
  if (dLon.abs() > Math.PI) {
    if (dLon > 0) {
      dLon = (2 * Math.PI - dLon) * -1;
    } else {
      dLon = 2 * Math.PI + dLon;
    }
  }
  // return the angle, normalized
  // not allowed to `modulo` double values, truncate the value to integer value
  return (rad2deg(Math.atan2(dLon, dPhi)) + 360).toNumber() % 360;
}

function getCompassDirection(bearing) {
  var direction = "";
  // Round and convert to number (1.00000 -> 1)
  switch (Math.round(bearing / 22.5).toNumber()) {
    case 1:
      direction = "NNE";
      break;
    case 2:
      direction = "NE";
      break;
    case 3:
      direction = "ENE";
      break;
    case 4:
      direction = "E";
      break;
    case 5:
      direction = "ESE";
      break;
    case 6:
      direction = "SE";
      break;
    case 7:
      direction = "SSE";
      break;
    case 8:
      direction = "S";
      break;
    case 9:
      direction = "SSW";
      break;
    case 10:
      direction = "SW";
      break;
    case 11:
      direction = "WSW";
      break;
    case 12:
      direction = "W";
      break;
    case 13:
      direction = "WNW";
      break;
    case 14:
      direction = "NW";
      break;
    case 15:
      direction = "NNW";
      break;
    default:
      direction = "N";
  }

  return direction;
}