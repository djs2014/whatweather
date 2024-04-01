todo:

docu:

    - 
# owm
52.189 enough?
test alerts 3 after each other.
test mm pos text

- test if lat, lon in less 1 decimal gives other results.
- handle multiple alerts


getimage: alternative sites? weerplaza with geoip


-- 1h mm/hour snow or rain
 "pop": 1,
      "snow": {
        "1h": 0.54
      }
of 
  "pop": 1,
      "rain": {
        "1h": 1.05
      }

if include mmhour
[,,...,1hrain, 1hsnow]
[,,...,1.05, 0.54]


## alerts
x - array of alerts, indicate by array of start dates
x  - cache alerts per geo / for 10 min  
? - then extra call to retrieve the details
  


{
      "dt": 1679461200,
      "temp": 9.69,
      "feels_like": 6.45,
      "pressure": 1004,
      "humidity": 87,
      "dew_point": 7.63,
      "uvi": 0,
      "clouds": 0,
      "visibility": 10000,
      "wind_speed": 7.31,
      "wind_deg": 206,
      "wind_gust": 14.5,
      "weather": [
        {
          "id": 500,
          "main": "Rain",
          "description": "light rain",
          "icon": "10n"
        }
      ],
      "pop": 0.2,
      "rain": {
        "1h": 0.15  <--show this .. >
      }
    },

