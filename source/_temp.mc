// @@ or use the garmin 
function getWeatherCondition(condition) as WeatherCondition {
  switch (condition) {
    // clear
    case Weather.CONDITION_FAIR:
    case Weather.CONDITION_MOSTLY_CLEAR:
    case Weather.CONDITION_PARTLY_CLEAR:
    case Weather.CONDITION_CLEAR:
    // clouds
    case Weather.CONDITION_THIN_CLOUDS:      
    case Weather.CONDITION_PARTLY_CLOUDY:      
    case Weather.CONDITION_MOSTLY_CLOUDY:
    case Weather.CONDITION_CLOUDY:
    // (chance of) rain  
    case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
    case Weather.CONDITION_CHANCE_OF_SHOWERS:      
    case Weather.CONDITION_DRIZZLE:      
    case Weather.CONDITION_LIGHT_RAIN:
    case Weather.CONDITION_LIGHT_SHOWERS:
    case Weather.CONDITION_SCATTERED_SHOWERS:      
    case Weather.CONDITION_RAIN:
    case Weather.CONDITION_SHOWERS:    
    case Weather.CONDITION_HEAVY_RAIN:
    case Weather.CONDITION_HEAVY_SHOWERS:
    case Weather.CONDITION_FREEZING_RAIN:
    case Weather.CONDITION_HEAVY_RAIN_SNOW:
    
    // hail
    case Weather.CONDITION_HAIL:
    case Weather.CONDITION_WINTRY_MIX:
  
    case Weather.CONDITION_CHANCE_OF_SNOW:
    case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
    case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
    case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
      
    // snow
    case Weather.CONDITION_FLURRIES:
    case Weather.CONDITION_LIGHT_SNOW:
      
    case Weather.CONDITION_SNOW:
    case Weather.CONDITION_RAIN_SNOW:
      
    case Weather.CONDITION_SLEET:
    case Weather.CONDITION_ICE_SNOW:
    case Weather.CONDITION_ICE:      
    case Weather.CONDITION_HEAVY_SNOW:
      

    // thunder                              
    case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:      
    case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
    case Weather.CONDITION_THUNDERSTORMS:
    case Weather.CONDITION_TROPICAL_STORM:
            
    // dust
    case Weather.CONDITION_DUST:
    case Weather.CONDITION_SAND:
      
    case Weather.CONDITION_HAZY: // dust, difficult to see
    // sandstorm
    case Weather.CONDITION_SANDSTORM:
      
    // ash
    case Weather.CONDITION_VOLCANIC_ASH:
      
    // smoke
    case Weather.CONDITION_SMOKE:
      return new WeatherCondition(WeatherCondition.SMOKE,
                                  WeatherCondition.NORMAL);
// hurricane
    case Weather.CONDITION_HURRICANE:
    case Weather.CONDITION_TORNADO:
      return new WeatherCondition(WeatherCondition.TORNADO,
                                  WeatherCondition.HEAVY);
    

    // fog
    case Weather.CONDITION_FOG:
     case Weather.CONDITION_MIST:
     
     // windy
    case Weather.CONDITION_WINDY:    
    case Weather.CONDITION_SQUALL:  // sudden windspeed
   
    
    
    case Weather.CONDITION_UNKNOWN_PRECIPITATION:
    case Weather.CONDITION_UNKNOWN:
    
  }
}

class WeatherCondition {
  var category;
  var severity;

  function initialize(category, severity) {
    self.category = category;
    self.severity = severity;
  }

  enum {
    CLEAR = 0,
    CLOUDS,
    THUNDERSTORMS,
    DRIZZLE,
    RAIN,
    HAIL,
    SNOW,
    MIST,
    SMOKE,
    HAZE,
    DUST,
    FOG,
    SAND,
    ASH,
    SQUALL,
    TORNADO,
    WINDY,
    UNKNOWN
  }

  enum {
    CHANCE = -2, // ?
    LIGHT = -1,  // pale
    NORMAL = 0,  // normal
    HEAVY,       // bold
  }
}
