import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

var gExitedMenu as Boolean = false;

//! Initial view for the settings
class DataFieldSettingsView extends WatchUi.View {
  //! Constructor
  function initialize() {
    View.initialize();
  }

  //! Update the view
  //! @param dc Device context
  function onUpdate(dc as Dc) as Void {
    dc.clearClip();
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    var version = System.getDeviceSettings().monkeyVersion;
    var versionString = Lang.format("$1$.$2$.$3$", version);

    dc.drawText(
      dc.getWidth() / 2,
      dc.getHeight() / 2 - 30,
      Graphics.FONT_SMALL,
      "Press Menu \nfor settings \nCIQ " + versionString,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }
}

//! Handle opening the settings menu
class DataFieldSettingsDelegate extends WatchUi.BehaviorDelegate {
  //! Constructor
  function initialize() {
    BehaviorDelegate.initialize();
  }

  //! Handle the menu event
  //! @return true if handled, false otherwise
  function onMenu() as Boolean {
    var menu = new $.DataFieldSettingsMenu();
    var mi = new WatchUi.MenuItem("Proxy", "Server config", "proxy", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Show weather", null, "showweather", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Extra information", null, "extrainfo", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Alerts", null, "alerts", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Comfort region", null, "comfort", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Advanced", null, "advanced", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Sound", null, "sound", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Demo", null, "demo", null);
    menu.addItem(mi);

    var boolean = false;

    boolean = Storage.getValue("resetAlerts") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Show alerts again", null, "resetAlerts", boolean, null));
    // boolean = Storage.getValue("debug") ? true : false;
    // menu.addItem(new WatchUi.ToggleMenuItem("Debug", null, "debug", boolean, null));
    boolean = Storage.getValue("resetDefaults") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Reset to defaults", null, "resetDefaults", boolean, null));
  


    // var view = new $.DataFieldSettingsView();
    WatchUi.pushView(menu, new $.DataFieldSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
    return true;
  }

  function onBack() as Boolean {
    getApp().onSettingsChanged();    
    $.gExitedMenu = true;
    return false;
  }
}

function getStorageNumberAsString(key as String) as String {
  return (getStorageValue(key, 0) as Number).format("%0d");
}

function getStorageFloatAsString(key as String) as String {
  return (getStorageValue(key, 0.0f) as Float).format("%.1f");
}

function getMinimalGPSqualityText(value as Number) as String {
  switch (value) {
    case 0:
      return "Not available";
    case 1:
      return "Last known";
    case 2:
      return "Poor";
    case 3:
      return "Usable";
    case 4:
      return "Good";

    default:
      return "Not available";
  }
}

function getWeatherDataSourceText(value as WeatherSource) as String {
  switch (value) {
    case wsGarminFirst:
      return "Garmin first";
    case wsOWMFirst:
      return "OWM first";
    case wsGarminOnly:
      return "Garmin";
    case wsOWMOnly:      
      return "Open Weather Map";

    default:
      return "Garmin first";
  }
}

function getShowWindText(value as Number) as String {
  switch (value) {
    case SHOW_WIND_NOTHING:
      return "Nothing";
    case SHOW_WIND_METERS:
      return "Meters/sec";
    case SHOW_WIND_KILOMETERS:
      return "Kilometers/sec";
    case SHOW_WIND_BEAUFORT:
      return "Beaufort";
    
    default:
      return "--";
  }
}

function getShowInfoText(value as Number) as String {
  switch (value) {
    case SHOW_INFO_NOTHING:
      return "Nothing";
    case SHOW_INFO_TIME_Of_DAY:
      return "Time";    
    case SHOW_INFO_AMBIENT_PRESSURE:
      return "Pressure";
    case SHOW_INFO_SEALEVEL_PRESSURE:
      return "Pressure at sea";
    case SHOW_INFO_DISTANCE:
      return "Distance";
    case SHOW_INFO_RELATIVE_WIND:
      return "Relative wind";

    default:
      return "--";
  }
}
function getGustLevelText(value as Number) as String {
  switch (value) {
    case 0:
      return "None";
    case 1:
      return "Gusts";
    case 2:
      return "Strong gusts";    
    case 3:
      return "Violent gusts";
    
    default:
      return "--";
  }
}

function getSoundModeText(value as Number) as String {
  switch (value) {
    case 0:
      return "Quiet";
    case 1:
      return "Beep";
    case 2:
      return "Canary";    
    case 3:
      return "Beep Beep";    

    default:
      return "--";
  }
}
