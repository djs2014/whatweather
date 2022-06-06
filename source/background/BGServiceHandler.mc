// Version 1.0.1
import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Time;
import Toybox.Background;
using WhatAppBase.Utils;

class BGServiceHandler {    
    var mCurrentLocation as Utils.CurrentLocation?;
    var mError as Number = 0; 
    var mHttpStatus as Number = BGService.HTTP_OK;
    var mPhoneConnected as Boolean = false;    
    var mBGActive as Boolean = false;
    var mBGDisabled as Boolean = false;

    var mUpdateFrequencyInMinutes as Number = 5;
    var mRequestCounter as Number = 0; 
    var mObservationTimeDelayedMinutesThreshold as Number = 10;
    var mMinimalGPSLevel as Number = 3;
            
    var mLastRequestMoment as Time.Moment?; 
    var mLastObservationMoment as Time.Moment?; 
    var mData as Object?;

    // var methodOnBeforeWebrequest = null;

    function initialize() {}
    function setCurrentLocation(currentLocation as Utils.CurrentLocation) as Void {
        mCurrentLocation = currentLocation;
    }

    function setMinimalGPSLevel(level as Number) as Void { mMinimalGPSLevel = level; }
    function setUpdateFrequencyInMinutes(minutes as Number) as Void {mUpdateFrequencyInMinutes = minutes; }
    function Disable() as Void { mBGDisabled = true; }
    function Enable() as Void { mBGDisabled = false;  reset(); }
    function setObservationTimeDelayedMinutes(minutes as Number) as Void { mObservationTimeDelayedMinutesThreshold = minutes; }
    function isDataDelayed() as Boolean {
        return Utils.isDelayedFor(mLastObservationMoment, mObservationTimeDelayedMinutesThreshold);
    }
    function hasError() as Boolean { return mError != BGService.ERROR_BG_NONE || mHttpStatus != BGService.HTTP_OK; }
    function reset() as Void {
        System.println("Reset BG service");
        mError = 0;
        mHttpStatus = BGService.HTTP_OK;
    }
    function onCompute(info as Activity.Info) as Void {
        mPhoneConnected = System.getDeviceSettings().phoneConnected;        
        if (mCurrentLocation != null) {
            mCurrentLocation.onCompute(info);
        }
    }

    function autoScheduleService() as Void {
        if (mBGDisabled) { return; }
        
        try {
            testOnNonFatalError();            
            
            // @@ disable temporary when position not changed ( less than x km distance) and last call < x minutes?
            if (hasError()) {                
                stopBGservice();
                return;
            }

            startBGservice();            
        } catch (ex) {
            ex.printStackTrace();
        } 
        // Doesnt work!
        // finally {
        //     mError = error;
        //     if (error !=BGService.ERROR_BG_NONE) {
        //         stopBGservice();
        //     }
        // }      
    }
    
    hidden function testOnNonFatalError() as Void {
        if (mError == BGService.ERROR_BG_GPS_LEVEL || mError == BGService.ERROR_BG_NO_PHONE || mError == BGService.ERROR_BG_NO_POSITION ) {
            mError =BGService.ERROR_BG_NONE;
        }
        
        if (!mPhoneConnected) {
            mError =BGService.ERROR_BG_NO_PHONE;            
        } else if (mCurrentLocation != null) {
            var currentLocation = mCurrentLocation as Utils.CurrentLocation;
            if (currentLocation.getAccuracy() < mMinimalGPSLevel) { 
                mError =BGService.ERROR_BG_GPS_LEVEL;                    
            } else if (!currentLocation.hasLocation()) {
                mError =BGService.ERROR_BG_NO_POSITION;
            }
        }     
    }

    function stopBGservice() as Void {
        if (!mBGActive) { return; }
        try {
            Background.deleteTemporalEvent();
            mBGActive = false;
            mError =BGService.ERROR_BG_NONE;
            System.println("stopBGservice stopped"); 
        } catch (ex) {
            ex.printStackTrace();
            mError =BGService.ERROR_BG_EXCEPTION;
            mBGActive = false;
        } 
    }

