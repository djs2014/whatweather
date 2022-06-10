import Toybox.Lang;
import Toybox.System;
using WhatAppBase.Utils as Utils;

const COMFORT_NO = 0;
const COMFORT_BELOW = 1;
const COMFORT_NORMAL = 2;
const COMFORT_HIGH = 3;
var _Comfort as Comfort?;

(:typecheck(disableBackgroundCheck))
class Comfort {
  // perc 0 - 100;
  var humidityMin as Number = 40;
  var humidityMax as Number = 60;
  var temperatureMin as Number = 20;
  var temperatureMax as Number = 27;
  var precipitationChanceMin as Number = 0;
  var precipitationChanceMax as Number = 40;

  function initialize() {

  }

  static function getComfort() as Comfort {
    if ($._Comfort == null) {
      $._Comfort = new Comfort();
    }
    return $._Comfort;
  }

    // Somewhere from the internet.. Humans generally feel comfortable between
    // temperatures of 22 °C to 27 °C and a relative humidity of 40% to 60%.
    function convertToComfort(temperature as Lang.Number?, relativeHumidity as Lang.Number?, precipitationChance as Lang.Number?) as Lang.Number {
        if (temperature == null || relativeHumidity == null || precipitationChance == null) {
            return COMFORT_NO;
        }

        // var cTemp0 = temperatureMin;
        // var cTemp1 = temperatureMax;
        // var cHum0 = humidityMin;
        // var cHum1 = humidityMax;
        // var cPrec0 = precipitationChanceMin;
        // var cPrec1 = precipitationChanceMax;

        if (temperature < offsetValue(temperatureMin, 0.3) ||
            relativeHumidity < offsetValue(humidityMin, 0.3)) {
            return COMFORT_NO;
        }

        var tempLow = Utils.compareTo(temperature, temperatureMin);
        var tempHigh = Utils.compareTo(temperature, temperatureMax);

        var humLow = Utils.compareTo(relativeHumidity, humidityMin);
        var humHigh = Utils.compareTo(relativeHumidity, humidityMax);

        var popLow = Utils.compareTo(precipitationChance, precipitationChanceMin);
        var popHigh = Utils.compareTo(precipitationChance, precipitationChanceMax);

        var popIdx = calculateComfortIdxInverted(popLow, popHigh);
        if (popIdx < COMFORT_NORMAL) {
            return COMFORT_NO;
        }

        var tempIdx = calculateComfortIdx(tempLow, tempHigh);
        var humIdx = calculateComfortIdx(humLow, humHigh);
        // System.println("Comfort tempIdx:" + tempIdx + " humIdx:" + humIdx);

        if (tempIdx <= COMFORT_BELOW) {
            return COMFORT_BELOW;
        } else if (tempIdx == COMFORT_NORMAL) {
            if (humIdx <= COMFORT_NORMAL) {
            return COMFORT_NORMAL;
            } else {
            return COMFORT_HIGH;
            }
        } else {
            if (humIdx <= COMFORT_NORMAL) {
            return COMFORT_NORMAL;
            } else {
            return COMFORT_HIGH;
            }
        }     
    }
}