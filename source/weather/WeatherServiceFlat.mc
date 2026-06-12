import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Remove forecasts from past hour
(:typecheck(disableBackgroundCheck))
function purgePastWeatherdataFlat(flatData as Dictionary?) as Dictionary {
    var size = $.getWeatherDataSize(flatData);
    if (size == 0) { 
        return {};
    }

    // Get start of the hour, minus 1 hour
    var nowSeconds = Time.now().value() - 3600;
    var cutOffTime = new Time.Moment(nowSeconds);
    if (DEBUG_DETAILS) {
        $.logInfo(
            "purgePastWeatherdata cutOffTime: " +
                $.getDateTimeString(cutOffTime)
        );
    }

    var hrDtArray = flatData[:hr_dt] as Array<Time.Moment>;
    var hrHourArray = flatData[:hr_hour] as Array<Lang.Number>;
    var hrCloudsArray = flatData[:hr_clouds] as Array<Lang.Number>;
    var hrPrecipitationChanceArray =
        flatData[:hr_precipitationChance] as Array<Lang.Number>;
    var hrConditionArray = flatData[:hr_condition] as Array<Lang.Number>;
    var hrUviArray = flatData[:hr_uvi] as Array<Lang.Float>;
    var hrWindSpeedArray = flatData[:hr_windSpeed] as Array<Lang.Float>;
    var hrWindBearingArray = flatData[:hr_windBearing] as Array<Lang.Number>;
    var hrTemperatureArray = flatData[:hr_temperature] as Array<Lang.Numeric>;
    var hrPressureArray = flatData[:hr_pressure] as Array<Lang.Number>;
    var hrRelativeHumidityArray =
        flatData[:hr_relativeHumidity] as Array<Lang.Number>;
    var hrDewPointArray = flatData[:hr_dewPoint] as Array<Lang.Float>;
    var hrRain1hrArray = flatData[:hr_rain1hr] as Array<Lang.Float>;
    var hrSnow1hrArray = flatData[:hr_snow1hr] as Array<Lang.Float>;
    var hrWindGustArray = flatData[:hr_windGust] as Array<Lang.Float>;

    var newIdx = -1;
    var max = hrDtArray.size();

    for (var idx = 0; idx < max; idx += 1) {
        if (DEBUG_DETAILS) {
            $.logInfo(
                "purgePastWeatherdata?: " +
                    $.getDateTimeString(hrDtArray[idx]) +
                    " cutOffTime: " +
                    $.getDateTimeString(cutOffTime)
            );
        }

        if (hrDtArray[idx].lessThan(cutOffTime)) {
            // Is a past hour, will be removed.
            if (DEBUG_DETAILS) {
                $.logInfo(
                    "purgePastWeatherdata past hour!: " +
                        $.getDateTimeString(hrDtArray[idx])
                );
            }
            newIdx = idx;
        }
    }

    if (newIdx > -1) {
        flatData[:hr_dt] = hrDtArray.slice(newIdx + 1, null);
        flatData[:hr_hour] = hrHourArray.slice(newIdx + 1, null);
        flatData[:hr_clouds] = hrCloudsArray.slice(newIdx + 1, null);
        flatData[:hr_precipitationChance] = hrPrecipitationChanceArray.slice(
            newIdx + 1,
            null
        );
        flatData[:hr_condition] = hrConditionArray.slice(newIdx + 1, null);
        flatData[:hr_uvi] = hrUviArray.slice(newIdx + 1, null);
        flatData[:hr_windSpeed] = hrWindSpeedArray.slice(newIdx + 1, null);
        flatData[:hr_windBearing] = hrWindBearingArray.slice(newIdx + 1, null);
        flatData[:hr_temperature] = hrTemperatureArray.slice(newIdx + 1, null);
        flatData[:hr_pressure] = hrPressureArray.slice(newIdx + 1, null);
        flatData[:hr_relativeHumidity] = hrRelativeHumidityArray.slice(
            newIdx + 1,
            null
        );
        flatData[:hr_dewPoint] = hrDewPointArray.slice(newIdx + 1, null);
        flatData[:hr_rain1hr] = hrRain1hrArray.slice(newIdx + 1, null);
        flatData[:hr_snow1hr] = hrSnow1hrArray.slice(newIdx + 1, null);
        flatData[:hr_windGust] = hrWindGustArray.slice(newIdx + 1, null);
        flatData[:changed] = true;
    }

    return flatData;
}

