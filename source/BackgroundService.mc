import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Sensor;
import Toybox.Application.Storage;
import Toybox.Communications;

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
            var proxyUrl = Storage.getValue("openWeatherProxy");
            var proxyApiKey = Storage.getValue("openWeatherProxyAPIKey");
            var maxhours = Storage.getValue("openWeatherMaxHours");
            var minutely = Storage.getValue("openWeatherMinutely");
            var testScenario = Storage.getValue("testScenario");
 
        	System.println(Lang.format("Proxyurl[$1$] location [$2$] apiKey[$3$] apiVersion[$4$] maxhours[$5$] openWeatherMinutely[$6$] testScenario[$7$] openWeatherAlerts[$8$]",
                [proxyUrl, location , apiKey, apiVersion, maxhours, minutely, testScenario, true]));    

            if (apiKey == null) { apiKey=""; }            
            if (proxyUrl == null) { proxyUrl=""; }            
            if (proxyApiKey == null) { proxyApiKey=""; }
                        
            if (location  == null) { return CustomErrors.ERROR_BG_NO_POSITION; }
            if ((apiKey as String).length() == 0) { return CustomErrors.ERROR_BG_NO_API_KEY; }
            if ((proxyUrl as String).length() == 0) { return CustomErrors.ERROR_BG_NO_PROXY; }
            if (maxhours == null) { maxhours = 8; }
            if (minutely == null) { minutely = true; }            
            if (testScenario == null) { testScenario = 0; }
            var lat = (location as Array)[0] as Double;
            var lon = (location as Array)[1] as Double;
            if ((lat >= 179.99 || lat <= -179.99) && (lon >= 179.99 || lon <= -179.99)) {
                System.println("1 Invalid location lat[" + lat + "] lon[" + lon + "] exit background service");                
                return CustomErrors.ERROR_BG_NO_POSITION;
            }
            
            var params = {
                "proxy" => "2.0",
                "version" => apiVersion as String,
                "lat" => lat,
                "lon" => lon,
                "alerts" => true as Boolean,
                "maxhours" => maxhours as Number,
                "minutely" => minutely as Boolean,
                "testScenario" => testScenario as Number,
                "appid" => apiKey as String
            } as Lang.Dictionary<Lang.Object, Lang.Object>;		       
            requestOWMData(proxyUrl as String, proxyApiKey as String, params);	
            return 0;
        } catch(ex) {
            System.println("1");
            System.println(ex.getErrorMessage());
            ex.printStackTrace();
            return CustomErrors.ERROR_BG_EXCEPTION;
        }
    }

    function requestOWMData(proxy as String, proxyApiKey as String, params as Lang.Dictionary<Lang.Object, Lang.Object>) as Void {        		  
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
        Communications.makeWebRequest(url, params, options, responseCallBack);
   	}

    function onReceiveOpenWeatherResponse(responseCode as Lang.Number, responseData as Lang.Dictionary or Null or Lang.String) as Void {
        try { 
            var curTime = System.getClockTime();
            System.println("onReceiveOpenWeatherResponse time " + curTime.hour.format("%02d") + ":" + curTime.min.format("%02d") + ":" + curTime.sec.format("%02d"));
            System.println("onReceiveOpenWeatherResponse responseCode " + responseCode);
            if (responseCode == 200 && responseData != null) {
                System.println("onReceiveOpenWeatherResponse responseData not null");                
                Background.exit(responseData as PropertyValueType);                                         
            } else {
                System.println("Not 200");
                System.println(responseData);
                Background.exit(responseCode);
            }
        } catch(ex instanceof Background.ExitDataSizeLimitException ) {
            System.println(ex.getErrorMessage());
            ex.printStackTrace();
            Background.exit(CustomErrors.ERROR_BG_EXIT_DATA_SIZE_LIMIT);
        } catch(ex) {
            System.println(ex.getErrorMessage());
            ex.printStackTrace();
            //System.println(responseData);
            Background.exit(CustomErrors.ERROR_BG_EXCEPTION);
        }        
    }
}