    function startBGservice() as Void {
        if (mBGDisabled) {
            System.println("startBGservice Service is disabled, no scheduling"); 
            return;
        }
        if (mBGActive) {
            System.println("startBGservice already active"); 
            return;
        }
        
        try {
            if (Toybox.System has :ServiceDelegate) {
                Background.registerForTemporalEvent(new Time.Duration(mUpdateFrequencyInMinutes * 60));
                mBGActive = true;
                mError =BGService.ERROR_BG_NONE;
                mHttpStatus = BGService.HTTP_OK;
                System.println("startBGservice registerForTemporalEvent [" +
                            mUpdateFrequencyInMinutes + "] minutes scheduled");
            } else {
                System.println("Unable to start BGservice (no registerForTemporalEvent)");
                mBGActive = false;
                mError =BGService.ERROR_BG_NOT_SUPPORTED;
                System.exit(); // @@ ??
            }
        } catch (ex) {
            ex.printStackTrace();
            mError =BGService.ERROR_BG_EXCEPTION;
            mBGActive = false;
        } 
    }

    function getWhenNextRequest() as String? {
        if (hasError() || mBGDisabled || !mBGActive) { return null; }
        var lastTime = Background.getLastTemporalEventTime();
        if (lastTime == null) { return null; }
        var elapsedSeconds = Time.now().value() - lastTime.value();
        var secondsToNext = (mUpdateFrequencyInMinutes * 60) - elapsedSeconds;
        return Utils.secondsToShortTimeString(secondsToNext, "{m}:{s}");
    }
 
    function onBackgroundData(data as Application.PropertyValueType, obj as Object, cbProcessData as Symbol) as Void {                
        mLastRequestMoment = Time.now();
        if (data instanceof Lang.Number) {
            // Check for known error else http status
            var code = data as Lang.Number;
            if (code < 0) {
                mError = code;
            } else {
                mHttpStatus = code;\
                mError = BGService.ERROR_BG_HTTPSTATUS;
            }
            System.println("onBackgroundData error responsecode: " + data);
        } else {
            mHttpStatus = BGService.HTTP_OK;
            mData = data;
            mError = BGService.ERROR_BG_NONE;
            mRequestCounter = mRequestCounter + 1;
            if (obj != null) {
                var processData = new Lang.Method(obj, cbProcessData);
                processData.invoke(self, data);
            }
        }    
    }
    function setLastObservationMoment(moment as Time.Moment?) as Void {
        mLastObservationMoment = moment;
    }

    function getStatus() as Lang.String {
        // @@ enum/const
        if (mBGDisabled) { return "Disabled"; }
        if (mBGActive) { return "Active"; }
        // @@ + countdown minutes?
        if (!mBGActive) { return "Inactive"; }
        return "";
    }
    
    function getCounterStats() as Lang.String {
        return mRequestCounter.format("%0d");
    }

    function getError() as Lang.String {
        if (mHttpStatus != BGService.HTTP_OK) {
             return "Http [" + mHttpStatus.format("%0d") + "]";    
        }
        if (mError == BGService.ERROR_BG_NONE) {
            return "";
        }
        if (mError == BGService.ERROR_BG_NO_API_KEY) {
            return "ApiKey?";
        }
        if (mError == BGService.ERROR_BG_NO_POSITION) {
            return "Position?";
        }
        if (mError == BGService.ERROR_BG_NO_PROXY) {
            return "Proxy?";
        }
        if (mError == BGService.ERROR_BG_EXCEPTION) {
            return "Error?";
        }
        if (mError == BGService.ERROR_BG_EXIT_DATA_SIZE_LIMIT) {
            return "Memory?";
        }
        if (mError == BGService.ERROR_BG_INVALID_BACKGROUND_TIME) {
            return "ScheduleTime?";
        }
        if (mError == BGService.ERROR_BG_NOT_SUPPORTED) {
            return "Supported?";
        }
        if (mError == BGService.ERROR_BG_NO_PHONE) {
            return "Phone?";
        }
        if (mError == BGService.ERROR_BG_GPS_LEVEL) {
            return "Gps quality?";
        }
        if (mError == BGService.ERROR_BG_HTTPSTATUS) {
            return "Http [" + mHttpStatus.format("%0d") + "]";
        }
        return "";
    }
}
