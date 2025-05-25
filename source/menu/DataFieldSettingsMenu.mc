import Toybox.Application;
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
  // hidden var _view as DataFieldSettingsView;

  function initialize() {
    // view as DataFieldSettingsView
    Menu2InputDelegate.initialize();
    //_view = view;
  }

  function onSelect(menuItem as MenuItem) as Void {
    _currentMenuItem = menuItem;
    var id = menuItem.getId();

    if (id instanceof String && id.equals("proxy")) {
      var proxyMenu = new WatchUi.Menu2({ :title => "Poi server config" });

      var mi = new WatchUi.MenuItem("Minimal GPS", null, "minimalGPSquality", null);
      var value = getStorageValue(mi.getId() as String, 1) as Number;
      mi.setSubLabel($.getMinimalGPSqualityText(value));
      proxyMenu.addItem(mi);
      // @@ api version
      // @@ proxy url - text picker
      // @@ proxy apikey - text picker
      // @@ owm apikey - text picker
      mi = new WatchUi.MenuItem("Checkinterval minutes |5", null, "checkIntervalMinutes", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Background timeout sec", null, "g_bg_timeout_seconds", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Background delay sec", null, "g_bg_delay_seconds", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);

      // Set initial position
      // @@ reset to false when used.
      // var boolean = Storage.getValue("useInitialPosition") ? true : false;
      // mi.addItem(new WatchUi.ToggleMenuItem("Use initial position", null, "useInitialPosition", boolean, null));

      // mi = new WatchUi.MenuItem("Initial position", null, "initialposition", null);
      // mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      // proxyMenu.addItem(mi);

      WatchUi.pushView(proxyMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("showweather")) {
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
      
      boolean = Storage.getValue("zoomMinuteForecast") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Zoom rain first hour", null, "zoomMinuteForecast", boolean, null));
      mi = new WatchUi.MenuItem("Zoom when mm >|0.0~", null, "zoomMinuteForecastMM", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      showMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Zoom factor |1~10", null, "zoomFactorMinuteForecast", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      showMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Max hours forecast|0~24", null, "maxHoursForecast", null);
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

      boolean = Storage.getValue("showRelativeWind") ? true : false;
      showMenu.addItem(new WatchUi.ToggleMenuItem("Wind relative", null, "showRelativeWind", boolean, null));

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

      WatchUi.pushView(showMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("extrainfo")) {
      var extraMenu = new WatchUi.Menu2({ :title => "Extra info" });
      var mi = new WatchUi.MenuItem("One page field", null, "showInfoOneField", null);
      var value = getStorageValue(mi.getId() as String, $._showInfoLargeField) as Number;
      mi.setSubLabel($.getShowInfoText(value));
      extraMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Large field", null, "showInfoLargeField", null);
      value = getStorageValue(mi.getId() as String, $._showInfoLargeField) as Number;
      mi.setSubLabel($.getShowInfoText(value));
      extraMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Wide field", null, "showInfoWideField", null);
      value = getStorageValue(mi.getId() as String, $._showInfoSmallField) as Number;
      mi.setSubLabel($.getShowInfoText(value));
      extraMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Small field", null, "showInfoSmallField", null);
      value = getStorageValue(mi.getId() as String, $._showInfoSmallField) as Number;
      mi.setSubLabel($.getShowInfoText(value));
      extraMenu.addItem(mi);

      WatchUi.pushView(extraMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("alerts")) {
      var alertsMenu = new WatchUi.Menu2({ :title => "Alerts" });

      var mi = new WatchUi.MenuItem("Precipitation chance|0~100", null, "alertLevelPrecipitationChance", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("MM rain 1st h |0.0~100.0", null, "alertLevelRainMMfirstHour", null);
      mi.setSubLabel($.getStorageFloatAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("MM rain / h |0.0~100.0", null, "alertLevelRainMMHour", null);
      mi.setSubLabel($.getStorageFloatAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("UV index|0~20", null, "alertLevelUVi", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Wind in", null, "alertWindIn", null);
      var value = getStorageValue(mi.getId() as String, $._alertWindIn) as Number;
      if (value == SHOW_WIND_NOTHING) { 
        value = SHOW_WIND_BEAUFORT;
      }
      var windIn = $.getShowWindText(value);
      mi.setSubLabel(windIn);
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Wind " + windIn, null, "alertLevelWindSpeed", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Wind gust", null, "alertLevelWindGust", null);
      value = getStorageValue(mi.getId() as String, 2) as Number;
      mi.setSubLabel($.getGustLevelText(value));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Dewpoint (C) |0~50", null, "alertLevelDewpoint", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      WatchUi.pushView(alertsMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
    }
    if (id instanceof String && id.equals("advanced")) {
      var advancedMenu = new WatchUi.Menu2({ :title => "Advanced" });

      var mi = new WatchUi.MenuItem("Max temperature (C)|0~100", null, "maxTemperature", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Max UV index|0~50", null, "maxUVIndex", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Min pressure (hPa)|0~1200", null, "minPressure", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Max pressure (hPa)|0~1200", null, "maxPressure", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Max rain per hour (mm))|1~20", null, "maxMMRainPerHour", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);
      
      WatchUi.pushView(advancedMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("comfort")) {
      var comfortMenu = new WatchUi.Menu2({ :title => "Comfort" });

      var mi = new WatchUi.MenuItem("Min humidity (%)|0~100", null, "comfortHumidityMin", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      comfortMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Max humidity (%)|0~100", null, "comfortHumidityMax", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      comfortMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Min temp (C)|0~100", null, "comfortTempMin", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      comfortMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Max temp (C)|0~100", null, "comfortTempMax", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      comfortMenu.addItem(mi);

      WatchUi.pushView(comfortMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("sound")) {
      var soundMenu = new WatchUi.Menu2({ :title => "Alert sound/light" });
      // mode: silent,beep,canary
      var mi = new WatchUi.MenuItem("Sound", null, "sound_mode", null);
      var value = getStorageValue(mi.getId() as String, 1) as Number;
      mi.setSubLabel($.getSoundModeText(value));
      soundMenu.addItem(mi);

      var boolean = Storage.getValue("alert_backlight") ? true : false;
      soundMenu.addItem(new WatchUi.ToggleMenuItem("Backlight", null, "alert_backlight", boolean, null));

      WatchUi.pushView(soundMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("demo")) {
      // var demoMenu = new WatchUi.Menu2({ :title => "Demo" });
      // some scenarios, set duration, no OWM api key needed
      return;
    }
    if (id instanceof String && menuItem instanceof ToggleMenuItem) {
      Storage.setValue(id as String, menuItem.isEnabled());
      return;
    }
  }
}

class GeneralMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _item as MenuItem?;
  hidden var _currentPrompt as String = "";
  hidden var _debug as Boolean = false;

  function initialize() {
    Menu2InputDelegate.initialize();
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
    }
    if (id instanceof String && id.equals("weatherDataSource")) {
      var sp = new selectionMenuPicker("Weather source", id as String);
      for (var i = 0; i < 4; i++) {
        sp.add($.getWeatherDataSourceText(i as WeatherSource), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && (id.equals("showWind") || id.equals("alertWindIn"))){
      var sp = new selectionMenuPicker("Wind display", id as String);
      for (var i = 0; i < 4; i++) {
        sp.add($.getShowWindText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("showInfoOneField")) {
      var sp = new selectionMenuPicker("One page field", id as String);
      for (var i = 0; i <= 5; i++) {
        sp.add($.getShowInfoText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("showInfoLargeField")) {
      var sp = new selectionMenuPicker("Large field", id as String);
      for (var i = 0; i <= 5; i++) {
        sp.add($.getShowInfoText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("showInfoWideField")) {
      var sp = new selectionMenuPicker("Wide field", id as String);
      for (var i = 0; i <= 5; i++) {
        sp.add($.getShowInfoText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("showInfoSmallField")) {
      var sp = new selectionMenuPicker("Small field", id as String);
      for (var i = 0; i <= 5; i++) {
        sp.add($.getShowInfoText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("alertLevelWindGust")) {
      var sp = new selectionMenuPicker("Wind gust level", id as String);
      for (var i = 0; i <= 3; i++) {
        sp.add($.getGustLevelText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("sound_mode")) {
      var sp = new selectionMenuPicker("Sound level", id as String);
      for (var i = 0; i <= 3; i++) {
        sp.add($.getSoundModeText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && item instanceof ToggleMenuItem) {
      Storage.setValue(id as String, item.isEnabled());
      return;
    }

    // Numeric input
    var prompt = item.getLabel();
    var value = $.getStorageValue(id as String, 0) as Numeric;
    var view = $.getNumericInputView(prompt, value);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_RIGHT);
  }

  function onAcceptNumericinput(value as Numeric, subLabel as String) as Void {
    try {
      if (_item != null) {
        var storageKey = _item.getId() as String;

        Storage.setValue(storageKey, value);
        (_item as MenuItem).setSubLabel(subLabel);
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function onNumericinput(
    editData as Array<Char>,
    cursorPos as Number,
    insert as Boolean,
    negative as Boolean,
    opt as NumericOptions
  ) as Void {
    // Hack to refresh screen
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    var view = new $.NumericInputView("", 0);
    view.processOptions(opt);
    view.setEditData(editData, cursorPos, insert, negative);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

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

  function onSelectedSelection(storageKey as String, value as Application.PropertyValueType) as Void {
    Storage.setValue(storageKey, value);
  }
}
