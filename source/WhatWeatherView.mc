import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Weather;
using Toybox.Time.Gregorian as Calendar;

class WhatWeatherView extends WatchUi.DataField {
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
		var showCurrentForecast = getBooleanProperty("showCurrentForecast", true);    	       	        		   
    	var maxHoursForecast = getNumberProperty("maxHoursForecast", 8); 
    	var showTimeOfDay = getBooleanProperty("showTimeOfDay", true);
        var alertLevelPrecipitationChance = getNumberProperty("alertLevelPrecipitationChance", 70); 
        var showAlertLevel = getBooleanProperty("showAlertLevel", true);
        var showMaxPrecipitationChance = getBooleanProperty("showMaxPrecipitationChance", true);
        var dashesUnderColumnHeight = getNumberProperty("dashesUnderColumnHeight", 2); 
    	var showColumnBorder = getBooleanProperty("showColumnBorder", false);
		var showObservationTime = getBooleanProperty("showObservationTime", true);
		var showObservationLocationName = getBooleanProperty("showObservationLocationName", true);
		var showPrecipitationChanceAxis = getBooleanProperty("showPrecipitationChanceAxis", true);
		
		if (mDisplayBackgroundAlert && !mDisplayedBackgroundAlert) {
			mBackgroundColor = Graphics.COLOR_YELLOW;
			mDisplayBackgroundAlert = false;			
			mDisplayedBackgroundAlert = true;
		} else {mBackgroundColor = getBackgroundColor();}
		
		dc.setColor(mBackgroundColor, mBackgroundColor);
		dc.clear();
		mForegroundColor = Graphics.COLOR_BLACK;	
     	if (mBackgroundColor == Graphics.COLOR_BLACK) {mForegroundColor = Graphics.COLOR_WHITE;} 
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var nrOfColumns = maxHoursForecast;
        if (showCurrentForecast) {nrOfColumns = nrOfColumns + 1;}
        
        var margin = 5;
        var space = 2;
        var bar_width = 10;
        if (nrOfColumns > 0) {bar_width = (width - (2 * margin) - (nrOfColumns - 1) * space) / nrOfColumns; }
        
        var bar_height = height - 2 * margin;                      
		var barY = margin;
		var correction = (width - (2 * margin) - (nrOfColumns * bar_width) - (nrOfColumns - 1) * space )/2;
    	var barX = margin + correction; 
    	    	     	
   	  	var maxPrecipitationChance = 0;   	  	
    	var isWarningCondition = false;
	    try {
	    	if (showCurrentForecast) {
	    		var currentConditions = Weather.getCurrentConditions();
				if (currentConditions != null) {
					// First column, current conditions
					var precipitationChance = currentConditions.precipitationChance;
					var color = getConditionColor(currentConditions.condition);
					isWarningCondition = isWarningCondition || color != Graphics.COLOR_BLUE;						
					 
	           	  	if (precipitationChance!=null) {
	           	  		if (precipitationChance>maxPrecipitationChance) {maxPrecipitationChance = precipitationChance;}	           	  		
						if (showColumnBorder) {drawColumnBorder(dc, barX, barY, bar_width, bar_height);}
	           	  		drawColumnPrecipitationChance(dc, color, barX, barY, bar_width, bar_height, precipitationChance);
	           	  	
		           	  	if (dashesUnderColumnHeight>0) {
			           	  	dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);   
							dc.fillRectangle(barX, barY + bar_height, bar_width, dashesUnderColumnHeight);
						}
						barX = barX + bar_width + space;	   
	           	  	}
				}
			}
			
