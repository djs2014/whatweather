import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Weather;

using Toybox.Time.Gregorian as Calendar;

class WhatWeatherView extends WatchUi.DataField {
	hidden var font=Graphics.FONT_LARGE;
	hidden var fontSmall=Graphics.FONT_XTINY;
	hidden var mTime as Date;
	hidden var printMessages = false;	
								
    function initialize() {
        DataField.initialize();
        mTime = Calendar.info(Time.now(), Time.FORMAT_SHORT);
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {

    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
    	mTime = Calendar.info(Time.now(), Time.FORMAT_SHORT);
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        mTime = Calendar.info(Time.now(), Time.FORMAT_SHORT);
    	       	        		     	
    	var maxHoursForecast = getNumberProperty("maxHoursForecast", 8); 
    	var showTimeOfDay = getBooleanProperty("showTimeOfDay", true);
        var alertLevelPrecipitationChance = getNumberProperty("alertLevelPrecipitationChance", 70); 
        var showAlertLevel = getBooleanProperty("showAlertLevel", true);
        var dashesUnderColumnHeight = getNumberProperty("dashesUnderColumnHeight", 2); 
    	var showColumnBorder = getBooleanProperty("showColumnBorder", false);
		var showForecastStartTime = getBooleanProperty("showForecastStartTime", true);
		
		var backColor = getBackgroundColor();
		dc.setColor(backColor, backColor);
		dc.clear();
	
        var width = dc.getWidth();
        var height = dc.getHeight();
                
        var bar_width = width/(maxHoursForecast + 4); // 12;
        var space = bar_width/4;
        var bar_height = height - 2 * space;
                      
		// System.println("FIRST width[" + width.format("%d") + "] height[" + height.format("%d") + "] space[" + space.format("%d") + "] bar_width[" + bar_width.format("%d") + "] bar_height[" + bar_height.format("%d") + "]");
                      
    	var barY = space;
    	var barX = width / maxHoursForecast - space/2;
    	    	     	
   	  	debug("barY[" + barY.format("%d") + "] bar_height[" + bar_height.format("%d") + "]");               
    	debug("now: " + getDateTimeString(mTime));
    
    	var hourlyForecast = Weather.getHourlyForecast();
    	var firstValidSegmentTime = null;    	    	
    	var validSegment = 0;
    	var isPrecipitationChance = false;
    	if (hourlyForecast != null) {
    	    var maxSegment =  hourlyForecast.size();
		    debug("found maxSegment: " + maxSegment.format("%d"));
		    	    	      	 
            for (var segment = 0; validSegment < maxHoursForecast && segment < maxSegment; segment +=1) {
           	  var forecast = hourlyForecast[segment];           	 
           	  var fcTime= Calendar.info(forecast.forecastTime, Time.FORMAT_SHORT);
           	  debug("found forecast:" + getDateTimeString(fcTime));
           	             	            	             	             	             
           	  if (forecast.forecastTime.compare(Time.now()) >= 0) { 
           	    validSegment +=1;          	  
           	  	var precipitationChance = forecast.precipitationChance;
           	   	debug("Segment[" + segment.format("%d") + "] forecast[" + getDateTimeString(fcTime) + "] rain[" + precipitationChance.format("%d") + "%]");
 				if (validSegment==1) {
 					firstValidSegmentTime = getTimeString(fcTime);
 				}
 				
 				if (showColumnBorder) {          	  	
	           	  	debug("barX[" + barX.format("%d") + "] barY[" + barY.format("%d") + "] bar_width[" + bar_width.format("%d") + "] bar_height[" + bar_height.format("%d") + "]");           	  	
	           	  	dc.setColor(Graphics.COLOR_LT_GRAY,Graphics.COLOR_TRANSPARENT); 
	           	  	dc.drawRectangle(barX, barY, bar_width, bar_height);
           	  	}
           	  	
           	  	if (isThunder(forecast.condition)) {
           	  		dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
           	  	} else if (precipitationChance >= alertLevelPrecipitationChance) {
           	  		dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
           	  	} else {
           	  		dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
           	  	}
           	  	
           	  	if (precipitationChance>0) {
           	  		isPrecipitationChance = true;
           	  		           	  	
	           	  	var barFilledHeight = bar_height - (bar_height - ((bar_height.toFloat() / 100.0)  * precipitationChance)); 
	           	  	var barFilledY = barY + bar_height - barFilledHeight; 
	           	  	      	  	           	  	           	  
	           	  	debug("barX[" + barX.format("%d") + "] barFilledY[" + barFilledY.format("%d") + "] bar_width[" + bar_width.format("%d") + "] barFilledHeight[" + barFilledHeight.format("%d") + "]");
	           	  	dc.fillRectangle(barX, barFilledY, bar_width, barFilledHeight);
           	  	}      	  	
           	  	
           	  	if (dashesUnderColumnHeight>0) {
           	  		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);   
					dc.fillRectangle(barX, barY + bar_height, bar_width, dashesUnderColumnHeight);
				}
				           	  	           	  	
           	  	barX = barX + bar_width + space;	               
              }
            }
        }
        
        if (isPrecipitationChance && showAlertLevel) {
        	drawWarningLevel(dc, Graphics.COLOR_LT_GRAY, alertLevelPrecipitationChance);			
        }     
        
    	var foregroundColor = Graphics.COLOR_BLACK;
     	if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            foregroundColor = Graphics.COLOR_WHITE;
        } 

			
		if (firstValidSegmentTime != null && showForecastStartTime) {
			// top right 
			var textY=1; 
			var textW=dc.getTextWidthInPixels(firstValidSegmentTime, fontSmall)+10;
			var textX=width - textW - space;
			dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
			dc.drawText(textX,textY,fontSmall,firstValidSegmentTime,Graphics.TEXT_JUSTIFY_LEFT);
		}
    	
    	if (showTimeOfDay) {
    	    var hour = mTime.hour;
	        if (System.getDeviceSettings().is24Hour == false) {
	        	hour = (hour+11)%12 + 1;     
	        }        
			var timeString=hour.format("%d")+":"+mTime.min.format("%02d"); //+":"+mTime.sec.format("%02d")+AMPM;		
    		dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
			dc.drawText(width/2,height/2,font,timeString,Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		}	        
    }
    
    
    function drawWarningLevel(dc, foregroundColor, heightPerc){  
    	if (heightPerc<=0) {return;}
    	  
    	var height = dc.getHeight();
    	var width = dc.getWidth();
    	var margin = 5;
    	// integer division truncates the result, use float values
        var lineY = height - height * (heightPerc / 100.0);
        
        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);	
        dc.drawLine(0 + margin, lineY, width - (2 * margin), lineY);         
    }
    
	function getDateTimeString(moment) {
		if (moment == null) {return "";}
		return moment.day.format("%02d")+"-"+moment.month.format("%02d")+"-"+moment.year.format("%d")+" " + moment.hour.format("%02d") +":" + moment.min.format("%02d")+":" + moment.sec.format("%02d");
	}
	
	function getTimeString(moment) {
		if (moment == null) {return "";}
		return moment.hour.format("%02d") +":" + moment.min.format("%02d")+":" + moment.sec.format("%02d");
	}
	
	function isThunder(condition) {
				switch (condition) {
		    case Weather.CONDITION_THUNDERSTORMS:
		    case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
		    case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:    
		    case Weather.CONDITION_TORNADO:
		    case Weather.CONDITION_HURRICANE:
		    	return true;
		        break;		    
		    default:
		        return false;
		}
	}
	
	function debug(message) {
		if (printMessages) {
			System.println(message);
		}
	}
}
