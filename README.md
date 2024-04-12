# What Weather

# TL;DR;

Connect IQ datafield showing predicted weather information.
 
Get weather forecast and show per upcoming hour the precipitation chance in a blue column.
If the weather conditions is `dangerous` then the color will be different.

Option to set weather alerts.

First column shows precipitation chance for the current hour.
A small field has a different layout than the `large` field.

Default weather source is garmin. 
With an Open Weather Map API key you can display OWM data (Open weather map)[https://openweathermap.org/]. This app uses the `One Call API 3.0` from OWM.


# Settings

## Using garmin connect IQ app

	- OWM API version
    	- Use `onecall 3.0`
  	- OWM API key
    	- Open weather map API key: Get an API key from (Open weather map)[https://openweathermap.org/].          	
        	- Get api key for "One Call API 3.0" it has 1,000 API calls per day for free. 
        	- Default setup of the datafield is: every 5 minutes 1 API call, so 5000 minutes of cycling. And there is a setting on OWM billing plans to stop after 1000 calls. --> Your next payment based on usage One Call API 3.0: 0.0 EUR + VAT 			
	- OWM Proxy: Proxy to compress the json normally returned from OWM.
    	- https://api.castlephoto.info/owm_one
    	- (Github source:)[https://github.com/djs2014/garmin_nodeproxy]
	- OWM Proxy API key:
    	- 0548b3c7-61bc-4afc-b6e5-616f19d3cf23
  	
## On device (edge)

### Proxy

  	- Minimal GPQ quality
  	- Check interval in minutes 
    	- Default every 5 minutes a call to OWM
    	
### Show Weather

	- Weather source:
    	- Garmin first: First show garmin data, then if missing, OWM data.
    	- OWM first: First show OWM data, then if missing, garmin data.
    	- Garmin: Only Garmin data.
    	- OWM: Only Open Weather Map data.

	- Current forecast: show precipitation chance of current hour in first column.
	- Rain first hour: in case of rain in first hour, show this in a graph.
	- Maximum hours of forecast data: precipitation chance will be displayed per hour in the next columns.
	- Clouds: show percentage of clouds per hour
	- Wind: Beaufort, m/s or km/h, and direction.
	- Current wind: Display wind in tiny field (left side).
	- Wind relatve: Wind in tiny field is relative wind (adjusted to current heading)
 	- UV: show Uv index per hour
	- Temperature (`large field`): show predicted temperature (green dots).
	- Relative humidity (`large field`): show predicted humidity (blue dots).
	- Pressure sealevel: show pressure at sealevel per hour
	- Dewpoint: show dewpoint per hour
	- Comfort zone (`large field`): Display the comfortable zones for temperature (wobbly green lines) and humidity (wobbly blue lines). Default 21-27 Celcius and 40% - 60% relative humidity
     	- Comfort colors are calculated using the dewpoint.
	- Weather condition (`large field`): Display condition in a icon. On single field display also the text.
	- 
### Extra information

	- One page field / large field / Wide field / Small field
    	- Nothing
    	- Time
    	- Pressure
    	- Pressure at sea
    	- Distance
    	- Relative wind
  
### Alerts

	Beep when alert reached.

	- Precipitation chance in %.
	- Amount of mm rain in 1st hour (current)
	- Amount of mm rain per hour (forecast)
	- UV index.
	- Windspeed in Beaufort.
	- Dewpoint (Celcius).

### Comfort zone
	- Comfort zone humidity, min and max %.
	- Comfort zone temperature, min and max (in Celcius).
  
### Advanced
	For display the graphics
	- Max temperature
	- Max UV index
	- Min pressure
	- Max pressure
  	
 ## Colors

	- Blue: Default.
	- Gray: Wintry, rain/snow, snow.
	- Red: Thunderstorms.
	- Dark Blue: Heavy rain, Freezing rain, Hail, Heavy snow.
	- Purple: Hurricane, tornado, sandstorm, tropical storm, volcanic ash.

## Weather text abbreviations:

	- ? = chance of
	- p = partly
	- m = mostly
	- - = light
	- + = heavy
	- s = scattered
	- wintry = rain/snow etc.
	- thunder = thunderstorms
	- tropical = tropicalstorms (so not that good)

## Uv index
https://en.wikipedia.org/wiki/Ultraviolet_index

UV index:
<= 2 	Low (Green)
<= 5 	Moderate (Yellow)
<= 7 	High (Orange)
<= 10 	Very high (Red)
> 		Extreme (Purple)

## Dew point

https://en.wikipedia.org/wiki/Dew_point

<= 10 Celcius - A little dry 		
<= 12 Extreme comfortable 			
<= 16 Comfortable
<= 18 OK, but a little high 		
<= 21 A little uncomfortable		
<= 24 Humid, extreme uncomfortable	
<= 26 Very uncomfortable, rather oppressive 
> Severely high						

![Dewpoint colors](/other/images/colors_dewpoint.png "Color scheme dewpoint")


## OWM alerts

When using the openweathermap API you also get the alerts from OWM.
![OWM alert message](/other/images/alerts.png "Display OWM alert")

When using the datafield as a one page data field, it will display the whole alert. This will stay for 30 seconds.
If more alerts are available, they will then popup.
When swipe to another page *which also contains this datafield, but smaller* the alert will immediately disappear.

## Troubleshooting

# When using OWM data

Http[<error code>] are http errors regarding the OWM API.
For example: http[401] -> "Invalid API key. Please see https://openweathermap.org/faq#error401 for more info." The API key for accessing Open Weather Map is invalid.

OWM call used:
https://openweathermap.org/api/one-call-3

# Depricated, only valid with old api key and owm setting to 2.5

https://openweathermap.org/api/one-call-api
https://api.openweathermap.org/data/2.5/onecall?lat=33.44&lon=-94.04&exclude=hourly,daily&appid={API key}