(:typecheck(disableBackgroundCheck))
function toWeatherDataFlat(data as Dictionary?) as Dictionary {
    if (data == null) {
        return {};
    }

    var flatData = {} as Dictionary;

    var bgData = data as Dictionary;
    var current = bgData["current"];
    var hourly = bgData["hourly"];
    var minutely = bgData["minutely"];
    var alerts = bgData["alerts"];

    if (current != null && current instanceof Dictionary) {
        var bg_cc = current as Dictionary;
        // var bg_hh = hourly as Array<Array<Numeric> >;

        flatData[:lat] = (
            $.getDictionaryValue(bg_cc, "lat", 0.0d) as Double
        ).toDouble();
        flatData[:lon] = (
            $.getDictionaryValue(bg_cc, "lon", 0.0d) as Double
        ).toDouble();
        flatData[:observationLocationName] =
            flatData[:lat] + "," + flatData[:lon];
        flatData[:observationTime] = new Time.Moment(
            $.getDictionaryValue(bg_cc, "dt", 0) as Number
        );

        //$.logInfo("OWM Observation: " + wo.info());
    }

    if (hourly != null && hourly instanceof Array) {
        var bg_hh = hourly as Array<Array>;
        /*
      // Get only the hours we need, start from current hour
      var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

      var todayStartOfhour = Gregorian.moment({
        :year => today.year,
        :month => today.month,
        :day => today.day,
        :hour => today.hour,
        :minute => 0,
        :second => 0,
      });

      var oneHour = Gregorian.duration({ :hours => 1 });
      var startTime = todayStartOfhour.subtract(oneHour);
      System.println(["OWM start time forecast hourly:", $.getDateTimeString(startTime)]);
        */

        // Get start of the hour, minus 1 hour
        var nowSeconds = Time.now().value() - 3600;
        var cutOffTime = new Time.Moment(nowSeconds);
        $.logInfo("OWM cutOffTime: " + $.getDateTimeString(cutOffTime));

        // Plus 1, for handling hour change. Not showing empty column
        var maxHoursDisplayed =
            ($.getStorageValue("openWeatherMaxHours", 1) as Number) + 1;

        var max = bg_hh.size();

        // Data per hour
        var hrDtArray = [] as Array<Time.Moment>;
        var hrHourArray = [] as Array<Lang.Number>;
        var hrCloudsArray = [] as Array<Lang.Number>;
        var hrPrecipitationChanceArray = [] as Array<Lang.Number>;
        var hrConditionArray = [] as Array<Lang.Number>;
        var hrUviArray = [] as Array<Lang.Float>;
        var hrWindSpeedArray = [] as Array<Lang.Float>;
        var hrWindBearingArray = [] as Array<Lang.Number>;
        var hrTemperatureArray = [] as Array<Lang.Numeric>;
        var hrPressureArray = [] as Array<Lang.Number>;
        var hrRelativeHumidityArray = [] as Array<Lang.Number>;
        var hrDewPointArray = [] as Array<Lang.Float>;
        var hrRain1hrArray = [] as Array<Lang.Float>;
        var hrSnow1hrArray = [] as Array<Lang.Float>;
        var hrWindGustArray = [] as Array<Lang.Float>;

        // There are only values in array to compress the payload
        for (var idx = 0; idx < max; idx++) {
            if (hrDtArray.size() > maxHoursDisplayed) {
                $.logInfo([
                    "OWM skip forecast:",
                    idx,
                    "max display:",
                    maxHoursDisplayed,
                ]);
                continue;
            }

            if (!(bg_hh[idx] instanceof Array)) {
                $.logInfo([
                    "OWM skip forecast, no data for hour or not an array:",
                    idx,
                ]);
                continue;
            }
            var arr = bg_hh[idx] as Array<Numeric>;
            var fcTime = new Time.Moment(
                ($.getNumericValueOrDefault(arr[0], 0) as Number).toNumber()
            );

            // Skip forecast of different days/previous hours
            if (fcTime.lessThan(cutOffTime)) {
                $.logInfo([
                    "OWM skip forecast hour:",
                    $.getDateTimeString(fcTime),
                ]);
                continue;
            }

            hrDtArray.add(fcTime);
            var today = Gregorian.info(fcTime, Time.FORMAT_MEDIUM);
            hrHourArray.add(today.hour);

            hrCloudsArray.add(
                ($.getNumericValueOrDefault(arr[1], 0) as Number).toNumber()
            );
            // OWM pop from o.o - 1
            hrPrecipitationChanceArray.add(
                (
                    ($.getNumericValueOrDefault(arr[2], 0.0f) as Float) * 100.0
                ).toNumber()
            );
            hrConditionArray.add(
                ($.getNumericValueOrDefault(arr[3], 0) as Number).toNumber()
            );
            hrUviArray.add(
                ($.getNumericValueOrDefault(arr[4], 0.0f) as Float).toFloat()
            );
            hrWindSpeedArray.add(
                ($.getNumericValueOrDefault(arr[5], 0.0f) as Float).toFloat()
            );
            hrWindBearingArray.add(
                ($.getNumericValueOrDefault(arr[6], 0) as Number).toNumber()
            );
            hrTemperatureArray.add(
                ($.getNumericValueOrDefault(arr[7], 0) as Number).toNumber()
            );
            hrPressureArray.add(
                ($.getNumericValueOrDefault(arr[8], 0) as Number).toNumber()
            );
            hrRelativeHumidityArray.add(
                ($.getNumericValueOrDefault(arr[9], 0) as Number).toNumber()
            );
            hrDewPointArray.add(
                ($.getNumericValueOrDefault(arr[10], 0.0f) as Float).toFloat()
            );
            hrRain1hrArray.add(
                ($.getNumericValueOrDefault(arr[11], 0.0f) as Float).toFloat()
            );
            hrSnow1hrArray.add(
                ($.getNumericValueOrDefault(arr[12], 0.0f) as Float).toFloat()
            );
            hrWindGustArray.add(
                ($.getNumericValueOrDefault(arr[13], 0.0f) as Float).toFloat()
            );

            //$.logInfo("OWM Hourly: " + hf.info());
        }

        flatData[:hr_dt] = hrDtArray;
        flatData[:hr_hour] = hrHourArray;
        flatData[:hr_clouds] = hrCloudsArray;
        flatData[:hr_precipitationChance] = hrPrecipitationChanceArray;
        flatData[:hr_condition] = hrConditionArray;
        flatData[:hr_uvi] = hrUviArray;
        flatData[:hr_windSpeed] = hrWindSpeedArray;
        flatData[:hr_windBearing] = hrWindBearingArray;
        flatData[:hr_temperature] = hrTemperatureArray;
        flatData[:hr_pressure] = hrPressureArray;
        flatData[:hr_relativeHumidity] = hrRelativeHumidityArray;
        flatData[:hr_dewPoint] = hrDewPointArray;
        flatData[:hr_rain1hr] = hrRain1hrArray;
        flatData[:hr_snow1hr] = hrSnow1hrArray;
        flatData[:hr_windGust] = hrWindGustArray;        
    }

    // Minutely (not in Garmin Data)
    flatData[:minutely_pops] = [] as Array<Numeric>;
    flatData[:minutely_max] = 0.0f;
    flatData[:minutely_dt] = null;
    if (minutely != null && minutely instanceof Dictionary) {
        var bg_mm = minutely as Dictionary;
        flatData[:minutely_pops] =
            $.getDictionaryValue(bg_mm, "pops", [] as Array<Numeric>) as
            Array<Numeric>;
        flatData[:minutely_max] =
            $.getDictionaryValue(bg_mm, "max", 0.0f) as Float;
        flatData[:minutely_dt] = new Time.Moment(
            $.getDictionaryValue(bg_mm, "dt_start", 0) as Number
        );

        $.logInfo("OWM size of minutely: " + flatData[:minutely_pops].size());
    }

    $.logInfo(["OWM Alerts", alerts]);

    var weatherAlerts = [] as Array<WeatherAlert>;
    if (alerts != null && alerts instanceof Array) {
        var bg_al = alerts as Array<Array>;
        for (var i = 0; i < bg_al.size(); i++) {
            var wal = new WeatherAlert();
            var warr = bg_al[i] as Array<Numeric or String>;
            wal.event =
                $.getStringValueOrDefault(warr[0] as String, "") as String;
            wal.start = new Time.Moment(
                (
                    $.getNumericValueOrDefault(warr[1] as Number, 0) as Number
                ).toNumber()
            );
            wal.end = new Time.Moment(
                (
                    $.getNumericValueOrDefault(warr[2] as Number, 0) as Number
                ).toNumber()
            );
            wal.description =
                $.getStringValueOrDefault(warr[3] as String, "") as String;
            wal.description = $.stringReplace(wal.description, "\n", " ");
            wal.description = $.stringReplace(wal.description, "\r", " ");
            $.logInfo("OWM Alert: " + wal.info());
            weatherAlerts.add(wal);
        }
    }

    flatData[:alerts] = weatherAlerts;
    flatData[:changed] = true;
    return flatData;
}