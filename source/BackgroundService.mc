import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Sensor;
import Toybox.Application.Storage;
import Toybox.Communications;
// using CommunicationsHelpers as Helpers;

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
       
        System.println("BackgroundServiceDelegate handleOWM");
        var error = handleOWM();
        System.println("BackgroundServiceDelegate result handleOWM " + error);
        if (error != 0) {            
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
            var apiVersion = "2.5";
            var apiV = Storage.getValue("openWeatherAPIVersion");
            if (apiV != null && apiV instanceof(Number)) {
                if (apiV == owmOneCall30) {
                    apiVersion = "3.0";
                }
            }
            var proxy = Storage.getValue("openWeatherProxy");
            var proxyApiKey = Storage.getValue("openWeatherProxyAPIKey");
            var maxhours = Storage.getValue("openWeatherMaxHours");

        	System.println(Lang.format("Proxyurl[$1$] location [$2$] apiKey[$3$] apiVersion[$4$] maxhours[$5$]",[proxy, location , apiKey, apiVersion, maxhours]));    

            if (apiKey == null) { apiKey=""; }            
            if (proxy == null) { proxy=""; }            
            if (proxyApiKey == null) { proxyApiKey=""; }
                        
            if (location  == null) { return CustomErrors.ERROR_BG_NO_POSITION; }
            if ((apiKey as String).length() == 0) { return CustomErrors.ERROR_BG_NO_API_KEY; }
            if ((proxy as String).length() == 0) { return CustomErrors.ERROR_BG_NO_PROXY; }
            if (maxhours == null) { maxhours = 8; }
            var lat = (location as Array)[0] as Double;
            var lon = (location as Array)[1] as Double;
            
            requestOWMData(lat, lon, apiKey as String, apiVersion as String, proxy as String, proxyApiKey as String, maxhours as Number);	

            return 0;
        } catch(ex) {
            System.println("1");
            System.println(ex.getErrorMessage());
            ex.printStackTrace();
            return CustomErrors.ERROR_BG_EXCEPTION;
        }
    }

    function requestOWMData(lat as Lang.Double, lon as Lang.Double, apiKey as Lang.String, apiVersion as Lang.String, proxy as Lang.String, proxyApiKey as Lang.String, maxhours as Lang.Number) as Void {
		System.println(Lang.format("requestOWMData proxyurl[$1$] location[$2$,$3$] apiKey[$4$] apiVersion[$5$] proxyApiKey[$6$] maxhours[$7$]", [proxy, lat, lon , apiKey, apiVersion, proxyApiKey, maxhours]));    
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Accept" => "application/json",
                "Authorization" => proxyApiKey
                },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON	
        };
        var responseCallBack = method(:onReceiveOpenWeatherResponse);

        // API DOC: https://openweathermap.org/api/one-call-api
        // OWM json is too big for connect IQ background app, so proxy needed to minify the json
		var url = proxy;        
        var params = {
            "version" => apiVersion,
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
        System.println("onReceiveOpenWeatherResponse responseCode " + responseCode);
        if (responseCode == 200 && responseData != null) {
            try { 
                    System.println("onReceiveOpenWeatherResponse responseData not null");
                    // !! Do not convert responseData to string (println etc..) --> gives out of memory
                    //System.println(responseData);   --> gives out of memory
                    // var data = responseData as String;  --> gives out of memory
                    Background.exit(responseData as PropertyValueType);                     
                } catch(ex instanceof Background.ExitDataSizeLimitException ) {
                    System.println("2a");
                    System.println(ex.getErrorMessage());
                    ex.printStackTrace();
                    Background.exit(CustomErrors.ERROR_BG_EXIT_DATA_SIZE_LIMIT);
                } catch(ex) {
                    System.println("2b");
                    System.println(ex.getErrorMessage());
                    ex.printStackTrace();
                    //System.println(responseData);
                    Background.exit(CustomErrors.ERROR_BG_EXCEPTION);
                }
        } else {
            System.println("Not 200");
            System.println(responseData);
            Background.exit(responseCode);
        }
    }
}