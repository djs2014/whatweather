import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Weather;
using Toybox.Time.Gregorian as Calendar;

class WhatWeatherView extends WatchUi.DataField {
	hidden var printMessages = false;	
	hidden var mFont=Graphics.FONT_LARGE;
	hidden var mFontSmall=Graphics.FONT_XTINY;
	hidden var mFontSmallH;
	hidden var mForegroundColor;
	hidden var mBackgroundColor;
	
	hidden var mDisplayBackgroundAlert;
    hidden var mDisplayedBackgroundAlert; 
     										
    function initialize() {
        DataField.initialize();
        mFontSmallH = Graphics.getFontHeight(mFontSmall);
        ResetBackgroundAlert(); 
    }

    function onLayout(dc as Dc) as Void {

    }

    function compute(info as Activity.Info) as Void {
    }

    // Display the value you computed here. This will be called once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
		// forecast + the current condition    	       	        		   
    	var maxHoursForecast = getNumberProperty("maxHoursForecast", 8) + 1; 
    	var showTimeOfDay = getBooleanProperty("showTimeOfDay", true);
        var alertLevelPrecipitationChance = getNumberProperty("alertLevelPrecipitationChance", 70); 
        var showAlertLevel = getBooleanProperty("showAlertLevel", true);
        var dashesUnderColumnHeight = getNumberProperty("dashesUnderColumnHeight", 2); 
    	var showColumnBorder = getBooleanProperty("showColumnBorder", false);
		//var showForecastStartTime = getBooleanProperty("showForecastStartTime", true);
		var showObservationTime = getBooleanProperty("showObservationTime", true);
		var showObservationLocationName = getBooleanProperty("showObservationLocationName", true);
		
		if (mDisplayBackgroundAlert && !mDisplayedBackgroundAlert) {
			mBackgroundColor = Graphics.COLOR_YELLOW;
			mDisplayBackgroundAlert = false;			
			mDisplayedBackgroundAlert = true;
		} else {
			mBackgroundColor = getBackgroundColor();
		}
		
		dc.setColor(mBackgroundColor, mBackgroundColor);
		dc.clear();
		mForegroundColor = Graphics.COLOR_BLACK;	
     	if (mBackgroundColor == Graphics.COLOR_BLACK) {
            mForegroundColor = Graphics.COLOR_WHITE;
        } 
        
        var width = dc.getWidth();
        var height = dc.getHeight();                
        var bar_width = width/(maxHoursForecast + 4);
        var space = bar_width/4;
        var bar_height = height - 2 * space;                      
		// System.println("FIRST width[" + width.format("%d") + "] height[" + height.format("%d") + "] space[" + space.format("%d") + "] bar_width[" + bar_width.format("%d") + "] bar_height[" + bar_height.format("%d") + "]");                      
    	var barY = space;
    	var barX = space; // width / maxHoursForecast - space/2;
    	    	     	
   	  	//debug("barY[" + barY.format("%d") + "] bar_height[" + bar_height.format("%d") + "]");               
    	//debug("now: " + getDateTimeString(mTime));
    
    	var isWarningCondition = false;
	    var isPrecipitationChance = false;
	    var firstValidSegmentTime = null;    	    	
    	try {
    		var currentConditions = Weather.getCurrentConditions();
			if (currentConditions != null) {
				// First column, current conditions
				var precipitationChance = currentConditions.precipitationChance;
				var color = getConditionColor(currentConditions.condition);
				isWarningCondition = isWarningCondition || color != Graphics.COLOR_BLUE;
				 
				if (showColumnBorder) {    
 					drawColumnBorder(dc, barX, barY, bar_width, bar_height);      	  	
           	  	}
           	  	if (precipitationChance!=null) {
           	  		drawColumnPrecipitationChance(dc, color, barX, barY, bar_width, bar_height, precipitationChance);
           	  	}
           	  	
           	  	if (dashesUnderColumnHeight>0) {
	           	  	dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);   
					dc.fillRectangle(barX, barY + bar_height, bar_width, dashesUnderColumnHeight);
				}
				barX = barX + bar_width + space;	   
			}
			
