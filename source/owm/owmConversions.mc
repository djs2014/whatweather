import Toybox.Weather;
import Toybox.System;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

// @@ check watchrain -> generic class?
// function owmBGstatusToText(bgStatus as Number) as Lang.String {
//   if (bgStatus == 200) {return "ok";}   
//   if (bgStatus == WhatWeatherBGService.ERROR_BG_NO_API_KEY) {return "apikey?";} 
//   if (bgStatus == WhatWeatherBGService.ERROR_BG_NO_POSITION) {return "position?";} 
//   if (bgStatus == WhatWeatherBGService.ERROR_BG_NO_PROXY) {return "proxy?";} 
//   if (bgStatus == WhatWeatherBGService.ERROR_BG_EXIT_DATA_SIZE_LIMIT) {return "resp size?";} 
//   if (bgStatus == WhatWeatherBGService.ERROR_BG_EXCEPTION) {return "resp ex?";} 
//   if (bgStatus == WhatWeatherBGService.ERROR_BG_INVALID_BACKGROUND_TIME) {return "please wait";} 
  
//   // http code
//   return "http:" + bgStatus.format("%d");
// }

// function owmConditionToGarminWeatherCondition(owmCondition) {
//     if (owmCondition == null) {
//       return Weather.CONDITION_CLEAR;
//     }
//     switch (owmCondition) {
//       case "clear":
//       	return Weather.CONDITION_CLEAR;
//       case "clouds":
//       	return Weather.CONDITION_CLOUDY;
//       case "thunderstorm":
//       	return Weather.CONDITION_THUNDERSTORMS;
//       case "drizzle":
//       	return Weather.CONDITION_DRIZZLE;
//       case "rain":
//       	return Weather.CONDITION_RAIN;
//       case "snow":
//       	return Weather.CONDITION_SNOW;
//       case "mist":
//       	return Weather.CONDITION_MIST;
//       case "smoke":
//       	return Weather.CONDITION_SMOKE;
//       case "haze":
//       	return Weather.CONDITION_HAZE;
//       case "dust":
//       return Weather.CONDITION_DUST;
//       case "fog":
//       return Weather.CONDITION_FOG;
//       case "sand":
//       return Weather.CONDITION_SAND;
//       case "ash":
//       return Weather.CONDITION_VOLCANIC_ASH;
//       case "squall":
//       return Weather.CONDITION_SQUALL;
//       case "tornado":
//       return Weather.CONDITION_TORNADO;      
//       default:
//       	System.println("Unknown OWM condition: " + owmCondition);
//         return Weather.CONDITION_CLEAR;
//     }
//   }
  
// // @@ use what colors
//  function uviToColor(uvi as Lang.Float?) as Lang.Number {
//  	if (uvi == null) {
//       return Graphics.COLOR_GREEN;
//     }
//     if (uvi >10) {
//  			return Graphics.COLOR_PURPLE;    
//     } else if (uvi >=8) {
//  			return Graphics.COLOR_RED;    
//     } else if (uvi >=6) {
//  			return Graphics.COLOR_ORANGE;    
//     } else if (uvi >=3) {
//  			return Graphics.COLOR_YELLOW;    
//     } else {
//  			return Graphics.COLOR_GREEN;    
//     }    	
//  } 
 
//  // @@ use what colors
//  function getConditionColor(condition as Lang.Number?, def as Lang.Number) as Lang.Number {
//     if (condition == null) {
//       return def; //Graphics.COLOR_BLUE;
//     }
//     switch (condition) {
//       case Weather.CONDITION_THUNDERSTORMS:
//       case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
//       case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
//         return Graphics.COLOR_RED;
//         break;
//       case Weather.CONDITION_FREEZING_RAIN:
//       case Weather.CONDITION_HAIL:
//       case Weather.CONDITION_HEAVY_RAIN:
//       case Weather.CONDITION_HEAVY_RAIN_SNOW:
//       case Weather.CONDITION_HEAVY_SHOWERS:
//       case Weather.CONDITION_HEAVY_SNOW:
//         return Graphics.COLOR_DK_BLUE;
//       case Weather.CONDITION_HURRICANE:
//       case Weather.CONDITION_TORNADO:
//       case Weather.CONDITION_SANDSTORM:
//       case Weather.CONDITION_TROPICAL_STORM:
//       case Weather.CONDITION_VOLCANIC_ASH:
//         return Graphics.COLOR_PURPLE;
//       default:
//         return def; 
//     }
//   }