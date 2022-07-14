- git project node proxy server
-> node.js: OWM pop = value 0.1 - 1  + example json
-> other weather sources available?
-> test param with minutely data
-> enable minutely if needed
--------------------
TL;DR;
 - properties without in settings anymore -> weird bugs 
 - don't use Toybox.Communications in import for foreground app (even if it is not used)
 - 
optimize
	wobbly increment x, y .. 5 px
	@@DRY 
	x calculate dewpoint for garmin..?
	x	https://learnmetrics.com/dew-point-calculator-chart-formula/
	-> color scale
	cels/farenh etc.. when paused.
	docu - colors dewpoint etc.
	xx wobbly lines -> to array
    - use profiler to check duration -> cache some code results (wobbly line)
    - remove unused code
    - show wind info current hour on small field
- radar -> offset to left x px
LATER
- show minutely (option / test)
global Settings object
	cleanup properties / settings

docu -> screenshots + settings

? showActualWeather -> how to display nice
	show actual temperature / pressure /  replace current / add / none

- weather alert? -> garmin alert? possible?
xshow errors:
x- api key etc..
x http->code 0 -> savesettings to trigger bg again

min/max configuration
	pressure: line min=900 max = 1040 calc perc
	dewpoint/temp: min = 0, max = 50 
		<0 min = -10
	x dewpoint use comfort color based on value
	
	set max temperature (same as for dewpoint)
	if > alert -> color the icon (dewpoint)

 test parameter with dummy data and fake time stamps
 - /test parameter -> owm response with mm rain data to test layout (setting?)
x  - show night/sun down/up  --> wind icon inverted ? / bar under black
x	grijs lichter, nacht -> grijs donker
? - set interval for weather call 0/5/10/15/20/25/30
- 
x memory -> display 8 hours -> get only 9 hours

MVP - 1 
? weather data changed -> buffered bitmap out of memory
x show details:  font should be white if cloud/rain y+10 > point y 
x	- array with max y coord cloud/rain
x activity paused 
x	- show max numbers: pressure, temp, dew etc.
x hide dewpoint below x celcius - 8
x	hideTemperatureLowerThan
x	 Point to WeatherPoint (x, value, minValue)
x check memory background
x add pressure + node docu example output to edge
x dewpoint -> comfort (or calculate?)
	
https://api.castlephoto.info/owm_one
http://localhost:4000/owm_one

x condition -> cond
x dew_p=>7.260000 --> dew_p=>7.26
x remove last 4 digits	
x- max uvidx ipv factor tbv bereken perc en y pos

7 -  buffered bitmaps (when weather not changed)
	- draw wobbly line // aka the background

x show alert info on small field (abbreviated)
x combine with bg data / rain pop 
  x pop_other ==> side line diff color blue
    x- use condition icon if not different from default (color)
    x- show mode on screen (when paused?)
    x  - garmin only + add missing
    x  - owm only + add missing
    x  - garmin first
    x  - owm first
    x- bg enabled if owm first or show uvi/clouds
x- use intial stored gps location
  - for current loc
  - for garmin weather?
  - for owm


x - start bg process when valid (phone, position, parameters valid, option chose (like temperature))
x - layout garmin / owm
	- uvi icon () ?


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
    - detect bikerader -> offset display x time info
## Nice to have :-)
	- Uv index,
	- Minutely forecast.

show stat/counter in display when bg active


ams 52.188950, 4.549666
lasvegas 36.16373271614203, -115.1262537886411


vs code end of line --> LF
git -> CRLF settings
https://stackoverflow.com/questions/1967370/git-replacing-lf-with-crlf

  – git config --system core.autocrlf false            # per-system solution
  – git config --global core.autocrlf false            # per-user solution
  – git config --local core.autocrlf false              # per-project solution

PPS My personal preference is configuring the editor/IDE to use Unix-style endings, and setting core.autocrlf to false.


