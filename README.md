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
	Show maximum precipitation chance on top of first column: Just what you read.
	Show time of observation: display the time of the wheater data in top right corner.
	Show location of observation: display the name in top left corner.
	Show time of day: yes or no.	

	Colors:
		Thunderstorms: red
		Heavy Rain: dark blue
		Hurricane, tornado, sandstorm: purple 
		    		       
New
	Beep on alert.
	Time of observation is red when delayed for x minutes.
	
Todo:
 - App settings for color / color picker?
 - Target for other weather conditions and colors
 - layout for small and layout for bigger field  
 - to fix, weird bug format Gregorian.Info.hour -> shows the actual time using println but shows `method` when drawn to dc.

- optional: icon under bar 14 pix breed
	https://freebiesbug.com/illustrator-freebies/26-free-weather-icons/
- refactor
	- overlay bug delayed
	- move generic code to classes: Render etc..

x - use ww OWM code
	
	- windspeed 0.1 < 10 anders 10 11 etc 0 decimals
	- move to renderobject 
	- temperature graph
	- smallfield / large field
	- large/wide field: current info

	- show km (bearing)
	- show diff fields
	- alert (weather-condition, windSpeed, precipitation)

	- humidity
	- wind bearing
	- speed 
	- wind speed alert
	- icon with condition draw with sdk?

- WWOWM - glitch simple node -> more advanced .. step by step



7 m/s

7 *60 *60 /1000 
= 25 km/u
of miles / u

beaufort

windSpeed alert ??