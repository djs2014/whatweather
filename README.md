# What Weather

TL;DR;

Connect IQ datafield showing precipitation chance.

Get weather forecast and show per upcoming hour the precipitation chance in a blue column.
If the weather conditions is `thunder` then the color will be red.

First column shows precipitation chance for the next hour. If current time is 12:01 or 12:59 then 
first column precipitation chance is for 13:00.

Todo:
 - Show notification (next to time) ! when forecast data is delayed.
 - App settings for color
 - Target for other weather conditions and colors
 - show the current values (condition and precipitation chance).
    - make it first column
 - layout margins
 - layout for small and layout for bigger field
  - background orange when first time thunder, reset when no thunder at all. 

- weird bug format Gregorian.Info.hour -> shows the actual time using println but shows `method` when drawn to dc.
 