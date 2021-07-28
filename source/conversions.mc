import Toybox.Weather;
import Toybox.System;
import Toybox.Graphics;

function uviToColor(uvi) {
 	if (uvi == null) {
      return Graphics.COLOR_GREEN;
   }
    if (uvi >10) {
 			return Graphics.COLOR_PURPLE;    
    } else if (uvi >=8) {
 			return Graphics.COLOR_RED;    
    } else if (uvi >=6) {
 			return Graphics.COLOR_ORANGE;    
    } else if (uvi >=3) {
 			return Graphics.COLOR_YELLOW;    
    } else {
 			return Graphics.COLOR_GREEN;    
    }    	
} 
 
function getConditionColor(condition, def) {
    if (condition == null) {
      return def; //Graphics.COLOR_BLUE;
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
        return def; 
    }
 }