import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.System;
import Toybox.Background;
import Toybox.Sensor;
import Toybox.Application.Storage;
import Toybox.Communications;
using CommunicationsHelpers as Helpers;
// Background not allowed to have GPS access, but can get last known position
// import Toybox.Position;

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

        handleOWM();
        // check phone
        // use location from storage
        
    }

    function handleOWM() {
         try { 

             if (DEBUG_DETAILS) { System.println("BackgroundServiceDelegate handleOWM"); }

        var location  = Storage.getValue("latest_latlng");
    	// var positionInfo = Position.getInfo();
      	// if (positionInfo has :position && positionInfo.position != null) {
        // 	location = positionInfo.position.toDegrees();  	
    	// }   
    	

		var apiKey = Storage.getValue("openWeatherAPIKey");
        var proxy = Storage.getValue("openWeatherProxy");
        var proxyApiKey = Storage.getValue("openWeatherProxyAPIKey");
        
        if (location  == null || apiKey == null || apiKey.length() == 0 || proxy == null || proxy.length() == 0) {     
        	System.println( Lang.format("Warning proxyurl[$1$] location [$2$] apiKey[$3$]",[proxy, location , apiKey]));    
            if (location  == null) {Background.exit(Helpers.CustomErrors.ERROR_BG_NO_POSITION);}
            if (apiKey == null || apiKey.length() == 0) {Background.exit(Helpers.CustomErrors.ERROR_BG_NO_API_KEY);}
            Background.exit(Helpers.CustomErrors.ERROR_BG_NO_PROXY);
        }
		
        if (proxyApiKey == null) {proxyApiKey="";}
		var lat = location[0];
		var lon = location[1];
		requestOWMData(lat, lon, apiKey, proxy, proxyApiKey);	
         } catch(ex) {
                ex.printStackTrace();
                Background.exit(Helpers.CustomErrors.ERROR_BG_EXCEPTION);
            }
    }

    function requestOWMData(lat as Lang.Double, lon as Lang.Double, apiKey as Lang.String, proxy as Lang.String, proxyApiKey as Lang.String) as Void {
		System.println(Lang.format("requestOWMData proxyurl[$1$] location[$2$,$3$] apiKey[$4$] proxyApiKey[$5$]", [proxy, lat, lon , apiKey, proxyApiKey]));    
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
            "exclude" => "daily,alerts",
            "units" => "metric",
            "appid" => apiKey
        };		       
//        var proxy = "http://localhost:3000/owm";
//        var url = Lang.format("$1$/lat=$2$/lon=$3$/exclude=daily,alerts/units=metric/appid=$4$/",[proxy, lat, lon,apiKey]);
//        var params = {};                                
//		System.println(url);		                                        
        Communications.makeWebRequest(url, params, options, responseCallBack);
   	}

    function onReceiveOpenWeatherResponse(responseCode as Lang.Number, responseData as Lang.Dictionary or Null) as Void {
    if (responseCode == 200 && responseData != null) {
        try { 
                System.println(responseData);
                // var datax = {
                //     "current" => responseData["current"],
                //     "minutely" => responseData["minutely"],
                //     "hourly" => responseData["hourly"]              
                // };
                // data.put("current", responseData["current"]);
                var data = responseData as String;            
                Background.exit(data);
            } catch(ex instanceof Background.ExitDataSizeLimitException ) {
                ex.printStackTrace();
                System.println(responseData);
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