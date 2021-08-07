# What Weather

TL;DR;

Connect IQ datafield showing precipitation chance.

Get weather forecast and show per upcoming hour the precipitation chance in a blue column.
If the weather conditions is `thunder` then the color will be red.

First column shows precipitation chance for the current hour.

Settings:
	Show current forecast: show precipitation chance of current hour in first column.
	Maximum hours of forecast data: precipitation chance will be displayd per hour in the next columns.
	Alert level precipitation chance: set the percentage.
	Show alert level line: display the precipitation chance alert level.
	Show wind info: Beaufort, m/s or km/h.
	Alert level windspeed in Beaufort.
	Show maximum precipitation chance on top of first column: Just what you read.
	Show extra info:
		- Time of the day
		- Altitude
		- Heading
		- Temperature (if it works)
		- Heartrate
		- Pressure
		- Elapsed distance
	Show time of observation: display the time of the wheater data in top right corner.
		- Time of observation is red when delayed for x minutes.
	Show location of observation: display the name in top left corner.

	Colors:
		Thunderstorms: red
		Heavy Rain: dark blue
		Hurricane, tornado, sandstorm: purple 
		    		       
New
	Show wind info: Beaufort, m/s or km/h.
	Alert level windspeed in Beaufort.
	Show extra info:
		- Time of the day
		- Altitude
		- Heading
		- Temperature (if it works)
		- Heartrate
		- Pressure
		- Elapsed distance
	Show temperature
	Show relative humidity
	Show comfort zones (humidity / temperature). Default 21-27 Celcius and 40% - 60% relative humidity.
	
	Show weather condition 
	Small field / Large field automatic layout
Todo:
 - picture explaining information	
 - App settings for color / color picker?
 - refactor		
	- if pop > 30 -> wind text black
	- move generic code to classes: Render etc..
	- monkey barrel -> shared code
	- 'dual' field info
	- fix show info for temperature		
	- BUG - one column + weather alarm -> continue beep
	- Finetune black/white background with diff settings (comfort, pop, condition)			
	- At initial start -> position is 0 (calc distance is then 5840km)? 
	- Show glossary weather icons if 1 field  + text
		- draw colors + text
		? = chance of
		p = partly
		m = mostly
		- = light
		+ = heavy
		s = scattered
		wintry = rain/snow etc.
		thunder = thunderstorms
		tropical = tropicalstorms
		
- WWOWM - glitch simple node -> more advanced .. step by step