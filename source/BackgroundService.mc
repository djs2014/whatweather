import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Sensor;
import Toybox.Application.Storage;
import Toybox.Communications;
using CommunicationsHelpers as Helpers;

(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {
    
    function initialize() {
        System.println("BackgroundServiceDelegate initialize");
        ServiceDelegate.initialize();        
    }

    public function onTemporalEvent() as Void {
        System.println("BackgroundServiceDelegate onTemporalEvent");

        var sensorInfo = Sensor.getInfo();
        if (sensorInfo has :temperature && sensorInfo.temperature != null) {
            Storage.setValue("Temperature", sensorInfo.temperature);            
        }

        Storage.setValue("BGError", "");
        var error = handleOWM();
        if (error != 0) {
            Storage.setValue("BGError", Helpers.getCommunicationError(error));
            Background.exit(error);
        }
    }

    function handleOWM() as Number {
        try {        

            var ws = Storage.getValue("weatherDataSource");
            if (ws != null && ws instanceof(Number)) {
                // wsGarminOnly = 2
                if (ws == wsGarminOnly) {
                    System.println("OWM disabled - wsGarminOnly");
                    Background.exit(0);
                    return 0;
                }
            }
                
            var location = Storage.getValue("latest_latlng");                                
            var apiKey = Storage.getValue("openWeatherAPIKey");
            var proxy = Storage.getValue("openWeatherProxy");
            var proxyApiKey = Storage.getValue("openWeatherProxyAPIKey");
            var maxhours = Storage.getValue("openWeatherMaxHours");

        	System.println(Lang.format("Proxyurl[$1$] location [$2$] apiKey[$3$] maxhours[$4$]",[proxy, location , apiKey, maxhours]));    

            if (apiKey == null) { apiKey=""; }            
            if (proxy == null) { proxy=""; }            
            if (proxyApiKey == null) { proxyApiKey=""; }
            // @@ check error codes
            if (location  == null) { return Helpers.CustomErrors.ERROR_BG_NO_POSITION; }
            if ((apiKey as String).length() == 0) { return Helpers.CustomErrors.ERROR_BG_NO_API_KEY; }
            if ((proxy as String).length() == 0) { return Helpers.CustomErrors.ERROR_BG_NO_PROXY; }
            if (maxhours == null) { maxhours = 8; }
            var lat = (location as Array)[0] as Double;
            var lon = (location as Array)[1] as Double;
            
            requestOWMData(lat, lon, apiKey as String, proxy as String, proxyApiKey as String, maxhours as Number);	

            return 0;
        } catch(ex) {
            ex.printStackTrace();
            return Helpers.CustomErrors.ERROR_BG_EXCEPTION;
        }
    }

    function requestOWMData(lat as Lang.Double, lon as Lang.Double, apiKey as Lang.String, proxy as Lang.String, proxyApiKey as Lang.String, maxhours as Lang.Number) as Void {
		System.println(Lang.format("requestOWMData proxyurl[$1$] location[$2$,$3$] apiKey[$4$] proxyApiKey[$5$] maxhours[$6$]", [proxy, lat, lon , apiKey, proxyApiKey, maxhours]));    
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => proxyApiKey
                },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON	
        };
        var responseCallBack = method(:onReceiveOpenWeatherResponse);

        // API DOC: https://openweathermap.org/api/one-call-api
        // OWM json is too big for connect IQ background app, so proxy needed to minify the json
		var url = proxy;        
        var params = {
            "lat" => lat,
            "lon" => lon,
            // "exclude" => "daily,alerts",
            // "units" => "metric",
            "maxhours" => maxhours,
            "appid" => apiKey
        };		       
        Communications.makeWebRequest(url, params, options, responseCallBack);
   	}

    function onReceiveOpenWeatherResponse(responseCode as Lang.Number, responseData as Lang.Dictionary or Null) as Void {
        if (responseCode == 200 && responseData != null) {
            try { 
                    // !! Do not convert responseData to string (println etc..) --> gives out of memory
                    //System.println(responseData);   --> gives out of memory
                    // var data = responseData as String;  --> gives out of memory
                    Background.exit(responseData as PropertyValueType);                     
                } catch(ex instanceof Background.ExitDataSizeLimitException ) {
                    ex.printStackTrace();
                    Background.exit(Helpers.CustomErrors.ERROR_BG_EXIT_DATA_SIZE_LIMIT);
                } catch(ex) {
                    System.println(responseData);
                    ex.printStackTrace();
                    Background.exit(Helpers.CustomErrors.ERROR_BG_EXCEPTION);
                }
        } else {
            System.println("Not 200");
            System.println(responseData);
            Background.exit(responseCode);
        }
    }
}