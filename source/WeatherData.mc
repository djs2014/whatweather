import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

class WeatherData {
	public var current as CurrentConditions;
	public var minutely as MinutelyForecast;
	public var hourly as Lang.Array;
	public var lastUpdated; // as Time.Moment; 
	
	public function initialize() {
      current = new CurrentConditions();
      minutely = new MinutelyForecast();
      hourly = [];
      lastUpdated = new Time.Moment(0);
      System.println("WeatherData initialize");
    }
}
	
class CurrentConditions {
	public  var lat = 0;
	public  var lon = 0;
	public  var observationLocationName = "";
	public  var observationTime = null;
	public  var forecastTime = null;
	public  var clouds = 0;
	public  var precipitationChance = 0;
	public  var condition = 0;
	public  var weather = "";
	public  var uvi = 0;
	
	public function info() {
	 	return Lang.format("CurrentConditions: time[$1$] pop[$2$] clouds[$3$] condition[$4$] weather[$5$] uvi[$6$] lat[$7$] lon[$8$] obsname[$9$] obstime[$10$]",
        [getDateTimeString(forecastTime), precipitationChance, clouds, condition, weather, uvi, lat, lon, observationLocationName, getDateTimeString(observationTime)]);
  	}
}

class MinutelyForecast
{
    public var forecastTime;
    public var pops = [];           
}

class HourlyForecast
{
    public var forecastTime;
    public var precipitationChance = 0;
    public var clouds = 0;
    public var condition = 0;
    public var weather = "";
    public var uvi = 0;       
    
    public function info() {
    	return Lang.format("HourlyForecast: time[$1$] pop[$2$] clouds[$3$] condition[$4$] conditionText[$5$] uvi[$6$]",
    	[getDateTimeString(forecastTime), precipitationChance, clouds, condition, weather, uvi]);   
    } 
}