	    	var validSegment = 0;
	    	var hourlyForecast = Weather.getHourlyForecast();
	    	if (hourlyForecast != null) {
	    	    var maxSegment =  hourlyForecast.size();			    	    	      	 
	            for (var segment = 0; validSegment < maxHoursForecast && segment < maxSegment; segment +=1) {
	           	  var forecast = hourlyForecast[segment];           	 
	           	  var fcTime= Calendar.info(forecast.forecastTime, Time.FORMAT_SHORT);
	           	             	            	             	             	             
	           	  if (forecast.forecastTime.compare(Time.now()) >= 0) { 
	           	    validSegment +=1;          	  
	           	  	var precipitationChance = forecast.precipitationChance;
	 				
	           	  	if (precipitationChance != null) {
	           	  		if (precipitationChance>maxPrecipitationChance) {maxPrecipitationChance = precipitationChance;}
		 				if (showColumnBorder) {drawColumnBorder(dc, barX, barY, bar_width, bar_height);}		           	  		           	  		           	
	           	  		// TODO, alert once, background flash if (precipitationChance >= alertLevelPrecipitationChance)
	           	  		
		           	  	var color = getConditionColor(forecast.condition);
		           	  	isWarningCondition = isWarningCondition || color != Graphics.COLOR_BLUE;
						drawColumnPrecipitationChance(dc, color, barX, barY, bar_width, bar_height, precipitationChance);							           	  		           	  	
	           	  	
		           	  	if (dashesUnderColumnHeight>0) {
		           	  		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);   
							dc.fillRectangle(barX, barY + bar_height, bar_width, dashesUnderColumnHeight);
						}
						           	  	           	  	
		           	  	barX = barX + bar_width + space;	               
	           	  	}      	  	
	              }
	            } // /for
	        }
        
        } catch(ex) {
			System.println(ex);
		}
		
        if (maxPrecipitationChance > 0) {
        	if (showMaxPrecipitationChance) {drawMaxPrecipitationChance(dc, margin, bar_height, Graphics.COLOR_LT_GRAY, maxPrecipitationChance);}
        	if (showAlertLevel) {drawWarningLevel(dc, margin, bar_height, Graphics.COLOR_LT_GRAY, alertLevelPrecipitationChance);}			
        }     

		try {			
			var currentConditions = Weather.getCurrentConditions();
			if (currentConditions != null) {
				if (showObservationLocationName) {
					var observationLocationName = currentConditions.observationLocationName;		
					observationLocationName = observationLocationName == null ? "--------" : observationLocationName;
					var comma = observationLocationName.find(",");
					if (comma != null) {observationLocationName = observationLocationName.substring(0, comma);}											
														 
					var textY = 1; 					
					var textX = margin;					
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
						var textX = width - textW - margin;
						drawText(dc, textX, textY, observationTimeString, mFontSmall, Graphics.COLOR_LT_GRAY, mBackgroundColor);										
					}
				}			
			}
		} catch(ex) {
			System.println(ex);
		}
    	
    	if (showPrecipitationChanceAxis) { drawPrecipitationChanceAxis(dc, margin, bar_height);}
    	
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
		
		if (isWarningCondition) {SetBackgroundAlert();}
		else {ResetBackgroundAlert();}        
    }
    
    function drawText(dc, x, y, text, font, color, backColor) {    	    	
		dc.setColor(color, backColor);
		dc.drawText(x,y,font,text,Graphics.TEXT_JUSTIFY_LEFT);
    }
    
    function drawWarningLevel(dc, margin, bar_height, color, heightPerc){  
    	if (heightPerc<=0) {return;}
    	  
    	var width = dc.getWidth();
    	
    	// integer division truncates the result, use float values
        var lineY = margin + bar_height - bar_height * (heightPerc / 100.0);
        
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);	
        dc.drawLine(margin, lineY, width - margin, lineY);         
    }
    
    function drawMaxPrecipitationChance(dc, margin, bar_height, color, precipitationChance){
    	if (precipitationChance > 80) {return;} 
    	var y = margin + bar_height - bar_height * (precipitationChance / 100.0) - mFontSmallH - 2;
    	dc.setColor(color, Graphics.COLOR_TRANSPARENT);	
    	dc.drawText(margin, y, mFontSmall, precipitationChance.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);    	
    }
    
    function drawPrecipitationChanceAxis(dc, margin, bar_height) {
    	dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
		var width = dc.getWidth();
		var x2 = width - margin;
		var y100 = margin;
    	dc.drawLine(0, y100, margin, y100);
    	dc.drawLine(x2, y100, width, y100);
    	var y75 = margin + bar_height - bar_height * 0.75;
    	dc.drawLine(0, y75, margin, y75);  
    	dc.drawLine(x2, y75, width, y75); 
    	var y50 = margin + bar_height - bar_height * 0.5;
    	dc.drawLine(0, y50, margin, y50);
    	dc.drawLine(x2, y50, width, y50);
    	var y25 = margin + bar_height - bar_height * 0.25;
    	dc.drawLine(0, y25, margin, y25);
    	dc.drawLine(x2, y25, width, y25);
    	var y0 = margin + bar_height;
    	dc.drawLine(0, y0, margin, y0);
    	dc.drawLine(x2, y0, width, y0);    	
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
		    	return Graphics.COLOR_RED;
		        break;		    
		    case Weather.CONDITION_FREEZING_RAIN:
		    case Weather.CONDITION_HAIL:
		    case Weather.CONDITION_HEAVY_RAIN:
		    case Weather.CONDITION_HEAVY_RAIN_SNOW:
		    case Weather.CONDITION_HEAVY_SHOWERS:
		    case Weather.CONDITION_HEAVY_SNOW:
		    	return Graphics.COLOR_DK_BLUE;
		    case Weather.CONDITION_HURRICANE:
		    case Weather.CONDITION_TORNADO:
		    case Weather.CONDITION_SANDSTORM:
		    case Weather.CONDITION_TROPICAL_STORM:
		    case Weather.CONDITION_VOLCANIC_ASH:
		    	return Graphics.COLOR_PURPLE;
		    default:
		        return Graphics.COLOR_BLUE;
		}
	}
	
	function drawColumnBorder(dc, x, y, width, height) {
   	  	//System.println("barX[" + barX.format("%d") + "] barY[" + barY.format("%d") + "] bar_width[" + bar_width.format("%d") + "] bar_height[" + bar_height.format("%d") + "]");           	  	
   	  	dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT); 
   	  	dc.drawRectangle(x, y, width, height);	
	}
	
	function drawColumnPrecipitationChance(dc, color, x, y, bar_width, bar_height, precipitationChance) {
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);	           	  
		var barFilledHeight = bar_height - (bar_height - ((bar_height.toFloat() / 100.0)  * precipitationChance)); 
		var barFilledY = y + bar_height - barFilledHeight; 		           	  	      	  	           	  	           	 
		// System.println("barX[" + barX.format("%d") + "] barFilledY[" + barFilledY.format("%d") + "] bar_width[" + bar_width.format("%d") + "] barFilledHeight[" + barFilledHeight.format("%d") + "]");
		dc.fillRectangle(x, barFilledY, bar_width, barFilledHeight);
	}	
			           	  
	function ResetBackgroundAlert() {
		mDisplayedBackgroundAlert = false;
		mDisplayBackgroundAlert = false;
	}
	
	function SetBackgroundAlert() {
		mDisplayBackgroundAlert = true;		
	}
}
