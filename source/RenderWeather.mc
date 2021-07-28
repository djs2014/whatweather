import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
using Toybox.Time.Gregorian as Calendar;

class RenderWeather {
 	private var dc as Dc;
 	private var ds as DisplaySettings;
 	 
	private const TOP_ADDITIONAL_INFO = 1;
	private var topAdditionalInfo2;

 	public function initialize( dc as Dc, ds as DisplaySettings ) {
      self.dc = dc;
      self.ds = ds;         
	  topAdditionalInfo2 = dc.getFontHeight(ds.fontSmall);
    } 
        
    public function drawUvIndexGraph(uvPoints as Lang.Array, factor as Lang.Number) {
	    try {    			            
	    	var max = uvPoints.size();	    		     
	     	for (var i = 0; i < max; i += 1) {
	            var uvp = uvPoints[i];
		        //System.println(uvp.info()); 		           
	            if (!uvp.isHidden) {
		            var x = uvp.x;
		            var y = ds.getYpostion(uvp.y * factor) ; 	              	
		            dc.setColor(uviToColor(uvp.uvi), Graphics.COLOR_TRANSPARENT);	                          	
	              	dc.fillCircle(x, y, 3);	              		              
              	}	            
	        }          		    
        } catch (ex) {
      		ex.printStackTrace();
    	}  
    }
    
    public function drawObservationLocation(name as Lang.String) {
		if (name == null || name.length() == 0) {return;}
    	dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
		dc.drawText(ds.margin, TOP_ADDITIONAL_INFO, ds.fontSmall, name, Graphics.TEXT_JUSTIFY_LEFT);
    }
    
	public function drawObservationLocation2(name as Lang.String) {
		// Hide on small screen 
		if (name == null || name.length() == 0 || ds.smallField ) {return;}
    	dc.setColor(ds.COLOR_TEXT_ADDITIONAL2, Graphics.COLOR_TRANSPARENT);
		dc.drawText(ds.margin, topAdditionalInfo2, ds.fontSmall, name, Graphics.TEXT_JUSTIFY_LEFT);
    }

    public function drawObservationTime(observationTime as Time.Moment) {
    	if (observationTime == null) { return;}    	
        
    	var observationTimeString = getShortTimeString(observationTime);
        
        var color = ds.COLOR_TEXT_ADDITIONAL;
        if (isDelayedFor(observationTime, $._observationTimeDelayedMinutesThreshold)) {
        	color = Graphics.COLOR_RED;
        }
        var textW = dc.getTextWidthInPixels(observationTimeString, ds.fontSmall);
        var textX = ds.width - textW - ds.margin;        
        
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(textX, TOP_ADDITIONAL_INFO, ds.fontSmall, observationTimeString, Graphics.TEXT_JUSTIFY_LEFT);
    }   
 }