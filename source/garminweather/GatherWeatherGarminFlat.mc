import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

function calculateDewpoint(
    temperatureCelcius as Numeric?,
    relativeHumidity as Number?
) as Float {
    if (temperatureCelcius == null || relativeHumidity == null) {
        return 0.0f;
    }
    // https://learnmetrics.com/dew-point-calculator-chart-formula/
    return temperatureCelcius - (100 - (relativeHumidity as Number)) / 5.0f;
}

(:typecheck(false))
function getLatestGarminWeatherFlat() as Dictionary {
    // Garmin Weather API
    var garCurrent = Weather.getCurrentConditions();
    if (garCurrent == null) {
        return {};
    }
    var flatData = {};

    var position = garCurrent.observationLocationPosition;
    if (position != null) {
        var location = position.toDegrees();
        flatData[:lat] =
            $.getNumericValueOrDefault(location[0], 0.0d) as Lang.Double;
        flatData[:lon] =
            $.getNumericValueOrDefault(location[1], 0.0d) as Lang.Double;
    }

    flatData[:observationLocationName] =
        "G" + flatData[:lat] + "," + flatData[:lon];
    flatData[:observationTime] = garCurrent.observationTime;
    flatData[:tz_offset] = 0;

    // Data per hour
    flatData[:hr_dt] = [] as Array<Time.Moment>; // forecast Time
    flatData[:hr_hour] = [] as Array<Lang.Number>; // forecast Time hour only, for easy access
    flatData[:hr_clouds] = [] as Array<Lang.Number>;
    flatData[:hr_precipitationChance] = [] as Array<Lang.Number>;
    flatData[:hr_condition] = [] as Array<Lang.Number>;
    flatData[:hr_uvi] = [] as Array<Lang.Float>;
    flatData[:hr_windSpeed] = [] as Array<Lang.Float>;
    flatData[:hr_windBearing] = [] as Array<Lang.Number>;
    flatData[:hr_temperature] = [] as Array<Lang.Numeric>;
    flatData[:hr_pressure] = [] as Array<Lang.Number>;
    flatData[:hr_relativeHumidity] = [] as Array<Lang.Number>;
    flatData[:hr_dewPoint] = [] as Array<Lang.Float>;
    flatData[:hr_rain1hr] = [] as Array<Lang.Float>;
    flatData[:hr_snow1hr] = [] as Array<Lang.Float>;
    flatData[:hr_windGust] = [] as Array<Lang.Float>;

    // Minutely (not in Garmin Data)
    flatData[:minutely_pops] = [] as Array<Lang.Numeric>;
    flatData[:minutely_max] = 0.0f as Lang.Float;
    flatData[:minutely_dt] = null as Time.Moment?;

    // Get Hourly data
    var hourly = Weather.getHourlyForecast();
    if (hourly == null) {
        return flatData;
    }

    // 1. Get the current time in seconds
    // Note this is based on the position in the Simulator. Can be different from local time on pc!
    //var nowSec = Time.now().value();
    // 2. Truncate to the start of the current hour
    // (e.g., 14:35 becomes 14:00)
    // var currentHourStartSec =
    //     nowSec - (nowSec % Time.Gregorian.SECONDS_PER_HOUR);

    var nowSeconds = Time.now().value() - 3600;
    var cutOffTime = new Time.Moment(nowSeconds);
    if (DEBUG_DETAILS) {
        $.logInfo([
            "now sec",
            $.secondsToShortTimeString(nowSeconds, ""),
            "Gar cutOffTime: " + $.getDateTimeString(cutOffTime),
        ]);
    }
    // Plus 1, for handling hour change. Not showing empty column
    var maxHoursDisplayed =
        ($.getStorageValue("openWeatherMaxHours", 1) as Number) + 1;

    // 1. Create explicitly typed local arrays BEFORE the loop
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

    for (var i = 0; i < hourly.size(); i++) {
        if (hrDtArray.size() > maxHoursDisplayed) {
            // Use local array size
            $.logInfo("Reached max hours to display: " + maxHoursDisplayed);
            break;
        }

        var hfc = hourly[i] as HourlyForecast;
        if (hfc.forecastTime == null) {
            continue;
        }

        var forecastTime = hfc.forecastTime as Time.Moment;

        // Skip if the forecast hour is strictly before the current hour
        if (forecastTime.lessThan(cutOffTime)) {
            if (DEBUG_DETAILS) {
                $.logInfo([
                    "Gar skip forecast hour:",
                    $.getDateTimeString(forecastTime),
                ]);
            }
            continue;
        }
        if (DEBUG_DETAILS) {
            $.logInfo([
                "Garmin hourly forecast",
                i,
                $.getDateTimeString(forecastTime),
            ]);
        }

        // 2. Add to the local, explicitly-typed arrays
        hrDtArray.add(forecastTime);
        var today = Gregorian.info(forecastTime, Time.FORMAT_MEDIUM);
        hrHourArray.add(today.hour);

        if (hfc has :cloudCover) {
            hrCloudsArray.add(
                $.getNumericValueOrDefault(hfc.cloudCover, 0) as Lang.Number
            );
        } else {
            hrCloudsArray.add(0);
        }
        hrPrecipitationChanceArray.add(
            $.getNumericValueOrDefault(hfc.precipitationChance, 0) as
                Lang.Number
        );
        hrConditionArray.add(
            $.getNumericValueOrDefault(
                hfc.condition as Lang.Number?,
                Weather.CONDITION_UNKNOWN
            ) as Lang.Number
        );

        if (hfc has :uvIndex) {
            hrUviArray.add(
                $.getNumericValueOrDefault(hfc.uvIndex, 0.0f) as Lang.Float
            );
        } else {
            hrUviArray.add(0.0f);
        }

        hrWindSpeedArray.add(
            $.getNumericValueOrDefault(hfc.windSpeed, 0.0f) as Lang.Float
        );
        hrWindBearingArray.add(
            $.getNumericValueOrDefault(hfc.windBearing, 0) as Lang.Number
        );
        hrTemperatureArray.add(
            $.getNumericValueOrDefault(hfc.temperature, 0.0f) as Lang.Numeric
        );

        if (hfc has :pressure) {
            var pascal =
                $.getNumericValueOrDefault(hfc.pressure, 0) as Lang.Number;
            hrPressureArray.add(pascal / 100);
        } else {
            hrPressureArray.add(0);
        }

        hrRelativeHumidityArray.add(
            $.getNumericValueOrDefault(hfc.relativeHumidity, 0) as Lang.Number
        );

        if (hfc has :dewPoint) {
            hrDewPointArray.add(
                $.getNumericValueOrDefault(hfc.dewPoint, 0.0f) as Lang.Float
            );
        } else {
            hrDewPointArray.add(
                calculateDewpoint(hfc.temperature, hfc.relativeHumidity)
            );
        }

        hrRain1hrArray.add(0.0f);
        hrSnow1hrArray.add(0.0f);
        hrWindGustArray.add(0.0f);

        // Next hourly forecast
    }

    // 3. Shove the completed local arrays into the dictionary AFTER the loop
    // If inside the loop, it causes VS Code to slow down to a crawl,
    // because it can't infer the types of the arrays (since they are being built dynamically)
    // Or add: (:typecheck(false)) above the function to skip type checking.
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

    return flatData;
}
