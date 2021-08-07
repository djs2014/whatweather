import Toybox.Graphics;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.Attention;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Position;

class WhatWeatherView extends WatchUi.DataField {
  // @@ cleanup
  hidden var mFont = Graphics.FONT_LARGE;
  hidden var mFontPostfix = Graphics.FONT_TINY;
  hidden var mFontSmall = Graphics.FONT_XTINY;
  hidden var mFontSmallH;

  hidden var ds as DisplaySettings;
  hidden var _currentInfo as CurrentInfo;

  hidden var _posnInfo as Info ? ;

  function initialize() {
    DataField.initialize();
    mFontSmallH = Graphics.getFontHeight(mFontSmall);

    _currentInfo = new CurrentInfo();
    ds = new DisplaySettings();
  }

  function onLayout(dc as Dc) as Void {}

  function compute(info as Activity.Info) as Void {
    _currentInfo.getPosition(info);
  }

  // Display the value you computed here. This will be called once a second when
  // the data field is visible.
  function onUpdate(dc as Dc) as Void {
    if (dc has :setAntiAlias) {
      dc.setAntiAlias(true);
    }

    var backgroundColor = getBackgroundColor();
    $._alertHandler.checkStatus();
    if ($._alertHandler.isAnyAlertTriggered()) {
      backgroundColor = Graphics.COLOR_YELLOW;
      playAlert();
      $._alertHandler.currentlyTriggeredHandled();
    }

    var nrOfColumns = $._maxHoursForecast;
    ds.setDc(dc, backgroundColor);
    ds.clearScreen();
  
    var heightWind = ($._showWind && !ds.smallField) ? 15 : 0;
    var heightWc = ($._showWeatherCondition && !ds.smallField) ? 15 : 0;
    var heightWt = (ds.oneField) ? dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY) : 0;
    if (heightWind > 0 || heightWc > 0 ) { $._dashesUnderColumnHeight = 0; }
    ds.calculate(nrOfColumns, heightWind, heightWc, heightWt);

    if ($._showGlossary && ds.oneField) {
      var render = new RenderWeather(dc, ds);
      render.drawGlossary();
      return;
    }

    GarminWeather.getLatestGarminWeather();
    onUpdateWeather(dc, ds);

    if ($._showMaxPrecipitationChance) {
      drawMaxPrecipitationChance(dc, ds.margin, ds.columnHeight,
                                 Graphics.COLOR_LT_GRAY,
                                 $._alertHandler.maxPrecipitationChance);
    }

    if ($._showAlertLevel) {
      drawWarningLevel(dc, ds.margin, ds.columnHeight, Graphics.COLOR_LT_GRAY,
                       $._alertLevelPrecipitationChance);
    }

    if ($._showPrecipitationChanceAxis) {
      drawPrecipitationChanceAxis(dc, ds.margin, ds.columnHeight);
    }

