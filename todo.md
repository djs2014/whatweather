smallfield 1040
 - height <= 93
 - 
 - >
- minutely
-> when rain first hour.
-> shift the mm graphic per minute


- show owm weather alert
  - enable in settings + enable in device
    - activity profiles - select profile - alerts - add connect iq - what weather
    - NB. what weather datafield should be in this profile
hide minutely when less than mm 0.1

????
alerts:
minutely text color night mode

- current hour == is for whole day ? default off..
  
x handle OWM error -> {json}
- OWM response error --> error code 200 met payload {error: {"cod":"400","message":"wrong latitude"} }
- code must be 200, else no data
- check lat lng valid in onbackground service before call

Added (:typecheck(false)) because of compiler bugs in strict mode.

- show alerts play sound?
- 
TL;DR;
 - don't use Toybox.Communications in import for foreground app (even if it is not used)

optimize	
    - use profiler to check duration -> cache some code results (wobbly line)
    - remove unused code -> comfort ..
    - radar -> offset to left x px

https://api.castlephoto.info/owm_one
http://localhost:4000/owm_one
ams 52.188950, 4.549666
lasvegas 36.16373271614203, -115.1262537886411


# Todo
	- Refactor the code, etc.	
	- BUG - one column + weather alarm -> continue beep
	- At initial start -> position is 0 (calc distance is then 5840km)? 			
	

vs code end of line --> LF
git -> CRLF settings
https://stackoverflow.com/questions/1967370/git-replacing-lf-with-crlf

  – git config --system core.autocrlf false            # per-system solution
  – git config --global core.autocrlf false            # per-user solution
  – git config --local core.autocrlf false              # per-project solution


