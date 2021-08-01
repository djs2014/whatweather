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
	
Todo:
 - App settings for color / color picker?
 - Target for other weather conditions and colors
 
 - refactor
	- print alarms aligned left border 
	- settings show info + config comfort range
	 
	- comfort zone
		< min temp == below 
		< 10 is no 
		
		 
	 - if pop > 30 -> wind text black
	TEST comfort background displays temp range + humidity range
	- move generic code to classes: Render etc..
	- monkey barrel -> shared code
	- 'dual' field info
	- afronding wind km / naar boven
	- fix show info 2 velden die nog niet werken
		- temperature
		x- distance
	- BUG - only current + weather alarm -> continue beep
	- Finetune black/white background with diff settings (comfort, pop, condition)

	- smallfield / large field
		- small: hide temp and humid or small line only

	- large/wide field: current info
	
	
	- show weather condition 
		- define categories
		- show the bars under ..
		- show abbreviation c, th, r, s, w, r2, -> check internet if available
		- use pictograms 
		

		

- WWOWM - glitch simple node -> more advanced .. step by step



