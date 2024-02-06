import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class DataFieldSettingsMenu extends WatchUi.Menu2 {
  function initialize() {
    Menu2.initialize({ :title => "Settings" });
  }
}

//! Handles menu input and stores the menu data
class DataFieldSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _currentMenuItem as MenuItem?;
  hidden var _view as DataFieldSettingsView;

  function initialize(view as DataFieldSettingsView) {
    Menu2InputDelegate.initialize();
    _view = view;
  }

  function onSelect(menuItem as MenuItem) as Void {
    _currentMenuItem = menuItem;
    var id = menuItem.getId();

    if (id instanceof String && id.equals("proxy")) {
      var proxyMenu = new WatchUi.Menu2({ :title => "Poi server config" });

      var mi = new WatchUi.MenuItem("Minimal GPS", null, "minimalGPSquality", null);
      var value = getStorageValue(mi.getId() as String, $.gMinimalGPSquality) as Number;
      mi.setSubLabel($.getMinimalGPSqualityText(value));
      proxyMenu.addItem(mi);
      // @@ api version
      // @@ proxy url - text picker
      // @@ proxy apikey - text picker
      // @@ owm apikey - text picker
      mi = new WatchUi.MenuItem("Checkinterval minutes", null, "checkIntervalMinutes", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);
                  
      WatchUi.pushView(proxyMenu, new $.GeneralMenuDelegate(self, proxyMenu), WatchUi.SLIDE_UP);
    } else if (id instanceof String && id.equals("showweather")) {
      var showMenu = new WatchUi.Menu2({ :title => "Show Weather" });

      // @@ Weather source 
      var mi = new WatchUi.MenuItem("Weather source", null, "weatherDataSource", null);
      var value = getStorageValue(mi.getId() as String, $._weatherDataSource) as WeatherSource;
      mi.setSubLabel($.getWeatherDataSourceText(value));
      showMenu.addItem(mi);

      var boolean = Storage.getValue("showCurrentForecast") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Current forecast", null, "showCurrentForecast", boolean, null));
      boolean = Storage.getValue("showMinuteForecast") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Rain first hour", null, "showMinuteForecast", boolean, null));
      // @@ max ..
      mi = new WatchUi.MenuItem("Max hours forecast |0-24", null, "maxHoursForecast", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      showMenu.addItem(mi);

      boolean = Storage.getValue("showClouds") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Clouds", null, "showClouds", boolean, null));

      mi = new WatchUi.MenuItem("Wind", null, "showWind", null);
      value = getStorageValue(mi.getId() as String, $._showWind) as Number;
      mi.setSubLabel($.getShowWindText(value));
      showMenu.addItem(mi);
      boolean = Storage.getValue("showCurrentWind") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Current wind", null, "showCurrentWind", boolean, null));    
      boolean = Storage.getValue("showUVIndex") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("UV", null, "showUVIndex", boolean, null));
      boolean = Storage.getValue("showTemperature") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Temperature", null, "showTemperature", boolean, null));
      boolean = Storage.getValue("showRelativeHumidity") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Relative humidity", null, "showRelativeHumidity", boolean, null));
      
      boolean = Storage.getValue("showPressure") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Pressure sealevel", null, "showPressure", boolean, null));
      boolean = Storage.getValue("showDewpoint") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Dewpoint", null, "showDewpoint", boolean, null));
      boolean = Storage.getValue("showComfortZone") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Comfort zone", null, "showComfortZone", boolean, null));
      boolean = Storage.getValue("showWeatherCondition") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Weather condition", null, "showWeatherCondition", boolean, null));     

      WatchUi.pushView(showMenu, new $.GeneralMenuDelegate(self, showMenu), WatchUi.SLIDE_UP);
    } else if (id instanceof String && id.equals("extrainfo")) {
      // var sfMenu = new WatchUi.Menu2({ :title => "Extra info" });

      // var boolean = Storage.getValue("sf_showWptDirection") ? true : false;
      // sfMenu.addItem(new WatchUi.ToggleMenuItem("Waypoint direction", null, "sf_showWptDirection", boolean, null));
      // boolean = Storage.getValue("sf_showWptDistance") ? true : false;
      // sfMenu.addItem(new WatchUi.ToggleMenuItem("Waypoint distance", null, "sf_showWptDistance", boolean, null));
      // boolean = Storage.getValue("sf_ShowCircleDistance") ? true : false;
      // sfMenu.addItem(new WatchUi.ToggleMenuItem("Range distance lable", null, "sf_ShowCircleDistance", boolean, null));

      // var mi = new WatchUi.MenuItem("Extra range meters", null, "sf_extraRangeMeters", null);
      // mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      // sfMenu.addItem(mi);

      // mi = new WatchUi.MenuItem("Fixed range meters", null, "sf_fixedRangeMeters", null);
      // mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      // sfMenu.addItem(mi);

      // mi = new WatchUi.MenuItem("Zoom # waypoints", null, "sf_zoomMinWaypoints", null);
      // mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      // sfMenu.addItem(mi);

      // mi = new WatchUi.MenuItem("Zoom on 1 meters", null, "sf_zoomOneMeters", null);
      // mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      // sfMenu.addItem(mi);

      // WatchUi.pushView(sfMenu, new $.GeneralMenuDelegate(self, sfMenu), WatchUi.SLIDE_UP);
    } else if (id instanceof String && id.equals("alerts")) {
      var alertsMenu = new WatchUi.Menu2({ :title => "Alerts" });

      // label
      // subLabel (value) + |0-100 
      var mi = new WatchUi.MenuItem("Precipitation chance |0-100", null, "alertLevelPrecipitationChance", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      WatchUi.pushView(alertsMenu, new $.GeneralMenuDelegate(self, alertsMenu), WatchUi.SLIDE_UP);                  
    } else if (id instanceof String && menuItem instanceof ToggleMenuItem) {
      Storage.setValue(id as String, menuItem.isEnabled());
      menuItem.setSubLabel($.subMenuToggleMenuItem(id as String));
    }
  }
}

class GeneralMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _delegate as DataFieldSettingsMenuDelegate;
  hidden var _item as MenuItem?;
  hidden var _currentPrompt as String = "";
  hidden var _debug as Boolean = false;
  hidden var _numericOptions as NumericOptions = new NumericOptions();

  function initialize(delegate as DataFieldSettingsMenuDelegate, menu as WatchUi.Menu2) {
    Menu2InputDelegate.initialize();
    _delegate = delegate;
  }

  function onSelect(item as MenuItem) as Void {
    _item = item;
    var id = item.getId();
    if (id instanceof String && id.equals("minimalGPSquality")) {
      var sp = new selectionMenuPicker("Minimal GPS", id as String);
      for (var i = 0; i <= 4; i++) {
        sp.add($.getMinimalGPSqualityText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    } else if (id instanceof String && id.equals("weatherDataSource")) {
      var sp = new selectionMenuPicker("Weather source", id as String);
      for (var i = 0; i < 4; i++) {
        sp.add($.getWeatherDataSourceText(i as WeatherSource), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    } else if (id instanceof String && id.equals("showWind")) {
      var sp = new selectionMenuPicker("Wind display", id as String);
      for (var i = 0; i < 4; i++) {
        sp.add($.getShowWindText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    } else if (id instanceof String && item instanceof ToggleMenuItem) {
      Storage.setValue(id as String, item.isEnabled());
      item.setSubLabel($.subMenuToggleMenuItem(id as String));
      return;
    } else if (id instanceof String && id.equals("alert_startAfterUnits")) {
      var sp = new selectionMenuPicker("Alert after", id as String);

      // sp.add($.getStartAfterUnitsText(AfterXKilometer), null, AfterXKilometer);
      // sp.add($.getStartAfterUnitsText(AfterXMinutes), null, AfterXMinutes);

      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    _currentPrompt = item.getLabel();

    var currentValue = $.getStorageValue(id as String, 0) as Number;
    var view = new $.NumericInputView(_debug, _currentPrompt, currentValue);

    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);
    
    // @@TODO parse label / sublabel to get min max
    _numericOptions = parseLabelToOptions(_currentPrompt);
    // _numericOptions.minValue = 0;
    // _numericOptions.maxValue = 100;
    view.setOptions(_numericOptions);
    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view) , WatchUi.SLIDE_RIGHT);
  }

  // function onSelectedAfterXUnits(value as Object, storageKey as String) as Void {
  //   var unit = value as AfterXUnits;
  //   Storage.setValue(storageKey, unit);
  //   if (_item != null) {
  //     (_item as MenuItem).setSubLabel($.getStartAfterUnitsText(unit));
  //   }
  // }

  function onAcceptNumericinput(value as Number) as Void {
    try {
      if (_item != null) {
        var storageKey = _item.getId() as String;
        Storage.setValue(storageKey, value);
        (_item as MenuItem).setSubLabel(value.format("%.0d"));
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function onNumericinput(
    editData as Array<Char>,
    cursorPos as Number,
    insert as Boolean,
    negative as Boolean
  ) as Void {
    // Hack to refresh screen
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    var view = new $.NumericInputView(_debug, _currentPrompt, 0);
    view.setEditData(editData, cursorPos, insert, negative);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);
    view.setOptions(_numericOptions);

    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_IMMEDIATE);
  }

  //! Handle the back key being pressed

  function onBack() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  //! Handle the done item being selected

  function onDone() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  function onSelectedSelection(value as Object, storageKey as String) as Void {
    var quality = value as Number;
    Storage.setValue(storageKey, quality);
  }
}
