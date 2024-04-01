const CONDITION_CLEAR = 0;
const CONDITION_PARTLY_CLOUDY = 1;
const CONDITION_MOSTLY_CLOUDY = 2;
const CONDITION_RAIN = 3;
const CONDITION_SNOW = 4;
const CONDITION_WINDY = 5;
const CONDITION_THUNDERSTORMS = 6;
const CONDITION_WINTRY_MIX = 7;
const CONDITION_FOG = 8;
const CONDITION_HAZY = 9;
const CONDITION_HAIL = 10;
const CONDITION_SCATTERED_SHOWERS = 11;
const CONDITION_SCATTERED_THUNDERSTORMS = 12;
const CONDITION_UNKNOWN_PRECIPITATION = 13;
const CONDITION_LIGHT_RAIN = 14;
const CONDITION_HEAVY_RAIN = 15;
const CONDITION_LIGHT_SNOW = 16;
const CONDITION_HEAVY_SNOW = 17;
const CONDITION_LIGHT_RAIN_SNOW = 18;
const CONDITION_HEAVY_RAIN_SNOW = 19;
const CONDITION_CLOUDY = 20;
const CONDITION_RAIN_SNOW = 21;
const CONDITION_PARTLY_CLEAR = 22;
const CONDITION_MOSTLY_CLEAR = 23;
const CONDITION_LIGHT_SHOWERS = 24;
const CONDITION_SHOWERS = 25;
const CONDITION_HEAVY_SHOWERS = 26;
const CONDITION_CHANCE_OF_SHOWERS = 27;
const CONDITION_CHANCE_OF_THUNDERSTORMS = 28;
const CONDITION_MIST = 29;
const CONDITION_DUST = 30;
const CONDITION_DRIZZLE = 31;
const CONDITION_TORNADO = 32;
const CONDITION_SMOKE = 33;
const CONDITION_ICE = 34;
const CONDITION_SAND = 35;
const CONDITION_SQUALL = 36;
const CONDITION_SANDSTORM = 37;
const CONDITION_VOLCANIC_ASH = 38;
const CONDITION_HAZE = 39;
const CONDITION_FAIR = 40;
const CONDITION_HURRICANE = 41;
const CONDITION_TROPICAL_STORM = 42;
const CONDITION_CHANCE_OF_SNOW = 43;
const CONDITION_CHANCE_OF_RAIN_SNOW = 44;
const CONDITION_CLOUDY_CHANCE_OF_RAIN = 45;
const CONDITION_CLOUDY_CHANCE_OF_SNOW = 46;
const CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW = 47;
const CONDITION_FLURRIES = 48;
const CONDITION_FREEZING_RAIN = 49;
const CONDITION_SLEET = 50;
const CONDITION_ICE_SNOW = 51;
const CONDITION_THIN_CLOUDS = 52;
const CONDITION_UNKNOWN = 53;

let convertOWMtoGarminWeather = function (owmWeather, owmWeatherId) {
    if (!owmWeather && !owmWeatherId) {
        return CONDITION_UNKNOWN_PRECIPITATION;
    }
    switch (owmWeather) {
        case "clear":
            return CONDITION_CLEAR;
        case "clouds":
            return CONDITION_CLOUDY;
        case "thunderstorm":
            if (owmWeatherId == 210) {
                return CONDITION_CHANCE_OF_THUNDERSTORMS;
            }
            return CONDITION_THUNDERSTORMS;
        case "drizzle":
            return CONDITION_DRIZZLE;
        case "rain":
            switch (owmWeatherId) {
                case 500:
                case 501:
                    return CONDITION_LIGHT_RAIN;
                case 502:
                case 503:
                case 504:
                    return CONDITION_HEAVY_RAIN;
                case 511:
                    return CONDITION_FREEZING_RAIN;
                case 520:
                    return CONDITION_LIGHT_SHOWERS;
                case 521:
                    return CONDITION_SHOWERS;
                case 522:
                case 531:
                    return CONDITION_HEAVY_SHOWERS;
            }
            return CONDITION_RAIN;
        case "snow":
            return CONDITION_SNOW;
        case "mist":
            return CONDITION_MIST;
        case "smoke":
            return CONDITION_SMOKE;
        case "haze":
            return CONDITION_HAZE;
        case "dust":
            return CONDITION_DUST;
        case "fog":
            return CONDITION_FOG;
        //return CONDITION_SQUALL;
        case "tornado":
            return CONDITION_TORNADO;
        default:
            console.log("Unknown OWM condition: " + owmWeather + " " + owmWeatherId);
            return CONDITION_UNKNOWN_PRECIPITATION;
    }
}

exports.OWMtoGarminWeather = function (owmWeather, owmWeatherId) {
    return convertOWMtoGarminWeather(owmWeather, owmWeatherId);
}