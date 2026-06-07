import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Application.Storage;
import Toybox.Communications;

(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        debugInfo("BackgroundServiceDelegate initialize");
        ServiceDelegate.initialize();
    }

    public function onTemporalEvent() as Void {
        debugInfo("onTemporalEvent start");
        checkMemory();
        
        // Check if the network is actually ready before spamming a request
        if (!System.getDeviceSettings().phoneConnected) {
            debugInfo("No phone connection, exiting background service");
            Background.exit(0);
            return;
        }

        var error = handleOWM();
        debugInfo("handleOWM with result code " + error);
        if (error != 0) {
            Background.exit(error);
        }

    }

    function handleOWM() as Number {
        try {
            var ws = Storage.getValue("weatherDataSource");
            if (ws != null && ws instanceof Number) {
                if (ws == wsGarminOnly) {
                    debugInfo("OWM disabled - wsGarminOnly");
                    Background.exit(0);
                    return 0;
                }
            }

            var location = Storage.getValue("latest_latlng");
            var apiKey = Storage.getValue("openWeatherAPIKey");
            var apiVersion = "2.5";
            var apiV = Storage.getValue("openWeatherAPIVersion");
            if (apiV != null && apiV instanceof Number) {
                if (apiV == owmOneCall30) {
                    apiVersion = "3.0";
                }
            }
            var proxyUrl = Storage.getValue("openWeatherProxy");
            var proxyApiKey = Storage.getValue("openWeatherProxyAPIKey");
            var maxhours = Storage.getValue("openWeatherMaxHours");
            var minutely = Storage.getValue("openWeatherMinutely");
            var testScenario = Storage.getValue("testScenario");

            debugInfo(
                Lang.format(
                    "Proxyurl[$1$] location [$2$] apiKey[$3$] apiVersion[$4$] maxhours[$5$] openWeatherMinutely[$6$] testScenario[$7$] openWeatherAlerts[$8$]",
                    [
                        proxyUrl,
                        location,
                        apiKey,
                        apiVersion,
                        maxhours,
                        minutely,
                        testScenario,
                        true,
                    ]
                )
            );

            if (apiKey == null) {
                apiKey = "";
            }
            if (proxyUrl == null) {
                proxyUrl = "";
            }
            if (proxyApiKey == null) {
                proxyApiKey = "";
            }

            if (location == null) {
                return CustomErrors.ERROR_BG_NO_POSITION;
            }
            if ((apiKey as String).length() == 0) {
                return CustomErrors.ERROR_BG_NO_API_KEY;
            }
            if ((proxyUrl as String).length() == 0) {
                return CustomErrors.ERROR_BG_NO_PROXY;
            }
            if (maxhours == null) {
                maxhours = 8;
            }
            if (minutely == null) {
                minutely = true;
            }
            if (testScenario == null) {
                testScenario = 0;
            } else if ((testScenario as Number) > 0) {
                Storage.setValue("testScenario", 0);
            }
            var lat = (location as Array)[0] as Double;
            var lon = (location as Array)[1] as Double;
            if (
                (lat >= 179.99 || lat <= -179.99) &&
                (lon >= 179.99 || lon <= -179.99)
            ) {
                debugInfo(
                    "Invalid location lat[" +
                        lat +
                        "] lon[" +
                        lon +
                        "] exit background service"
                );
                return CustomErrors.ERROR_BG_NO_POSITION;
            }

            var params =
                ({
                    "proxy" => "2.0",
                    "version" => apiVersion as String,
                    "lat" => lat,
                    "lon" => lon,
                    "alerts" => true as Boolean,
                    "maxhours" => maxhours as Number,
                    "minutely" => minutely as Boolean,
                    "testScenario" => testScenario as Number,
                    "appid" => apiKey as String,
                }) as Lang.Dictionary<Lang.Object, Lang.Object>;
            requestOWMData(proxyUrl as String, proxyApiKey as String, params);
            return 0;
        } catch (ex) {
            debugInfo(ex.getErrorMessage());
            ex.printStackTrace();
            return CustomErrors.ERROR_BG_EXCEPTION;
        }
    }

    function requestOWMData(
        proxy as String,
        proxyApiKey as String,
        params as Lang.Dictionary<Lang.Object, Lang.Object>
    ) as Void {
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Accept" => "application/json",
                "Authorization" => proxyApiKey,
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };
        var responseCallBack = method(:onReceiveOpenWeatherResponse);

        // API DOC: https://openweathermap.org/api/one-call-api
        // OWM json is too big for connect IQ background app, so proxy needed to minify the json
        var url = proxy;
        Communications.makeWebRequest(url, params, options, responseCallBack);
        debugInfo("OWM request sent");
    }

    function onReceiveOpenWeatherResponse(
        responseCode as Lang.Number,
        data as Lang.Dictionary?
    ) as Void {
        try {
            debugInfo(
                "onReceiveOpenWeatherResponse responseCode " + responseCode
            );
        
            checkMemory();
        
            if (responseCode == 200 && data != null) {
                debugInfo(
                    "OWM data received successfully, exiting background with data"
                );
                Background.exit(data);
            } else {
                debugInfo(
                    "Failed to receive OWM data, exiting background with error code " +
                        responseCode
                );
                Background.exit(responseCode);
            }
        } catch (ex instanceof Background.ExitDataSizeLimitException) {
            debugInfo(ex.getErrorMessage());
            ex.printStackTrace();
            Background.exit(CustomErrors.ERROR_BG_EXIT_DATA_SIZE_LIMIT);
        } catch (ex) {
            debugInfo(ex.getErrorMessage());
            ex.printStackTrace();
            debugInfo("Response Data: " + data);
            Background.exit(CustomErrors.ERROR_BG_EXCEPTION);
        }
    }

    function debugInfo(info) as Void {
        var clockTime = System.getClockTime();

        var timeString = Lang.format("$1$:$2$:$3$ - background - $4$", [
            clockTime.hour.format("%02d"),
            clockTime.min.format("%02d"),
            clockTime.sec.format("%02d"),
            info,
        ]);

        System.println(timeString);
    }

    function checkMemory() {
        var stats = System.getSystemStats();

        // SystemStats returns bytes, so dividing by 1024 converts it to Kilobytes (KB)
        debugInfo("Used Memory: " + stats.usedMemory / 1024 + " KB");
        debugInfo("Free Memory: " + stats.freeMemory / 1024 + " KB");
        debugInfo("Total Memory: " + stats.totalMemory / 1024 + " KB");
    }
}