    showInfo(dc, ds);
  }

  function showInfo(dc as Dc, ds as DisplaySettings) as Void {
    var devSettings = System.getDeviceSettings();
    var info = "";
    var postfix = "";
    var showInfo = $._showInfo2;
    if (ds.smallField) {
      showInfo = $._showInfo;
    }
    switch (showInfo) {
      case SHOW_INFO_NOTHING:
        return;
      case SHOW_INFO_TIME_Of_DAY:
        var now = Calendar.info(Time.now(), Time.FORMAT_SHORT);
        var nowMin = now.min;
        var nowHour = now.hour;
        if (!devSettings.is24Hour) {
          if (!ds.smallField) {
            postfix = "am";
            if (nowHour > 12) {
              postfix = "pm";
            }
          }
          nowHour = (nowHour + 11).toNumber() % 12 + 1;
        }
        info = (nowHour.format("%02d") + ":" + nowMin.format("%02d"));
        break;
      case SHOW_INFO_ALTITUDE:
        var altitude = _currentInfo.altitude();
        if (altitude != null) {
          var currentAltitude = altitude;
          postfix = "m";
          if (devSettings.distanceUnits == System.UNIT_STATUTE) {
            postfix = "f";
            currentAltitude = meterToFeet(altitude);
          }
          info = currentAltitude.toNumber().toString();
        }
        break;
      case SHOW_INFO_HEADING:
        var compassDirection = _currentInfo.compassDirection();
        if (compassDirection != null) {
          info = compassDirection;
        }
        break;
      case SHOW_INFO_TEMPERATURE:
        var temperatureCelcius = _currentInfo.temperature();
        if (temperatureCelcius != null) {
          postfix = "°C";
          var temperature = temperatureCelcius;
          if (devSettings.distanceUnits == System.UNIT_STATUTE) {
            postfix = "°F";
            temperature = celciusToFarenheit(temperatureCelcius);
          }
          if (ds.smallField) {
            info = temperature.format("%.0f");
          } else {
            info = temperature.format("%.2f");
          }
        }
        break;
      case SHOW_INFO_HEARTRATE:
        var hr = _currentInfo.heartRate();
        if (hr != null) {
          postfix = "bpm";
          info = hr.format("%d");
        }
        break;
      case SHOW_INFO_AMBIENT_PRESSURE:
        var ap = _currentInfo.ambientPressure();
        if (ap != null) {
          // pascal -> mbar (hPa)
          postfix = "hPa";
          if (ds.smallField) {
            info = (ap / 100).format("%.0f");
          } else {
            info = (ap / 100).format("%.2f");
          }
        }
        break;
      case SHOW_INFO_DISTANCE:
        var distanceInKm = _currentInfo.elapsedDistance();
        if (distanceInKm != null) {
          postfix = "km";
          var distance = distanceInKm;
          if (devSettings.distanceUnits == System.UNIT_STATUTE) {
            postfix = "mi";
            distance = kilometerToMile(distanceInKm).format("%.2f");
          }
          if (ds.smallField) {
            info = distance.format("%.0f");
          } else {
            info = distance.format("%.2f");
          }
        }
        break;
    }

    if (info.length() == 0) {
      return;
    }
    var wi = dc.getTextWidthInPixels(info, mFont);
    var wp = dc.getTextWidthInPixels(postfix, mFontPostfix);
    var xi = ds.width / 2 - (wi + wp) / 2;
    dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
    dc.drawText(xi, ds.height / 2, mFont, info,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    dc.drawText(xi + wi + 1, ds.height / 2, mFontPostfix, postfix,
                Graphics.TEXT_JUSTIFY_LEFT);
  }

  function onUpdateWeather(dc as Dc, ds as DisplaySettings) as Void {
    var x = ds.columnX;
    var y = ds.columnY;
    var uvPoints = [];
    var tempPoints = [];
    var humidityPoints = [];
    var windPoints = [];
    var color;
    var precipitationChance;
    var mm = null;
    var current = null;
    var hourlyForecast = null;
    var previousCondition = -1;

    try {
      if ($._mostRecentData != null) {
        mm = $._mostRecentData.minutely;
        current = $._mostRecentData.current;
        hourlyForecast = $._mostRecentData.hourly;
      }

      var render = new RenderWeather(dc, ds);

      if ($._maxMinuteForecast > 0) {
        var xMMstart = x;
        var popTotal = 0;
        var columnWidth = 1;
        var offset = ($._maxMinuteForecast * columnWidth) + ds.space;
        ds.calculateColumnWidth(offset);
        if (mm != null) {
          var max = mm.pops.size();
          for (var i = 0; i < max && i < $._maxMinuteForecast; i += 1) {
            var pop = mm.pops[i];
            popTotal = popTotal + pop;
            if (DEBUG_DETAILS) {
              System.println(
                  Lang.format("minutely x[$1$] pop[$2$]", [ x, pop ]));
            }

            if ($._showColumnBorder) {
              drawColumnBorder(dc, x, ds.columnY, columnWidth, ds.columnHeight);
            }
            drawColumnPrecipitationMillimeters(dc, Graphics.COLOR_BLUE, x, y,
                                               columnWidth, ds.columnHeight,
                                               pop);
            x = x + columnWidth;
          }
          x = x + ds.space;
        }

        if ($._dashesUnderColumnHeight > 0) {
          dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
          dc.fillRectangle(xMMstart, ds.columnY + ds.columnHeight,
                           ($._maxMinuteForecast * columnWidth),
                           $._dashesUnderColumnHeight);
        }
        x = xMMstart + offset;
        $._alertHandler.processRainMMfirstHour(popTotal);
      }

      var validSegment = 0;
      if ($._showCurrentForecast) {
        if (current != null) {
          color = getConditionColor(current.condition, Graphics.COLOR_BLUE);
          if (DEBUG_DETAILS) {
            System.println(Lang.format("current x[$1$] pop[$2$] color[$3$]",
                                       [ x, current.info(), color ]));
          }

          precipitationChance = current.precipitationChance;

          $._alertHandler.processPrecipitationChance(precipitationChance);
          $._alertHandler.processWeather(color.toNumber());
          $._alertHandler.processUvi(current.uvi);
          $._alertHandler.processWindSpeed(current.windSpeed);

          validSegment = validSegment + 1;

          if ($._showComfort) {
            render.drawComfortColumn(x, current.temperature,
                                     current.relativeHumidity,
                                     precipitationChance);
          }

          if ($._showColumnBorder) {
            drawColumnBorder(dc, x, ds.columnY, ds.columnWidth,
                             ds.columnHeight);
          }

          if ($._showClouds) {
            drawColumnPrecipitationChance(dc, COLOR_CLOUDS, x, ds.columnY,
                                          ds.columnWidth, ds.columnHeight,
                                          current.clouds);
          }

          // rain
          drawColumnPrecipitationChance(dc, color, x, ds.columnY,
                                        ds.columnWidth, ds.columnHeight,
                                        precipitationChance);

          if ($._showUVIndexFactor > 0 && current.uvi != null) {
            var uvp = new UvPoint(x + ds.columnWidth / 2, current.uvi);
            uvp.calculateVisible(precipitationChance);
            uvPoints.add(uvp);
          }

          if ($._showTemperature) {
            tempPoints.add(
                new Point(x + ds.columnWidth / 2, current.temperature));
          }
          if ($._showRelativeHumidity) {
            humidityPoints.add(
                new Point(x + ds.columnWidth / 2, current.relativeHumidity));
          }
          if ($._showWind) {
            windPoints.add(
                new WindPoint(x, current.windBearing, current.windSpeed));
          }

          if ($._dashesUnderColumnHeight > 0) {
            color =
                getConditionColor(current.condition, Graphics.COLOR_DK_GRAY);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, ds.columnY + ds.columnHeight, ds.columnWidth,
                             $._dashesUnderColumnHeight);
          }

          if ($._showWeatherCondition) {
            render.drawWeatherCondition(x, current.condition);   
            if (previousCondition != current.condition) {
              render.drawWeatherConditionText(x, current.condition);
              previousCondition = current.condition;
            }
          }

          x = x + ds.columnWidth + ds.space;
        }
      }  // showCurrentForecast

      if (hourlyForecast != null) {
        var maxSegment = hourlyForecast.size();
        for (var segment = 0;
             validSegment < $._maxHoursForecast && segment < maxSegment;
             segment += 1) {
          var forecast = hourlyForecast[segment];
          if (DEBUG_DETAILS) {
            System.println(forecast.info());
          }

          // Only forecast for the future
          var fcTime = Calendar.info(forecast.forecastTime, Time.FORMAT_SHORT);
          if (forecast.forecastTime.compare(Time.now()) >= 0) {
            validSegment += 1;
            precipitationChance = forecast.precipitationChance;

            color = getConditionColor(forecast.condition, Graphics.COLOR_BLUE);

            $._alertHandler.processPrecipitationChance(precipitationChance);
            $._alertHandler.processWeather(color.toNumber());
            $._alertHandler.processUvi(forecast.uvi);
            $._alertHandler.processWindSpeed(forecast.windSpeed);

            if (DEBUG_DETAILS) {
              System.println(
                  Lang.format("valid hour x[$1$] hourly[$2$] color[$3$]",
                              [ x, forecast.info(), color ]));
            }
            if ($._showComfort) {
              render.drawComfortColumn(x, forecast.temperature,
                                       forecast.relativeHumidity,
                                       precipitationChance);
            }
            if ($._showColumnBorder) {
              drawColumnBorder(dc, x, ds.columnY, ds.columnWidth,
                               ds.columnHeight);
            }

            if ($._showClouds) {
              drawColumnPrecipitationChance(dc, COLOR_CLOUDS, x, ds.columnY,
                                            ds.columnWidth, ds.columnHeight,
                                            forecast.clouds);
            }
            // rain
            drawColumnPrecipitationChance(dc, color, x, ds.columnY,
                                          ds.columnWidth, ds.columnHeight,
                                          precipitationChance);

            if ($._showUVIndexFactor > 0 && forecast.uvi != null) {
              var uvp = new UvPoint(x + ds.columnWidth / 2, forecast.uvi);
              uvp.calculateVisible(precipitationChance);
              uvPoints.add(uvp);
            }
            if ($._showTemperature) {
              tempPoints.add(
                  new Point(x + ds.columnWidth / 2, forecast.temperature));
            }
            if ($._showRelativeHumidity) {
              humidityPoints.add(
                  new Point(x + ds.columnWidth / 2, forecast.relativeHumidity));
            }
            if ($._showWind) {
              windPoints.add(
                  new WindPoint(x, forecast.windBearing, forecast.windSpeed));
            }
            if ($._dashesUnderColumnHeight > 0) {
              color =
                  getConditionColor(forecast.condition, Graphics.COLOR_DK_GRAY);
              dc.setColor(color, Graphics.COLOR_TRANSPARENT);
              dc.fillRectangle(x, ds.columnY + ds.columnHeight, ds.columnWidth,
                               $._dashesUnderColumnHeight);
            }

            if ($._showWeatherCondition) {
              render.drawWeatherCondition(x, forecast.condition);
              if (previousCondition != forecast.condition) {
                render.drawWeatherConditionText(x, forecast.condition);
                previousCondition = forecast.condition;
               }
            }

            x = x + ds.columnWidth + ds.space;
          }
        }
      }  // hourlyForecast

      if ($._showUVIndexFactor > 0) {
        render.drawUvIndexGraph(uvPoints, $._showUVIndexFactor);
      }
      if ($._showTemperature) {
        render.drawTemperatureGraph(tempPoints, 1);
      }
      if ($._showRelativeHumidity) {
        render.drawHumidityGraph(humidityPoints, 1);
      }

      if ($._showComfort) {
        render.drawComfortZones();
      }

      if (current != null) {
        // Always show position of observation
        var distance = "";
        var distanceMetric = "km";
        var distanceInKm = 0;
        if (DEBUG_DETAILS) {
          System.println(_currentInfo.infoLocation());
        }
        if (_currentInfo.hasLocation()) {
          distanceInKm = getDistanceFromLatLonInKm(
              _currentInfo.lat, _currentInfo.lon, current.lat, current.lon);
          distance = distanceInKm.format("%.2f");
          var deviceSettings = System.getDeviceSettings();
          if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
            // 1 Mile = 1.609344 Kilometers
            distanceMetric = "mi";
            distance = kilometerToMile(distanceInKm).format("%.2f");
          }
          var bearing = getRhumbLineBearing(_currentInfo.lat, _currentInfo.lon,
                                            current.lat, current.lon);
          var compassDirection = getCompassDirection(bearing);
          render.drawObservationLocation(Lang.format(
              "$1$ $2$ ($3$)", [ distance, distanceMetric, compassDirection ]));
        }

        if ($._showObservationLocationName) {
          render.drawObservationLocation2(current.observationLocationName);
        }
        // render.drawBGserviceInformation();
        if ($._showObservationTime) {
          render.drawObservationTime(current.observationTime);
        }
      }

      if ($._showWind) {
        render.drawWindInfo(windPoints);
      }
      render.drawAlertMessages($._alertHandler.infoHandled());

    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function drawWarningLevel(dc, margin, bar_height, color, heightPerc) {
    if (heightPerc <= 0) {
      return;
    }

    var width = dc.getWidth();

    // integer division truncates the result, use float values
    var lineY = margin + bar_height - bar_height * (heightPerc / 100.0);

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(margin, lineY, width - margin, lineY);
  }

  function drawMaxPrecipitationChance(dc, margin, bar_height, color,
                                      precipitationChance) {
    var y = margin + bar_height - bar_height * (precipitationChance / 100.0) -
            mFontSmallH - 2;
    // Do not overwrite Location name
    if (y < (mFontSmallH + 10)) {
      return;
    }
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(margin, y, mFontSmall, precipitationChance.format("%02d"),
                Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawPrecipitationChanceAxis(dc, margin, bar_height) {
    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
    var width = dc.getWidth();
    var x2 = width - margin;
    var y100 = margin;
    dc.drawLine(0, y100, margin, y100);
    dc.drawLine(x2, y100, width, y100);
    var y75 = margin + bar_height - bar_height * 0.75;
    dc.drawLine(0, y75, margin, y75);
    dc.drawLine(x2, y75, width, y75);
    var y50 = margin + bar_height - bar_height * 0.5;
    dc.drawLine(0, y50, margin, y50);
    dc.drawLine(x2, y50, width, y50);
    var y25 = margin + bar_height - bar_height * 0.25;
    dc.drawLine(0, y25, margin, y25);
    dc.drawLine(x2, y25, width, y25);
    var y0 = margin + bar_height;
    dc.drawLine(0, y0, margin, y0);
    dc.drawLine(x2, y0, width, y0);
  }

  function drawColumnBorder(dc, x, y, width, height) {
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawRectangle(x, y, width, height);
  }

  function drawColumnPrecipitationChance(dc, color, x, y, bar_width, bar_height,
                                         precipitationChance) {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var barFilledHeight =
        bar_height -
        (bar_height - ((bar_height.toFloat() / 100.0) * precipitationChance));
    var barFilledY = y + bar_height - barFilledHeight;
    dc.fillRectangle(x, barFilledY, bar_width, barFilledHeight);
  }

  function drawColumnPrecipitationMillimeters(dc, color, x, y, bar_width,
                                              bar_height, popmm) {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var barFilledHeight =
        bar_height - (bar_height - ((bar_height.toFloat() / 100.0) * popmm));
    var barFilledY = y + bar_height - barFilledHeight;
    dc.fillRectangle(x, barFilledY, bar_width, barFilledHeight);
  }

  function playAlert() {
    if (Attention has : playTone) {
      Attention.playTone(Attention.TONE_CANARY);
    }
  }
}
