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
	
Todo:
 - Show notification (next to time) ! when forecast data is delayed.
 - App settings for color
 - Target for other weather conditions and colors
 - layout for small and layout for bigger field  
 - to fix, weird bug format Gregorian.Info.hour -> shows the actual time using println but shows `method` when drawn to dc.
  
  