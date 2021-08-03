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
      return new WeatherCondition(WeatherCondition.RAIN,
                                  WeatherCondition.CHANCE);

    case Weather.CONDITION_LIGHT_RAIN:
    case Weather.CONDITION_LIGHT_SHOWERS:
    case Weather.CONDITION_SCATTERED_SHOWERS:
      return new WeatherCondition(WeatherCondition.RAIN,
                                  WeatherCondition.LIGHT);

    case Weather.CONDITION_RAIN:
    case Weather.CONDITION_SHOWERS:
      return new WeatherCondition(WeatherCondition.RAIN,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_FREEZING_RAIN:
    case Weather.CONDITION_HEAVY_RAIN:
    case Weather.CONDITION_HEAVY_RAIN_SNOW:
    case Weather.CONDITION_HEAVY_SHOWERS:
      return new WeatherCondition(WeatherCondition.RAIN,
                                  WeatherCondition.HEAVY);
                                  
    case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
      return new WeatherCondition(WeatherCondition.THUNDERSTORMS,
                                  WeatherCondition.CHANCE);
    case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
      return new WeatherCondition(WeatherCondition.THUNDERSTORMS,
                                  WeatherCondition.LIGHT);
    case Weather.CONDITION_THUNDERSTORMS:
      return new WeatherCondition(WeatherCondition.THUNDERSTORMS,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_TROPICAL_STORM:
      return new WeatherCondition(WeatherCondition.THUNDERSTORMS,
                                  WeatherCondition.HEAVY);

    
    case Weather.CONDITION_HAIL:
    case Weather.CONDITION_WINTRY_MIX:
      return new WeatherCondition(WeatherCondition.HAIL,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_CHANCE_OF_SNOW:
    case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
    case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
    case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.CHANCE);

    case Weather.CONDITION_FLURRIES:
    case Weather.CONDITION_LIGHT_SNOW:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.LIGHT);

    case Weather.CONDITION_SNOW:
    case Weather.CONDITION_RAIN_SNOW:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_SLEET:
    case Weather.CONDITION_ICE_SNOW:
    case Weather.CONDITION_ICE:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.HEAVY);

    case Weather.CONDITION_HEAVY_SNOW:
      return new WeatherCondition(WeatherCondition.SNOW,
                                  WeatherCondition.HEAVY);

    case Weather.CONDITION_HURRICANE:
    case Weather.CONDITION_TORNADO:
      return new WeatherCondition(WeatherCondition.TORNADO,
                                  WeatherCondition.HEAVY);

    case Weather.CONDITION_DUST:
    case Weather.CONDITION_SAND:
      return new WeatherCondition(WeatherCondition.SAND,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_SANDSTORM:
      return new WeatherCondition(WeatherCondition.SAND,
                                  WeatherCondition.HEAVY);

    case Weather.CONDITION_VOLCANIC_ASH:
      return new WeatherCondition(WeatherCondition.ASH,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_SMOKE:
      return new WeatherCondition(WeatherCondition.SMOKE,
                                  WeatherCondition.NORMAL);

    

    
    case Weather.CONDITION_FOG:
      return new WeatherCondition(WeatherCondition.FOG,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_MIST:
      return new WeatherCondition(WeatherCondition.MIST,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_WINDY:
      return new WeatherCondition(WeatherCondition.WINDY,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_HAZY:
      return new WeatherCondition(WeatherCondition.HAZE,
                                  WeatherCondition.NORMAL);
    case Weather.CONDITION_DRIZZLE:
      return new WeatherCondition(WeatherCondition.DRIZZLE,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_SQUALL:  // sudden windspeed
      return new WeatherCondition(WeatherCondition.SQUALL,
                                  WeatherCondition.NORMAL);

    case Weather.CONDITION_UNKNOWN_PRECIPITATION:
    case Weather.CONDITION_UNKNOWN:
    default:
      return new WeatherCondition(WeatherCondition.UNKNOWN,
                                  WeatherCondition.NORMAL);
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
