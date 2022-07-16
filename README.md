# What Weather

# TL;DR;

Connect IQ datafield showing precipitation chance.

Get weather forecast and show per upcoming hour the precipitation chance in a blue column.
If the weather conditions is `dangerous` then the color will be different.

First column shows precipitation chance for the current hour.
A small field has a different layout than the `large` field.

Default weather source is garmin. 
With an Open Weather Map API key you can display OWM data (Open weather map)[https://openweathermap.org/]. This app uses the `One Call API 1.0` from OWM.

# Settings
	- Weather source:
    	- Garmin first: First show garmin data, then if missing, OWM data.
    	- OWM first: First show OWM data, then if missing, garmin data.
    	- Garmin: Only Garmin data.
    	- OWM: Only Open Weather Map data.
	- Open weather map API key: Get an API key from (Open weather map)[https://openweathermap.org/].
	- OWM Proxy: Proxy to compress the json normally returned from OWM.
    	- https://api.castlephoto.info/owm_one

	- OWM Proxy API key:
    	- 0548b3c7-61bc-4afc-b6e5-616f19d3cf23
	- Show current forecast: show precipitation chance of current hour in first column.
	- Maximum hours of forecast data: precipitation chance will be displayed per hour in the next columns.
	- Show wind information: Beaufort, m/s or km/h, and direction.
	- Show temperature (`large field`): show predicted temperature (green dots).
	- Show relative humidity (`large field`): show predicted humidity (blue dots).
	- Show comfort regions (`large field`): Display the comfortable zones for temperature (wobbly green lines) and humidity (wobbly blue lines). Default 21-27 Celcius and 40% - 60% relative humidity
    	- Comfort colors are calculated using the dewpoint.
	- Show weather condition (`large field`): Display condition in a icon. On single field display also the text.
	- Show cloud %: show percentage of clouds per hour
	- Show pressure: show pressure at sealevel per hour
	- Show dewpoint: show dewpoint per hour
	- Show UV index: show Uv index per hour
	- Show extra info (`small field`):
		- Time of the day
		- Temperature 
		- Pressure
        - Pressure at sealevel		
        - Elapsed distance
	- Show extra info (`large field`):		
	- Alert level precipitation chance in %.
	- Alert level UV index.
	- Alert level windspeed in Beaufort.
	- Alert level dewpoint (Celcius).
	- Comfort zone humidity, min and max %.
	- Comfort zone temperature, min and max (in Celcius).
	- Show time of observation: display the time of the weather data in top right corner.
	- Show warning when time of observation is delayed for x minutes. (default 30)		
	- Show location of observation: Distance and heading from current position.
		- Display the name (`large field`).	
	

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