	    	var hourlyForecast = Weather.getHourlyForecast();
	    	var validSegment = 0;
	    	if (hourlyForecast != null) {
	    	    var maxSegment =  hourlyForecast.size();
			    //debug("found maxSegment: " + maxSegment.format("%d"));
			    	    	      	 
	            for (var segment = 0; validSegment < maxHoursForecast && segment < maxSegment; segment +=1) {
	           	  var forecast = hourlyForecast[segment];           	 
	           	  var fcTime= Calendar.info(forecast.forecastTime, Time.FORMAT_SHORT);
	           	  //debug("found forecast:" + getDateTimeString(fcTime));
	           	             	            	             	             	             
	           	  if (forecast.forecastTime.compare(Time.now()) >= 0) { 
	           	    validSegment +=1;          	  
	           	  	var precipitationChance = forecast.precipitationChance;
	           	   	//debug("Segment[" + segment.format("%d") + "] forecast[" + getDateTimeString(fcTime) + "] rain[" + precipitationChance.format("%d") + "%]");
	 				if (validSegment==1) {
	 					firstValidSegmentTime = getTimeString(fcTime);
	 				}
	 				
	 				if (showColumnBorder) {    
	 					drawColumnBorder(dc, barX, barY, bar_width, bar_height);      	  	
	           	  	}
	           	  		           	  		           	 
	           	  	// TODO, alert once, background flash if (precipitationChance >= alertLevelPrecipitationChance)
	           	  		
	           	  	if (precipitationChance != null) {
	           	  		isPrecipitationChance = true;
		           	  	var color = getConditionColor(forecast.condition);
		           	  	isWarningCondition = isWarningCondition || color != Graphics.COLOR_BLUE;
						drawColumnPrecipitationChance(dc, color, barX, barY, bar_width, bar_height, precipitationChance);							           	  		           	  	
	           	  	}      	  	
	           	  	
	           	  	if (dashesUnderColumnHeight>0) {
	           	  		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);   
						dc.fillRectangle(barX, barY + bar_height, bar_width, dashesUnderColumnHeight);
					}
					           	  	           	  	
	           	  	barX = barX + bar_width + space;	               
	              }
	            }
	        }
        
        } catch(ex) {
			System.println(ex);
		}
		
        if (isPrecipitationChance && showAlertLevel) {
        	drawWarningLevel(dc, Graphics.COLOR_LT_GRAY, alertLevelPrecipitationChance);			
        }     

		try {			
			var currentConditions = Weather.getCurrentConditions();
			if (currentConditions != null) {
				if (showObservationLocationName) {
					var observationLocationName = currentConditions.observationLocationName;		
					observationLocationName = observationLocationName == null ? "--------" : observationLocationName;
					var comma = observationLocationName.find(",");
					if (comma != null) {					
						observationLocationName = observationLocationName.substring(0, comma);
					}											
														 
					var textY = 1; 					
					var textX=space;					
					drawText(dc, textX, textY, observationLocationName, mFontSmall, Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);					
				}
							 			
				if (showObservationTime) {
					var observationTime = currentConditions.observationTime;
					if (observationTime!= null && observationTime != "") {
						var obsTime = Calendar.info(observationTime, Time.FORMAT_SHORT);
						
						var observationTimeCaption = getStringProperty("observationTimeCaption", "As of ");	
						var observationTimeString = observationTimeCaption + getShortTimeString(obsTime);
						 
						var textY = 1; 
						var textW = dc.getTextWidthInPixels(observationTimeString, mFontSmall);
						var textX = width - textW - space;
						drawText(dc, textX, textY, observationTimeString, mFontSmall, Graphics.COLOR_LT_GRAY, mBackgroundColor);										
					}
				}			
			}
		} catch(ex) {
			System.println(ex);
		}
    	
    	if (showTimeOfDay) {
    		var now = Calendar.info(Time.now(), Time.FORMAT_SHORT);
    	    var hour = now.hour;    	    
//	        if (!System.getDeviceSettings().is24Hour) {
//	        	System.println(hour);	        
//	        	hour = (hour + 11) % 12 + 1;     
//	        }
	        // @@ !! putting it in a variable, it will draw `method` @#@??        
    	    // var currentTimeString = hour.format("%02d") + ":" + now.min.format("%02d");
			// System.println(now.hour.format("%02d") + ":" + now.min.format("%02d"));	    	    			
    		dc.setColor(mForegroundColor, Graphics.COLOR_TRANSPARENT);
			dc.drawText(width/2,height/2,mFont,(now.hour.format("%02d") + ":" + now.min.format("%02d")),Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		}	
		
		if (!isWarningCondition) {
			ResetBackgroundAlert();
		}        
    }
    
    function drawText(dc, x, y, text, font, color, backColor) {    	    	
		dc.setColor(color, backColor);
		dc.drawText(x,y,font,text,Graphics.TEXT_JUSTIFY_LEFT);
    }
    
    function drawWarningLevel(dc, color, heightPerc){  
    	if (heightPerc<=0) {return;}
    	  
    	var height = dc.getHeight();
    	var width = dc.getWidth();
    	var margin = 5;
    	// integer division truncates the result, use float values
        var lineY = height - height * (heightPerc / 100.0);
        
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);	
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
	
	function getShortTimeString(moment) {
		if (moment == null) {return "";}
		return moment.hour.format("%02d") +":" + moment.min.format("%02d");
	}
	
	function getConditionColor(condition) {
		if (condition == null) {
		    return Graphics.COLOR_BLUE;
		}
		switch (condition) {
		    case Weather.CONDITION_THUNDERSTORMS:
		    case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
		    case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:    
		    case Weather.CONDITION_TORNADO:
		    case Weather.CONDITION_HURRICANE:
		    	// @@ TEST
		    	SetBackgroundAlert();
		    	return Graphics.COLOR_ORANGE;
		        break;		    
		    default:
		        return Graphics.COLOR_BLUE;
		}
	}
	
	function drawColumnBorder(dc, x, y, width, height) {
   	  	//debug("barX[" + barX.format("%d") + "] barY[" + barY.format("%d") + "] bar_width[" + bar_width.format("%d") + "] bar_height[" + bar_height.format("%d") + "]");           	  	
   	  	dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT); 
   	  	dc.drawRectangle(x, y, width, height);	
	}
	
	function drawColumnPrecipitationChance(dc, color, x, y, bar_width, bar_height, precipitationChance) {
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);	           	  
		var barFilledHeight = bar_height - (bar_height - ((bar_height.toFloat() / 100.0)  * precipitationChance)); 
		var barFilledY = y + bar_height - barFilledHeight; 		           	  	      	  	           	  	           	 
		// debug("barX[" + barX.format("%d") + "] barFilledY[" + barFilledY.format("%d") + "] bar_width[" + bar_width.format("%d") + "] barFilledHeight[" + barFilledHeight.format("%d") + "]");
		dc.fillRectangle(x, barFilledY, bar_width, barFilledHeight);
	}
		           	  	
	function debug(message) {
		if (printMessages) {
			System.println(message);
		}
	}
	
	function ResetBackgroundAlert() {
		mDisplayedBackgroundAlert = false;
		mDisplayBackgroundAlert = false;
	}
	
	function SetBackgroundAlert() {
		mDisplayBackgroundAlert = true;		
	}
}
