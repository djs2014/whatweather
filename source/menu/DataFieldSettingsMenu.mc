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
  hidden var _item as MenuItem?;
  hidden var _storageKey as String = "";
  hidden var _arrayIndex as Number = -1;

  function initialize() {
    // view as DataFieldSettingsView
    Menu2InputDelegate.initialize();
    //_view = view;
  }

  function onSelect(menuItem as MenuItem) as Void {
    _item = menuItem;
    var id = menuItem.getId();

    // System.println(["onSelect id", id, id.toString(), id instanceof String]);

    // Extract selected storage key and index
    _storageKey = stringLeft(id.toString(), "|", id.toString());
    var idx = stringRight(id.toString(), "|", "").toNumber();
    if (idx == null) {
      _arrayIndex = -1;
    } else {
      _arrayIndex = idx;
    }

    if (id instanceof String && id.equals("proxy")) {
      var proxyMenu = new WatchUi.Menu2({ :title => "Poi server config" });

      var mi = new WatchUi.MenuItem(
        "Minimal GPS",
        null,
        "minimalGPSquality",
        null
      );
      var value = getStorageValue(mi.getId() as String, 1) as Number;
      mi.setSubLabel($.getMinimalGPSqualityText(value));
      proxyMenu.addItem(mi);
      // @@ api version
      // @@ proxy url - text picker
      // @@ proxy apikey - text picker
      // @@ owm apikey - text picker
      mi = new WatchUi.MenuItem(
        "Checkinterval|5~(minutes)",
        null,
        "checkIntervalMinutes",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Background timeout sec",
        null,
        "g_bg_timeout_seconds",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Background delay sec",
        null,
        "g_bg_delay_seconds",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      proxyMenu.addItem(mi);

      // mi = new WatchUi.MenuItem("Weather source", null, "weatherDataSource", null);
      // value = getStorageValue(mi.getId() as String, $._weatherDataSource) as WeatherSource;
      // mi.setSubLabel($.getWeatherDataSourceText(value));
      // proxyMenu.addItem(mi);

      WatchUi.pushView(
        proxyMenu,
        new $.GeneralMenuDelegate(),
        WatchUi.SLIDE_UP
      );
      return;
    }

    if (
      id instanceof String &&
      (id.equals("show_one_field") ||
        id.equals("show_large_field") ||
        id.equals("show_wide_field") ||
        id.equals("show_small_field"))
    ) {
      var label = menuItem.getLabel();
      var prefix = id.toString();
      var fieldMenu = new WatchUi.Menu2({ :title => label + " items" });

      var storageKey = id.toString();

      var array = $.getStorageValue(storageKey, []) as Array<Number or Boolean>;
      // Check size
      if (
        $.ensureArraySize(
          array as Array<Application.PropertyValueType>,
          $.gSizeArrFieldItems,
          0
        )
      ) {
        $.setStorageValueOrArray(
          storageKey,
          array as Array<Application.PropertyValueType>
        );
      }
      var index = 0;
      $.addMenuItem(
        fieldMenu,
        "Hours forecast|0~24",
        (array[index] as Number).toString(),
        getKeyAndIndex(storageKey, index)
      );

      index = 1;
      $.addToggleMenuItem(
        fieldMenu,
        "Rain first hour",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 2;
      $.addToggleMenuItem(
        fieldMenu,
        "Zoom when rain",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 3;
      $.addMenuItem(
        fieldMenu,
        "Zoom when more than|.(mm)",
        (array[index] as Number).toString(),
        getKeyAndIndex(storageKey, index)
      );

      index = 4;
      $.addMenuItem(
        fieldMenu,
        "Zoom factor|1~10",
        (array[index] as Number).toString(),
        getKeyAndIndex(storageKey, index)
      );

      index = 5;
      $.addMenuItem(
        fieldMenu,
        "Zoom columns|1~6",
        (array[index] as Number).toString(),
        getKeyAndIndex(storageKey, index)
      );

      index = 6;
      $.addToggleMenuItem(
        fieldMenu,
        "Details on alert",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 7;
      $.addToggleMenuItem(
        fieldMenu,
        "Clouds",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 8;
      $.addToggleMenuItem(
        fieldMenu,
        "Wind",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 9; // show_one_field|9 etc
      $.addMenuItem(
        fieldMenu,
        "Wind unit",
        $.getShowWindText(array[index] as Number),
        $.getKeyAndIndex(storageKey, index)
      );

      index = 10;
      $.addToggleMenuItem(
        fieldMenu,
        "UV",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 11;
      $.addToggleMenuItem(
        fieldMenu,
        "Temperature",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 12;
      $.addToggleMenuItem(
        fieldMenu,
        "Relative humidity",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 13;
      $.addToggleMenuItem(
        fieldMenu,
        "Pressure sealevel",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 14;
      $.addToggleMenuItem(
        fieldMenu,
        "Dewpoint",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 15;
      $.addToggleMenuItem(
        fieldMenu,
        "Comfort zone",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      // Weather condition
      index = 16; // show_one_field|16
      $.addToggleMenuItem(
        fieldMenu,
        "Weather icons",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 17;
      $.addMenuItem(
        fieldMenu,
        "Extra info",
        $.getShowInfoText(array[index] as Number),
        $.getKeyAndIndex(storageKey, index)
      );

      index = 18;
      $.addToggleMenuItem(
        fieldMenu,
        "Details on pause",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 19;
      $.addToggleMenuItem(
        fieldMenu,
        "0 temperature line",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      index = 20;
      $.addToggleMenuItem(
        fieldMenu,
        "Weather text",
        null,
        $.getKeyAndIndex(storageKey, index),
        array[index] == true
      );

      WatchUi.pushView(
        fieldMenu,
        new $.GeneralMenuDelegate(),
        WatchUi.SLIDE_UP
      );
      return;
    }

    if (id instanceof String && id.equals("alerts")) {
      var alertsMenu = new WatchUi.Menu2({ :title => "Alerts" });

      var mi = new WatchUi.MenuItem(
        "Precipitation chance|0~100",
        null,
        "alertLevelPrecipitationChance",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "MM rain 1st h |0.0~100.0",
        null,
        "alertLevelRainMMfirstHour",
        null
      );
      mi.setSubLabel($.getStorageFloatAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "MM rain / h |0.0~100.0",
        null,
        "alertLevelRainMMHour",
        null
      );
      mi.setSubLabel($.getStorageFloatAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("UV index|0~20", null, "alertLevelUVi", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Wind in", null, "alertWindIn", null);
      var value =
        getStorageValue(mi.getId() as String, $._alertWindIn) as Number;
      var windIn = $.getShowWindText(value);
      mi.setSubLabel(windIn);
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Wind " + windIn,
        null,
        "alertLevelWindSpeed",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Wind gust", null, "alertLevelWindGust", null);
      value = getStorageValue(mi.getId() as String, 2) as Number;
      mi.setSubLabel($.getGustLevelText(value));
      alertsMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Dewpoint|0~50 (C)",
        null,
        "alertLevelDewpoint",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      alertsMenu.addItem(mi);

      WatchUi.pushView(
        alertsMenu,
        new $.GeneralMenuDelegate(),
        WatchUi.SLIDE_UP
      );
    }
    if (id instanceof String && id.equals("advanced")) {
      var advancedMenu = new WatchUi.Menu2({ :title => "Advanced" });

      var mi = new WatchUi.MenuItem(
        "Min temperature|-10~50 (C)",
        null,
        "minTemperature",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Max temperature|0~50 (C)",
        null,
        "maxTemperature",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Max UV index|0~50", null, "maxUVIndex", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Min pressure|0~1200 (hPa)",
        null,
        "minPressure",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Max pressure|0~1200 (hPa)",
        null,
        "maxPressure",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Max rain per hour|1~20 (mm)",
        null,
        "maxMMRainPerHour",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Hide details below y-axis|0~100 (%)",
        null,
        "percHideDetails",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advancedMenu.addItem(mi);

      WatchUi.pushView(
        advancedMenu,
        new $.GeneralMenuDelegate(),
        WatchUi.SLIDE_UP
      );
      return;
    }
    if (id instanceof String && id.equals("comfort")) {
      var comfortMenu = new WatchUi.Menu2({ :title => "Comfort" });

      var mi = new WatchUi.MenuItem(
        "Min humidity|0~100 (%)",
        null,
        "comfortHumidityMin",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      comfortMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Max humidity|0~100(%)",
        null,
        "comfortHumidityMax",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      comfortMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Min temp|-10~100(C)",
        null,
        "comfortTempMin",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      comfortMenu.addItem(mi);
      mi = new WatchUi.MenuItem(
        "Max temp|0~100(C)",
        null,
        "comfortTempMax",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      comfortMenu.addItem(mi);

      WatchUi.pushView(
        comfortMenu,
        new $.GeneralMenuDelegate(),
        WatchUi.SLIDE_UP
      );
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
      soundMenu.addItem(
        new WatchUi.ToggleMenuItem(
          "Backlight",
          null,
          "alert_backlight",
          boolean,
          null
        )
      );

      WatchUi.pushView(
        soundMenu,
        new $.GeneralMenuDelegate(),
        WatchUi.SLIDE_UP
      );
      return;
    }
    if (id instanceof String && id.equals("demo")) {
      var demoMenu = new WatchUi.Menu2({ :title => "Demo" });

      var mi = new WatchUi.MenuItem(
        "Scenario alert/rain/wind|0~3",
        null,
        "testScenario",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      demoMenu.addItem(mi);

      var boolean = Storage.getValue("weather_condition_loop") ? true : false;
      demoMenu.addItem(
        new WatchUi.ToggleMenuItem(
          "Loop weather condition",
          null,
          "weather_condition_loop",
          boolean,
          null
        )
      );

      WatchUi.pushView(demoMenu, new $.GeneralMenuDelegate(), WatchUi.SLIDE_UP);
      return;
    }

    if (id instanceof String && id.equals("weatherDataSource")) {
      var sp = new selectionMenuPicker("Weather source", id as String);
      for (var i = 0; i < 4; i++) {
        sp.add($.getWeatherDataSourceText(i as WeatherSource), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }

    if (id instanceof String && menuItem instanceof ToggleMenuItem) {
      $.setStorageValueOrArray(id, menuItem.isEnabled());
      return;
    }
  }

  function onSelectedSelection(
    storageKey as String,
    value as Application.PropertyValueType
  ) as Void {
    $.setStorageValueOrArray(storageKey, value);
  }
}

class GeneralMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _item as MenuItem?;
  hidden var _storageKey as String = "";
  hidden var _arrayIndex as Number = -1;

  hidden var _currentPrompt as String = "";

  function initialize() {
    Menu2InputDelegate.initialize();
  }

  function onSelect(menuItem as MenuItem) as Void {
    _item = menuItem;
    var id = menuItem.getId();

    // Extract selected storage key and index
    _storageKey = stringLeft(id.toString(), "|", id.toString());
    var idx = stringRight(id.toString(), "|", "").toNumber();
    if (idx == null) {
      _arrayIndex = -1;
    } else {
      _arrayIndex = idx;
    }

    if (id instanceof String && id.equals("minimalGPSquality")) {
      var sp = new selectionMenuPicker("Minimal GPS", id as String);
      for (var i = 0; i <= 4; i++) {
        sp.add($.getMinimalGPSqualityText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("weatherDataSource")) {
      var sp = new selectionMenuPicker("Weather source", id as String);
      for (var i = 0; i < 4; i++) {
        sp.add($.getWeatherDataSourceText(i as WeatherSource), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }
    if (
      id instanceof String &&
      (id.equals("showWind") ||
        id.equals("show_one_field|9") ||
        id.equals("show_large_field|9") ||
        id.equals("show_wide_field|9") ||
        id.equals("show_small_field|9") ||
        id.equals("alertWindIn"))
    ) {
      var sp = new selectionMenuPicker("Wind display", id as String);
      for (var i = 0; i < $.SHOW_WIND_COUNT; i++) {
        sp.add($.getShowWindText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }

    if (
      id instanceof String &&
      (id.equals("show_one_field|17") ||
        id.equals("show_large_field|17") ||
        id.equals("show_wide_field|17") ||
        id.equals("show_small_field|17"))
    ) {
      var sp = new selectionMenuPicker("Extra information", id as String);
      for (var i = 0; i <= 5; i++) {
        sp.add($.getShowInfoText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }

    if (id instanceof String && id.equals("showInfoOneField")) {
      var sp = new selectionMenuPicker("One page field", id as String);
      for (var i = 0; i <= 5; i++) {
        sp.add($.getShowInfoText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("showInfoLargeField")) {
      var sp = new selectionMenuPicker("Large field", id as String);
      for (var i = 0; i <= 5; i++) {
        sp.add($.getShowInfoText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("showInfoWideField")) {
      var sp = new selectionMenuPicker("Wide field", id as String);
      for (var i = 0; i <= 5; i++) {
        sp.add($.getShowInfoText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("showInfoSmallField")) {
      var sp = new selectionMenuPicker("Small field", id as String);
      for (var i = 0; i <= 5; i++) {
        sp.add($.getShowInfoText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("alertLevelWindGust")) {
      var sp = new selectionMenuPicker("Wind gust level", id as String);
      for (var i = 0; i <= 3; i++) {
        sp.add($.getGustLevelText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("sound_mode")) {
      var sp = new selectionMenuPicker("Sound level", id as String);
      for (var i = 0; i <= 3; i++) {
        sp.add($.getSoundModeText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }
    if (id instanceof String && _item instanceof ToggleMenuItem) {
      $.setStorageValueOrArray(id, _item.isEnabled());
      return;
    }

    // Numeric input
    var prompt = _item.getLabel();
    // System.println(["Numeric input:", prompt]);
    var value = $.getStorageValue(id as String, 0) as Numeric;
    var view = $.getNumericInputView(prompt, value);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(
      view,
      new $.NumericInputDelegate(view),
      WatchUi.SLIDE_RIGHT
    );
  }

  function onAcceptNumericinput(value as Numeric, subLabel as String) as Void {
    try {
      if (_item != null) {
        // Note contains `storageKey|index` or `storageKey`
        var key = _item.getId() as String;
        $.setStorageValueOrArray(key, value);
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

    Toybox.WatchUi.pushView(
      view,
      new $.NumericInputDelegate(view),
      WatchUi.SLIDE_IMMEDIATE
    );
  }

  //! Handle the back key being pressed

  function onBack() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  //! Handle the done item being selected

  function onDone() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  function onSelectedSelection(
    storageKey as String,
    value as Application.PropertyValueType
  ) as Void {
    $.setStorageValueOrArray(storageKey, value);
  }
}

function addMenuItem(
  menu as WatchUi.Menu2,
  label as String,
  subLabel as String,
  id as String
) {
  var mi = new WatchUi.MenuItem(label, subLabel, id, null);
  menu.addItem(mi);
}

function addToggleMenuItem(
  menu as WatchUi.Menu2,
  label as String,
  subLabel as String?,
  id as String,
  enabled as Boolean
) {
  var tmi = new WatchUi.ToggleMenuItem(label, subLabel, id, enabled, null);
  menu.addItem(tmi);
}

function getKeyAndIndex(key as String, index as Number) as String {
  return Lang.format("$1$|$2$", [key, index.toString()]);
}
