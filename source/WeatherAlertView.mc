
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.System;
using WhatAppBase.Utils as Utils;

var gWeatherAlertViewRef as WeakReference? = null;

class WeatherAlertView extends WatchUi.DataFieldAlert {

    hidden var mAlert as WeatherAlert;
    hidden var mDescription as String = "";
    // hidden var mCounter as Number;
    public function initialize(alert as WeatherAlert) {
        DataFieldAlert.initialize();

        mAlert = alert;           
        // mCounter = 10;    
    }

    public function onUpdate(dc as Dc) as Void {   
        // mCounter = mCounter - 1;
        // if (mCounter < 0)  {
        //     WatchUi.popView(SLIDE_DOWN);
        //     return;
        // }
        if (mAlert == null) { return; }
        var height = dc.getHeight() / 2.5;
        var y = dc.getHeight() - height;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, y, dc.getWidth(), height);   

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var lineHeight = dc.getFontHeight(Graphics.FONT_SMALL);
        
        var alert = mAlert;
        dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_SMALL, alert.event, Graphics.TEXT_JUSTIFY_CENTER);
        y = y + lineHeight;

        if (alert.start != null) {
            var start = Gregorian.info(alert.start as Time.Moment, Time.FORMAT_MEDIUM);
            var startString = "From " + Lang.format("$1$-$2$-$3$ $4$:$5$", [start.day, start.month, start.year, start.hour.format("%02d"), start.min.format("%02d")]);
            dc.drawText(1, y, Graphics.FONT_SMALL, startString, Graphics.TEXT_JUSTIFY_LEFT);
            y = y + lineHeight;
        }
        if (alert.end != null) {
            var end = Gregorian.info(alert.end  as Time.Moment, Time.FORMAT_MEDIUM);
            var endString = "Until " + Lang.format("$1$-$2$-$3$ $4$:$5$", [end.day, end.month, end.year, end.hour.format("%02d"), end.min.format("%02d")]);            
            dc.drawText(1, y, Graphics.FONT_SMALL, endString, Graphics.TEXT_JUSTIFY_LEFT);
            y = y + lineHeight;
        }
        if (alert.description != null && alert.description.length() > 0) {            
            var desc = alert.description;
            if (mDescription.length() > 0) {
                desc = mDescription;
            } else {
                var textWidth = dc.getTextWidthInPixels(desc, Graphics.FONT_TINY);
                // @@ TODO: split text and calculate witdh until fit screen width .. or is there a IQ function for this?
                if (textWidth > dc.getWidth()) {
                    desc = Utils.stringReplacePos(desc, desc.length() / 2,  " ", "\n", 1);
                }
            }
            dc.drawText(1, y, Graphics.FONT_TINY, desc, Graphics.TEXT_JUSTIFY_LEFT);
            y = y + lineHeight;
        }
    }
}

class WeatherAlertHandler {
    var mAlertDisplayed as Array<String> = [] as Array<String>;

    public function initialize() { }

    public function isDisplayed(key as String) as Boolean { return mAlertDisplayed.indexOf(key) > -1; }
    public function setDisplayed(key as String) as Void { mAlertDisplayed.add(key); }

    public function handle(alerts as Array<WeatherAlert>) as Void {
        var max = alerts.size();        
        for (var idx = 0; idx < max; idx++) {
            // Alert is already being displayed
            if (gWeatherAlertViewRef != null && gWeatherAlertViewRef.stillAlive()) { return; }

            var alert = alerts[idx] as WeatherAlert;
            if (alert.handled) { continue; }
            if (alert.start != null && alert.end != null) {
                var key = alert.event + (alert.start as Moment).value().format("%d") 
                    + (alert.end as Moment).value().format("%d");

                if (isDisplayed(key)) { 
                    alert.handled = true;
                    continue;
                }

                setDisplayed(key);
                alert.handled = true;
                var weatherAlertView = new $.WeatherAlertView(alert);
                WatchUi.DataField.showAlert(weatherAlertView);
                gWeatherAlertViewRef = weatherAlertView.weak();
                return;
            }
        }    
    }
}