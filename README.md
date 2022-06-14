# What Weather

# TL;DR;

Connect IQ datafield showing precipitation chance.

Get weather forecast and show per upcoming hour the precipitation chance in a blue column.
If the weather conditions is `dangerous` then the color will be different.

First column shows precipitation chance for the current hour.
A small field has a different layout than the `large` field.

# Settings

	- Show current forecast: show precipitation chance of current hour in first column.
	- Maximum hours of forecast data: precipitation chance will be displayed per hour in the next columns.
	- Show wind information: Beaufort, m/s or km/h, and direction.
	- Show temperature (`large field`): show predicted temperature (green dots).
	- Show relative humidity (`large field`): show predicted humidity (blue dots).
	- Show comfort regions (`large field`): Display the comfortable zones for temperature (wobbly green lines) and humidity (wobbly blue lines). Default 21-27 Celcius and 40% - 60% relative humidity
	- Show weather condition (`large field`): Display condition in a icon. On single field display also the text.
	- Show extra info (`small field`):
		- Time of the day
		- Temperature (if it works)
		- Pressure
        - Pressure at sealevel		
	- Show extra info (`large field`):		
	- Alert level precipitation chance in %.
	- Alert level windspeed in Beaufort.
	- Comfort zone humidity, min and max %.
	- Comfort zone temperature, min and max (in Celcius).
	- Show time of observation: display the time of the weather data in top right corner.
	- Show warning when time of observation is delayed for x minutes. (default 30)		
	- Show location of observation: Distance and heading from current position.
		- Display the name (`large field`).
	- Show alert level line: display the precipitation chance alert level.
	- Show maximum precipitation chance on top of first column.
	- Show glossary. Show all weather icons when on single field display.

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


## Open weather map
<=2 	Low (Green)
<= 5 	Moderate (Yellow)
<= 7 	Hight (Orange)
<= 10 	Very high (Red)
> 		Extreme (Violet)

## Uv index
https://en.wikipedia.org/wiki/Ultraviolet_index

## Dew point

https://en.wikipedia.org/wiki/Dew_point

<= 10 Celcius - A little dry 		COLOR_WHITE_BLUE_3
<= 12 Extreme comfortable 			COLOR_WHITE_DK_BLUE_3
<= 16 Comfortable 					COLOR_WHITE_DK_BLUE_4
<= 18 OK, but a little high 		COLOR_WHITE_LT_GREEN_3
<= 21 A little uncomfortable		COLOR_WHITE_YELLOW_3
<= 24 Humid, extreme uncomfortable	COLOR_WHITE_ORANGE_3
<= 26 Very uncomfortable, rather oppressive COLOR_WHITE_ORANGERED2_3
> Severely high						COLOR_WHITE_PURPLE_3
> 