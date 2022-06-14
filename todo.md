-> node.js: OWM pop = value 0.1 - 1  + example json
--------------------
@@ grade colors / flatland mode
MVP - 1 
check memory background
add pressure + node docu example output to edge
dewpoint -> comfort (or calculate?)
	pressure: line min=900 max = 1040 calc perc
	dewpoint/temp: min = 0, max = 50 
		<0 min = -10
	dewpoint use comfort color based on value
	hide dewpoint below x
	dewpoint value to color -
		- alert on dewpoint
	set max temperature (same as for dewpoint)
	if > alert -> color the icon (dewpoint)
	
https://api.castlephoto.info/owm_one
http://localhost:4000/owm_one

condition -> cond
dew_p=>7.260000 --> dew_p=>7.26
- remove last 4 digits
+ test parameter with dummy data and fake time stamps
8 - /test parameter -> owm response with mm rain data to test layout (setting?)
6 - show night/sun down/up  --> wind icon inverted ? / bar under black
	grijs lichter, nacht -> grijs donker
	
x- max uvidx ipv factor tbv bereken perc en y pos
? - set interval for weather call 0/5/10/15/20/25/30
7 -  buffered bitmaps (when weather not changed)
	- draw wobbly line // aka the background
9 - property: weatherData.changed -> 
	- new call to owm
	- obstime /lat /lng / obsname diff
10 - when owm location closer to current location then garmin location use owm for:
	- precepation chance / weather etc..
	- mark owm location green, garmin location light gray or something

x show alert info on small field (abbreviated)
x combine with bg data / rain pop 
  x pop_other ==> side line diff color blue
    - use condition icon if not different from default (color)
    ?- show mode on screen (when paused?)
      - garmin only + add missing
      - owm only + add missing
      - garmin first
      - owm first
    x- bg enabled if owm first or show uvi/clouds
?- use intial stored gps location
  - for current loc
  - for garmin weather?
  - for owm


x - start bg process when valid (phone, position, parameters valid, option chose (like temperature))
2 - layout garmin / owm
	- uvi icon () ?


MVP - 2
1 
# Todo
	- Refactor the code, etc.
	
	- Check white/black background settings.
	- BUG - one column + weather alarm -> continue beep
	- At initial start -> position is 0 (calc distance is then 5840km)? 			
	- bg process
     	- Show info for temperature.
         	- Option actual temperature in current
     	- no graphics for background
    	- merge owm data
    - colors as what apps
    - weather alert as icons (also on small field)
    - detect bikerader -> offset time info
## Nice to have :-)
	- Uv index,
	- Minutely forecast.

show stat/counter in display when bg active

var _owmCounter = 0; 
var _owmBGstatus = 0;
check watchrain for all the checks needed

ams 52.188950, 4.549666
lasvegas 36.16373271614203, -115.1262537886411


vs code end of line --> LF
git -> CRLF settings
https://stackoverflow.com/questions/1967370/git-replacing-lf-with-crlf

  – git config --system core.autocrlf false            # per-system solution
  – git config --global core.autocrlf false            # per-user solution
  – git config --local core.autocrlf false              # per-project solution

PPS My personal preference is configuring the editor/IDE to use Unix-style endings, and setting core.autocrlf to false.


{hourly=>[{dt=>1653926400, clouds=>36, uvi=>1.540000, pop=>0.100000, weather=>20}, {dt=>1653930000, clouds=>20, uvi=>0.790000, pop=>0.090000, weather=>20}, {dt=>1653933600, clouds=>36, uvi=>0.310000, pop=>0.050000, weather=>20}, {dt=>1653937200, clouds=>52, uvi=>0.090000, pop=>0, weather=>20}, {dt=>1653940800, clouds=>68, uvi=>0, pop=>0, weather=>20}, {dt=>1653944400, clouds=>84, uvi=>0, pop=>0, weather=>20}, {dt=>1653948000, clouds=>100, uvi=>0, pop=>0, weather=>20}, {dt=>1653951600, clouds=>100, uvi=>0, pop=>0, weather=>20}, {dt=>1653955200, clouds=>100, uvi=>0, pop=>0, weather=>20}, {dt=>1653958800, clouds=>100, uvi=>0, pop=>0.030000, weather=>20}, {dt=>1653962400, clouds=>100, uvi=>0, pop=>0.050000, weather=>20}, {dt=>1653966000, clouds=>100, uvi=>0, pop=>0.090000, weather=>20}, {dt=>1653969600, clouds=>100, uvi=>0, pop=>0.090000, weather=>20}, {dt=>1653973200, clouds=>100, uvi=>0.210000, pop=>0.090000, weather=>20}, {dt=>1653976800, clouds=>100, uvi=>0.560000, pop=>0.090000, weather=>20}], current=>{weather=>20, uvi=>0.790000, lon=>4.813800, clouds=>20, dt=>1653929007, tz_offset=>7200, lat=>52.201302}, minutely=>{dt_start=>1653929040, pops=>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}}