import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Math;
import Toybox.Time.Gregorian;

typedef Polygon as Lang.Array<Point2D>;

class RenderWeather {
  hidden var ds as DisplaySettings = new DisplaySettings();
  hidden var ef as EdgeField = EfLarge; // TODO refactor
  hidden const TOP_ADDITIONAL_INFO = 1;
  hidden var topAdditionalInfo2 as Lang.Number = 0;

  hidden var yHumTop as Lang.Number = 0;
  hidden var yHumBottom as Lang.Number = 0;
  hidden var yTempTop as Lang.Number = 0;
  hidden var yTempBottom as Lang.Number = 0;

  hidden const NO_BEARING_SPEED = 0.3;
  hidden const COLOR_TEXT_ALERT = Graphics.COLOR_ORANGE;

  // humidity is already percentage
  hidden var minTemperature as Lang.Number = 0; // celcius
  hidden var maxTemperature as Lang.Number = 50; // celcius
  hidden var maxPressure as Lang.Number = 1080;
  hidden var minPressure as Lang.Number = 870;

  function initialize() {}

  function initValues(
    dc as Dc,
    ds as DisplaySettings,
    ef as EdgeField
  ) as Void {
    self.ds = ds;
    self.ef = ef;
    topAdditionalInfo2 = dc.getFontHeight(ds.fontSmall);

    self.minTemperature = $._minTemperature;
    self.maxTemperature = $._maxTemperature;
    self.maxPressure = $._maxPressure;
    self.minPressure = $._minPressure;
    initComfortZones();
    Math.srand(System.getTimer());
  }

  hidden function initComfortZones() as Void {
    var comfort = getComfort();
    self.yHumTop = ds.getYpostion(comfort.humidityMax);
    self.yHumBottom = ds.getYpostion(comfort.humidityMin);
    var perc = $.percentageOf(
      comfort.temperatureMax,
      self.minTemperature,
      self.maxTemperature
    ).toNumber();
    self.yTempTop = ds.getYpostion(perc);
    perc = $.percentageOf(
      comfort.temperatureMin,
      self.minTemperature,
      self.maxTemperature
    ).toNumber();
    self.yTempBottom = ds.getYpostion(perc);
  }

  function drawUvIndexItem(
    dc as Dc,
    x as Number,
    uvi as Float,
    maxUvIndex as Lang.Number,
    showDetails as Lang.Boolean,
    blueBarPercentage as Number
  ) as Void {
    var perc = $.percentageOf(uvi, 0, maxUvIndex).toNumber();
    // System.println(["uvindex", uvi, maxUvIndex, perc, "<", $._percHideDetails]);

    var y = ds.getYpostion(perc);
    var r = $.uviToRadius(uvi);
    var color = $.uviToColor(uvi);
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    if (showDetails && perc > $._percHideDetails) {
      var h = dc.getFontHeight(Graphics.FONT_TINY);
      dc.drawText(
        x,
        y + (h / 2).toNumber(),
        Graphics.FONT_TINY,
        uvi.format("%.1f"),
        Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
      );
    }
    dc.fillCircle(x, y, r);
    var rh = ((r + 2) / 2).toNumber();
    dc.drawLine(x - r - rh, y - r - rh, x + r + rh, y + r + rh);
    dc.drawLine(x + r + rh, y - r - rh, x - r - rh, y + r + rh);
  }

  function draw0TemperatureLine(dc, x, m0TemperatureLineYpos) as Void {
    dc.setColor(ds.COLOR_0_TEMPERATURE, Graphics.COLOR_TRANSPARENT);
    //dc.setPenWidth(2.0);
    dc.drawLine(
      x - ds.columnWidth,
      m0TemperatureLineYpos,
      x + ds.columnWidth,
      m0TemperatureLineYpos
    );
    //dc.setPenWidth(1.0);
  }

  function drawTemperatureItem(
    dc as Dc,
    x as Number,
    temperature as Numeric,
    showDetails as Lang.Boolean,
    blueBarPercentage as Number
  ) as Void {
    try {
      var devSettings = System.getDeviceSettings();

      var perc = $.percentageOf(
        temperature,
        self.minTemperature,
        self.maxTemperature
      ).toNumber();
      var y = ds.getYpostion(perc);

      if (showDetails && perc > $._percHideDetails) {
        var yBlueBar = ds.getYpostion(blueBarPercentage);
        var h = dc.getFontHeight(Graphics.FONT_TINY);
        if (yBlueBar < y) {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
          dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        }
        var convertedTemperature = temperature;
        if (devSettings.temperatureUnits == System.UNIT_STATUTE) {
          convertedTemperature = $.celciusToFarenheit(temperature);
        }
        dc.drawText(
          x,
          (y - h / 2).toNumber(),
          Graphics.FONT_TINY,
          convertedTemperature.format("%d"),
          Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
        );
      }

      dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
      dc.drawRectangle(x - (ds.columnWidth / 2).toNumber(), y, ds.columnWidth, 1);

      dc.drawRectangle(x - 1, y - 6, 3, 8);
      dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
      dc.drawLine(x, y, x, y - 4);
      dc.fillCircle(x, y + 2, 2);
    } catch (ex) {
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  function drawDewpointItem(
    dc as Dc,
    x as Number,
    dewPoint as Numeric,
    showDetails as Lang.Boolean,
    blueBarPercentage as Number,
    darkBackground as Boolean
  ) as Void {
    try {
      var devSettings = System.getDeviceSettings();

      var perc = $.percentageOf(
        dewPoint,
        self.minTemperature,
        self.maxTemperature
      ).toNumber();
      var y = ds.getYpostion(perc);
      var r = 3;
      var color = dewpointToColor(y, darkBackground);

      if (showDetails && perc > $._percHideDetails) {
        var h = dc.getFontHeight(Graphics.FONT_TINY);
        dc.setColor(ds.COLOR_DEWPOINT_DETAILS, Graphics.COLOR_TRANSPARENT);
        var convertedDewpoint = dewPoint;
        if (devSettings.temperatureUnits == System.UNIT_STATUTE) {
          convertedDewpoint = $.celciusToFarenheit(dewPoint);
        }
        dc.drawText(
          x,
          (y + (h / 2).toNumber() + 1).toNumber(),
          Graphics.FONT_TINY,
          convertedDewpoint.format("%d"),
          Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
        );
      }

      dc.setColor(color, Graphics.COLOR_TRANSPARENT);
      dc.fillCircle(x, y + r - 1, 2);

      dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
      dc.drawRectangle(x - (ds.columnWidth / 2).toNumber(), y, ds.columnWidth, 1);
      dc.drawLine(x - r, y, x, y - 5);
      dc.drawLine(x, y - 5, x + r, y);
      dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, 0, 180);
    } catch (ex) {
      System.println("Error draw dewpoint: " + ex.getErrorMessage());
      ex.printStackTrace();
    }
  }

  function drawPressureItem(
    dc as Dc,
    x as Number,
    pressure as Number,
    showDetails as Boolean,
    bluebarPerc as Number
  ) as Void {
    if (pressure == 0) {
      return;
    }

    var perc = $.percentageOf(
      pressure,
      self.minPressure,
      self.maxPressure
    ).toNumber();
    var y = ds.getYpostion(perc).toNumber();

    // System.println(["drawPressureItem", perc, x, y, pressure]);

    if (showDetails) {
      var yBlueBar = ds.getYpostion(bluebarPerc).toNumber();
      var h = dc.getFontHeight(Graphics.FONT_TINY);
      if (yBlueBar < y - h) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      } else {
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
      }
      dc.drawText(
        x,
        y - (h / 2).toNumber(),
        Graphics.FONT_XTINY,
        pressure.format("%d"),
        Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
      );
    }

    dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
    dc.drawRectangle(x - (ds.columnWidth / 2).toNumber(), y, ds.columnWidth, 1);
    var pts = [
      [x - 3, y],
      [x, y + 5],
      [x + 3, y],
    ];
    dc.fillPolygon(pts as Polygon);
  }

  function drawHumidityItem(
    dc as Dc,
    x as Number,
    humidity as Number,
    showDetails as Lang.Boolean,
    blueBarPercentage as Number
  ) as Void {
    var perc = humidity.toNumber();
    var y = ds.getYpostion(perc); // value is percentage
    var r = 3;

    if (showDetails && perc > $._percHideDetails) {
      var h = dc.getFontHeight(Graphics.FONT_TINY);
      dc.setColor(ds.COLOR_HUMIDITY_DETAILS, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        x,
        y - (h / 2).toNumber(),
        Graphics.FONT_TINY,
        humidity.format("%d"),
        Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_CENTER
      );
    }

    dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
    dc.drawRectangle(x - (ds.columnWidth / 2).toNumber(), y, ds.columnWidth, 2);

    dc.setColor(ds.COLOR_HUMIDITY, Graphics.COLOR_TRANSPARENT);
    var pts = [
      [x - r, y],
      [x, y - 5],
      [x + r, y],
    ];
    dc.fillPolygon(pts as Polygon);
    dc.setPenWidth(r);
    dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, 0, 180);
    dc.setPenWidth(1.0);
  }

  // top is max (temp/humid), low is min(temp/humid)
  function drawComfortColumn(
    dc as Dc,
    x as Lang.Number,
    dewpoint as Lang.Float?,
    darkBackground as Boolean,
    hour as Number
  ) as Void {
    if (dewpoint == null) {
      return;
    }
    var comfort = getComfort();
    var color = $.dewpointToColor(dewpoint.toNumber(), darkBackground);
    dc.setColor(color, color);
    if (ef == EfSmall) {
      var percTemperature = $.percentageOf(
        comfort.temperatureMax,
        self.minTemperature,
        self.maxTemperature
      ).toNumber();
      var yTop = ds.getYpostion(
        $.max(percTemperature, comfort.humidityMax) as Lang.Number
      );
      percTemperature = $.percentageOf(
        comfort.temperatureMin,
        self.minTemperature,
        self.maxTemperature
      ).toNumber();
      var yBottom = ds.getYpostion(
        $.min(percTemperature, comfort.humidityMin) as Lang.Number
      );
      var height = yBottom - yTop;
      dc.fillRectangle(
        (x - (ds.space / 2).toNumber()),
        yTop,
        ds.columnWidth + ds.space,
        height
      );
      return;
    }

    dc.fillRectangle(
      x - (ds.space / 2).toNumber(),
      self.yHumTop,
      ds.columnWidth + ds.space,
      self.yHumBottom - self.yHumTop
    );
    dc.fillRectangle(
      x - (ds.space / 2).toNumber(),
      self.yTempTop,
      ds.columnWidth + ds.space,
      self.yTempBottom - self.yTempTop
    );

    // Draw current observation hour in comfort region
    // TODO menu + not draw last values ??
    // System.println(["hour", hour]);
    if (hour > -1) {
      var hourText = hour.format("%d");
      var nr = dewpoint.toNumber() - 4;
      if (nr < 0) {
        nr = 0;
      }
      color = $.dewpointToColor(nr, darkBackground);
      var fontHours = $.getMatchingFont(
        dc,
        ds.alertFonts,
        (ds.columnWidth / 2).toNumber(),
        hourText,
        -1
      );
      var yHours = self.yTempTop + ((self.yTempBottom - self.yTempTop) / 2).toNumber();
      // System.println(["hour", hour, hourText, nr, yHours, x]);
      dc.setColor(color, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        x + (ds.columnWidth / 2).toNumber(),
        yHours,
        fontHours,
        hourText,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
  }

  function drawComfortBorders(dc as Dc) as Void {
    var size = (dc.getWidth() / 40).toNumber();
    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
    dashedLine(dc, 0, ds.width, self.yHumTop, size);
    dashedLine(dc, 0, ds.width, self.yHumBottom, size);

    dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
    dashedLine(dc, 0, ds.width, self.yTempTop, size);
    dashedLine(dc, 0, ds.width, self.yTempBottom, size);
  }

  function drawObservationLocation(dc as Dc, name as Lang.String?) as Void {
    if (name == null || (name as String).length() == 0) {
      return;
    }
    dc.setColor(ds.COLOR_TEXT_ADDITIONAL, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      ds.margin,
      TOP_ADDITIONAL_INFO,
      ds.fontSmall,
      name,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  function drawObservationLocationLine2(
    dc as Dc,
    name as Lang.String?
  ) as Void {
    if (name == null || (name as String).length() == 0) {
      return;
    }
    dc.setColor(ds.COLOR_TEXT_ADDITIONAL2, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      ds.margin,
      topAdditionalInfo2,
      ds.fontSmall,
      name,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  function drawObservationTime(
    dc as Dc,
    observationTime as Time.Moment?
  ) as Void {
    if (observationTime == null) {
      return;
    }

    var observationTimeString = $.getShortTimeString(observationTime);

    var color = ds.COLOR_TEXT_ADDITIONAL;
    if (
      $.isDelayedFor(observationTime, $._observationTimeDelayedMinutesThreshold)
    ) {
      color = Graphics.COLOR_RED;
    }
    var textW = dc.getTextWidthInPixels(observationTimeString, ds.fontSmall);
    var textX = ds.width - textW - ds.margin;

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      textX,
      TOP_ADDITIONAL_INFO,
      ds.fontSmall,
      observationTimeString,
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  function drawAlertMessages(
    dc as Dc,
    activeAlerts as Lang.String?,
    onSecondLine as Boolean
  ) as Void {
    if (activeAlerts == null || (activeAlerts as Lang.String).length() <= 0) {
      return;
    }

    // Alert always visible
    dc.setColor(COLOR_TEXT_ALERT, ds.COLOR_BACKGROUND);
    var y = TOP_ADDITIONAL_INFO;
    if (onSecondLine) {
      y = topAdditionalInfo2;
    }
    dc.drawText(
      (ds.width / 2).toNumber(),
      y,
      ds.fontSmall,
      activeAlerts,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }

  function drawAlertMessagesVert(
    dc as Dc,
    activeAlerts as Array<String>
  ) as Void {
    var max = activeAlerts.size();
    if (max == 0) {
      return;
    }

    var h = dc.getFontHeight(ds.fontSmall) - 4;
    var y = TOP_ADDITIONAL_INFO;
    dc.setColor(COLOR_TEXT_ALERT, Graphics.COLOR_TRANSPARENT);
    for (var idx = 0; idx < max; idx += 1) {
      var aa = activeAlerts[idx] as String;
      y = y + h;

      var textW = dc.getTextWidthInPixels(aa, ds.fontSmall);
      var textX = ds.width - textW - ds.margin;

      dc.drawText(textX, y, ds.fontSmall, aa, Graphics.TEXT_JUSTIFY_LEFT);
    }
  }

  function drawWeatherConditionText(
    dc as Dc,
    x as Lang.Number,
    condition as Lang.Number,
    yLine as Lang.Number
  ) as Void {
    var text = getWeatherConditionText(condition);
    if (text != null) {
      //var yOffset = yLine == null ? 0 : yLine * ds.heightWt;
      var yOffset = 0;
      if (yLine == 0) {
        yOffset = (yLine * ds.heightWt) as Number;
      }
      dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        x,
        ds.columnY + ds.columnHeight + ds.heightWind + ds.heightWc + yOffset,
        Graphics.FONT_SYSTEM_XTINY,
        text as String,
        Graphics.TEXT_JUSTIFY_LEFT
      );
    }
  }

  function drawSunsetIndication(dc as Dc, x as Lang.Number) as Void {
    if (ef != EfOne) {
      // @@TODO should be from settings
      return;
    }
    var yOffset = ds.heightWt;
    drawMoon(
      dc,
      x + (ds.columnWidth / 2).toNumber(),
      ds.columnY + ds.columnHeight + ds.heightWind + ds.heightWc + yOffset,
      (ds.columnWidth / 5).toNumber(),
      Graphics.COLOR_BLACK,
      Graphics.COLOR_ORANGE
    );
  }

  function getThemeColor(darkBackground) as Dictionary<String, ColorType> {
    return {
      :border => darkBackground ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK,
      :main => darkBackground ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_LT_GRAY,
      :strong => darkBackground ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY,
      :accent => darkBackground ? Graphics.COLOR_YELLOW : Graphics.COLOR_ORANGE,
      :water => darkBackground ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_BLUE,
      :haze => darkBackground ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY,
      :danger => darkBackground ? Graphics.COLOR_PINK : Graphics.COLOR_PURPLE,
    };
  }

  function drawWeatherCondition(
    dc as Dc,
    xPos as Lang.Number,
    condition as Lang.Number?,
    nightTime as Lang.Boolean,
    darkBackground as Lang.Boolean
  ) as Void {
    if (condition == null) {
      return;
    }

    // Center of bar
    var x = xPos + (ds.columnWidth / 2).toNumber();
    // 2px Below bar
    var y = ds.columnY + ds.columnHeight + ds.heightWind + (ds.heightWc / 2).toNumber() + 2;
    // var iconWidth = (ds.columnWidth / 2.5).toNumber();
    // var cloudWidthSmall = ds.columnWidth / 4;
    var cloudWidth = (ds.columnWidth / 2.5).toNumber();
    var cloudWidthLarge = (ds.columnWidth / 2).toNumber();

    var rainWidth = (ds.columnWidth / 2.5).toNumber();
    var rainWidthLarge = (ds.columnWidth / 2).toNumber();
    var rainHeight = (ds.heightWc / 2).toNumber();
    var rainHeightLarge = (ds.heightWc / 1.5).toNumber();

    var widthSnowFlake = (ds.columnWidth / 4).toNumber();
    var widthSnowFlakeLarge = (ds.columnWidth / 3).toNumber();
    var widthLightning = (ds.columnWidth / 4).toNumber();
    var widthLightningLarge = (ds.columnWidth / 3).toNumber();

    var windWidth = (ds.columnWidth / 3).toNumber();
    var dustWidth = (ds.columnWidth / 3).toNumber();
    var dustWidthLarge = (ds.columnWidth / 2).toNumber();

    var colors = getThemeColor(darkBackground);
    var border = colors[:border];

    // condition = Weather.CONDITION_HURRICANE;
    // System.println([
    //   "drawWeatherCondition",
    //   getWeatherConditionText(condition),
    //   condition,
    // ]);

    // clear
    if (condition == Weather.CONDITION_FAIR) {
      drawConditionClear(
        dc,
        x,
        y,
        cloudWidth,
        60,
        nightTime,
        border,
        colors[:accent]
      );
      return;
    }

    if (condition == Weather.CONDITION_PARTLY_CLEAR) {
      drawConditionClear(
        dc,
        x + 3,
        y - 2,
        cloudWidth,
        60,
        nightTime,
        border,
        colors[:accent]
      );
      drawClouds(dc, x, y, cloudWidth, border, colors[:main]);
      return;
    }

    if (condition == Weather.CONDITION_MOSTLY_CLEAR) {
      drawConditionClear(
        dc,
        x + 3,
        y - 2,
        cloudWidth,
        30,
        nightTime,
        border,
        colors[:accent]
      );
      drawClouds(dc, x, y + 3, cloudWidth, border, colors[:main]);
      return;
    }
    if (condition == Weather.CONDITION_CLEAR) {
      drawConditionClear(
        dc,
        x,
        y,
        cloudWidthLarge,
        30,
        nightTime,
        border,
        colors[:accent]
      );
      return;
    }
    // clouds
    if (condition == Weather.CONDITION_PARTLY_CLOUDY) {
      drawConditionClear(
        dc,
        x + 3,
        y - 3,
        cloudWidth,
        60,
        nightTime,
        border,
        colors[:accent]
      );
      drawClouds(dc, x, y, cloudWidth, border, colors[:main]);
      return;
    }
    if (condition == Weather.CONDITION_THIN_CLOUDS) {
      drawClouds(dc, x, y, cloudWidth, border, colors[:main]);
      return;
    }
    if (condition == Weather.CONDITION_MOSTLY_CLOUDY) {
      drawClouds(dc, x, y, cloudWidth, border, colors[:main]);
      return;
    }
    if (condition == Weather.CONDITION_CLOUDY) {
      drawClouds(dc, x, y, cloudWidthLarge, border, colors[:strong]);
      return;
    }
    // rain
    if (
      condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN ||
      condition == Weather.CONDITION_CHANCE_OF_SHOWERS
    ) {
      drawRainDrops(dc, x, y, rainWidth, rainHeight, colors[:water]);
      drawClouds(dc, x, y, cloudWidth, border, colors[:main]);
    }

    if (condition == Weather.CONDITION_DRIZZLE) {
      drawRainDrops(dc, x, y, rainWidth, rainHeight, colors[:water]);
    }

    if (
      condition == Weather.CONDITION_LIGHT_RAIN ||
      condition == Weather.CONDITION_LIGHT_SHOWERS ||
      condition == Weather.CONDITION_SCATTERED_SHOWERS
    ) {
      drawRainDrops(dc, x, y, rainWidth, rainHeight, colors[:water]);
      drawClouds(dc, x, y, cloudWidth, border, colors[:main]);
      return;
    }

    if (
      condition == Weather.CONDITION_RAIN ||
      condition == Weather.CONDITION_SHOWERS
    ) {
      drawRainDrops(dc, x, y, rainWidthLarge, rainHeightLarge, colors[:water]);
      drawClouds(dc, x, y, cloudWidthLarge, border, colors[:strong]);
      return;
    }

    if (
      condition == Weather.CONDITION_HEAVY_SHOWERS ||
      condition == Weather.CONDITION_HEAVY_RAIN
    ) {
      drawRainDrops(dc, x, y, rainWidthLarge, rainHeightLarge, colors[:water]);
      drawClouds(dc, x, y, cloudWidthLarge, border, colors[:water]);
      return;
    }

    if (condition == Weather.CONDITION_FREEZING_RAIN) {
      drawRainDrops(dc, x, y, rainWidthLarge, rainHeightLarge, colors[:haze]);
      drawClouds(dc, x, y, cloudWidthLarge, border, colors[:water]);
      return;
    }

    // hail
    if (condition == Weather.CONDITION_HAIL) {
      drawRainDrops(dc, x, y, rainWidthLarge, rainHeightLarge, colors[:haze]);
      return;
    }

    if (
      condition == Weather.CONDITION_WINTRY_MIX ||
      condition == Weather.CONDITION_RAIN_SNOW
    ) {
      drawSnowFlake(dc, x - 4, y, widthSnowFlake, colors[:haze]);
      drawRainDrops(
        dc,
        x + 4,
        y,
        rainWidthLarge,
        rainHeightLarge,
        colors[:haze]
      );
      return;
    }

    if (
      condition == Weather.CONDITION_CHANCE_OF_RAIN_SNOW ||
      condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW ||
      condition == Weather.CONDITION_LIGHT_RAIN_SNOW
    ) {
      drawSnowFlake(dc, x - 4, y, widthSnowFlake, colors[:main]);
      drawRainDrops(
        dc,
        x + 4,
        y,
        rainWidthLarge,
        rainHeightLarge,
        colors[:main]
      );
      return;
    }

    // snow
    if (condition == Weather.CONDITION_CHANCE_OF_SNOW) {
      drawSnowFlake(dc, x, y, widthSnowFlake, colors[:main]);
      return;
    }

    if (condition == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW) {
      drawSnowFlake(dc, x, y + 2, widthSnowFlake, colors[:main]);
      drawClouds(dc, x, y, cloudWidth, border, colors[:main]);
      return;
    }

    if (
      condition == Weather.CONDITION_FLURRIES ||
      condition == Weather.CONDITION_LIGHT_SNOW
    ) {
      drawSnowFlake(dc, x, y, widthSnowFlake, colors[:main]);
      return;
    }

    if (condition == Weather.CONDITION_SNOW) {
      drawSnowFlake(dc, x, y, widthSnowFlakeLarge, colors[:haze]);
      return;
    }

    if (
      condition == Weather.CONDITION_SLEET ||
      condition == Weather.CONDITION_ICE_SNOW ||
      condition == Weather.CONDITION_ICE
    ) {
      drawHailStone(dc, x, y, 4, colors[:water]);
      drawSnowFlake(dc, x, y, widthSnowFlake, colors[:water]);
      return;
    }

    if (
      condition == Weather.CONDITION_HEAVY_SNOW ||
      condition == Weather.CONDITION_HEAVY_RAIN_SNOW
    ) {
      drawSnowFlake(dc, x - 4, 2, widthSnowFlake, colors[:water]);
      drawSnowFlake(dc, x + 4, y - 3, widthSnowFlakeLarge, colors[:water]);
      return;
    }

    // thunder
    if (condition == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS) {
      drawLightning(dc, x, y, widthLightning, colors[:accent]);
      return;
    }

    if (condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS) {
      drawLightning(dc, x, y, widthLightning, colors[:accent]);
      return;
    }

    if (condition == Weather.CONDITION_THUNDERSTORMS) {
      drawLightning(dc, x - 4, y - 2, widthLightning, colors[:accent]);
      drawLightning(dc, x + 2, y, widthLightningLarge, colors[:danger]);
      return;
    }

    if (condition == Weather.CONDITION_TROPICAL_STORM) {
      drawLightning(dc, x - 1, y + 1, widthLightningLarge, colors[:accent]);
      drawLightning(dc, x + 4, y + 4, widthLightning, colors[:danger]);
      drawClouds(dc, x, y, cloudWidthLarge, border, colors[:strong]);
      return;
    }

    // windy
    if (condition == Weather.CONDITION_WINDY) {
      drawWind(dc, x, y, windWidth, colors[:strong]);
      return;
    }
    // sudden windspeed
    if (condition == Weather.CONDITION_SQUALL) {
      drawWind(dc, x, y, windWidth, colors[:accent]);
      return;
    }

    // dust
    if (
      condition == Weather.CONDITION_DUST ||
      condition == Weather.CONDITION_SAND
    ) {
      drawDust(dc, x, y, dustWidth, 6, colors[:main]);
      return;
    }
    // dust, difficult to see
    if (
      condition == Weather.CONDITION_HAZY ||
      condition == Weather.CONDITION_HAZE
    ) {
      drawFog(dc, x, y, dustWidth, colors[:main]);
      drawDust(dc, x, y, dustWidth, 8, colors[:main]);
      return;
    }

    // sandstorm
    if (condition == Weather.CONDITION_SANDSTORM) {
      drawWind(dc, x, y, windWidth, colors[:strong]);
      drawDust(dc, x, y, dustWidthLarge, 8, colors[:main]);
      drawLightning(dc, x, y, widthLightning, colors[:accent]);
      return;
    }

    // ash
    if (condition == Weather.CONDITION_VOLCANIC_ASH) {
      drawVolcano(dc, x, y, dustWidthLarge, colors[:strong]);
      drawDust(dc, x, y, dustWidthLarge, 10, colors[:accent]);
      return;
    }

    // hurricane
    if (
      condition == Weather.CONDITION_HURRICANE ||
      condition == Weather.CONDITION_TORNADO
    ) {
      drawClouds(dc, x, y, cloudWidthLarge, border, colors[:main]);
      drawTornado(dc, x, y, dustWidthLarge, colors[:strong]);
      return;
    }

    // smoke
    if (condition == Weather.CONDITION_SMOKE) {
      drawClouds(dc, x, y, cloudWidthLarge, border, colors[:main]);
      drawDust(dc, x, y, dustWidth, 3, colors[:strong]);
      return;
    }

    // fog
    if (
      condition == Weather.CONDITION_FOG ||
      condition == Weather.CONDITION_MIST
    ) {
      drawFog(dc, x, y, dustWidthLarge, colors[:strong]);
      return;
    }

    // unknown
    if (
      condition == Weather.CONDITION_UNKNOWN_PRECIPITATION ||
      condition == Weather.CONDITION_UNKNOWN
    ) {
      dc.setColor(colors[:main], Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        x,
        y,
        Graphics.FONT_XTINY,
        "?",
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
      return;
    }

    return;
  }

  hidden function drawTornado(
    dc as Dc,
    x as Number, // Center X
    y as Number, // Top Y
    width as Number,
    color as ColorType
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    // We draw 5-6 lines that decrease in width
    var segments = 6;
    var gap = (width / segments).toNumber();

    for (var i = 0; i < segments; i++) {
      // Line gets narrower as i increases
      var lineWidth = (width - i * (width / (segments + 1))).toNumber();

      // Offset creates a "sway" or "twist" effect
      var xOffset = (i % 2).toNumber() == 0 ? 2 : -2;

      var yPos = y + i * gap;
      var xStart = x - (lineWidth / 2).toNumber() + xOffset;
      var xEnd = x + (lineWidth / 2).toNumber() + xOffset;

      // Make the top lines thicker than the bottom point
      dc.setPenWidth(segments - i);
      dc.drawLine(xStart, yPos, xEnd, yPos);
    }

    // Reset pen width for other functions
    dc.setPenWidth(1);
  }

  hidden function drawVolcano(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    color as ColorType
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    var halfW = (width / 2).toNumber();
    var topW = (width * 0.2).toNumber(); // Width of the crater
    var height = width;

    // Define the points for a volcano with a small crater dip
    var pts = [
      [x - topW, y], // Left rim of crater
      [x, y + 2], // Center dip of crater
      [x + topW, y], // Right rim of crater
      [x + halfW, y + height], // Bottom right base
      [x - halfW, y + height], // Bottom left base
    ];

    dc.fillPolygon(pts);

    // Add a little "Ash" cloud above it
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.fillCircle(x, y - 5, (topW * 0.8).toNumber());
    dc.fillCircle(x + 4, y - 8, (topW * 0.6).toNumber());
  }

  hidden function drawDust(
    dc as Dc,
    x as Number, // Center X
    y as Number, // Center Y
    width as Number, // Total span of the dust cloud
    particles as Number,
    color as ColorType
  ) as Void {
    if (width <= 0) {
      return;
    }

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    var half = (width / 2).toNumber();

    for (var i = 0; i < particles; i++) {
      // Randomize position within the [-half, +half] range relative to x,y
      var randomXOffset = (Math.rand() % width).toNumber();
      var randomYOffset = (Math.rand() % width).toNumber();

      var xD = x - half + randomXOffset;
      var yD = y - half + randomYOffset;

      // Vary the size slightly so it's not a grid of identical dots
      // Size will be between 1 and 2 pixels
      var size = (Math.rand() % 2).toNumber() + 1;

      dc.fillCircle(xD, yD, size);
    }
  }

  hidden function drawWind(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    color as ColorType
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.setPenWidth(1);

    // Define three tiers of wind lines
    // Line 1: Top (Short with curl)
    drawWindPath(dc, x - width * 0.4, y - width * 0.2, width * 0.6, true);

    // Line 2: Middle (Longest with curl)
    drawWindPath(dc, x - width * 0.5, y, width, true);

    // Line 3: Bottom (Short with curl)
    drawWindPath(dc, x - width * 0.4, y + width * 0.2, width * 0.5, false);
  }

  // Helper to draw a line that ends in a curl
  hidden function drawWindPath(dc, x, y, len, curlUp) {
    var radius = 3;
    // Draw the straight part
    dc.drawLine(x, y, x + len, y);

    // Draw the swirl at the end
    if (curlUp) {
      dc.drawArc(
        x + len,
        y - radius,
        radius,
        Graphics.ARC_COUNTER_CLOCKWISE,
        180,
        0
      );
    } else {
      dc.drawArc(x + len, y + radius, radius, Graphics.ARC_CLOCKWISE, 180, 0);
    }
  }

  hidden function drawFog(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    color as ColorType
  ) as Void {
    dc.setPenWidth(2);
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    // We draw 3-4 horizontal lines, staggered
    // Line 1: Top (Slightly offset right)
    var y1 = y - (width * 0.2).toNumber();
    dc.drawLine(
      x - (width * 0.3).toNumber(),
      y1,
      x + (width * 0.4).toNumber(),
      y1
    );

    // Line 2: Middle (Centered, longest)
    var y2 = y;
    dc.drawLine(
      x - (width * 0.5).toNumber(),
      y2,
      x + (width * 0.5).toNumber(),
      y2
    );

    // Line 3: Bottom (Slightly offset left)
    var y3 = y + (width * 0.2).toNumber();
    dc.drawLine(
      x - (width * 0.4).toNumber(),
      y3,
      x + (width * 0.2).toNumber(),
      y3
    );
  }

  hidden function drawLightning(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    color as ColorType
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    var h = width; // Let's use width as the total height of the bolt
    var w = (width * 0.5).toNumber(); // The "zig" width

    // Top Segment
    var x1 = x + w;
    var y1 = y;
    var x2 = x - (w * 0.2).toNumber();
    var y2 = y + (h * 0.4).toNumber();
    dc.drawLine(x1, y1, x2, y2);

    // Middle Horizontal-ish Segment (The "Zig")
    var x3 = x2 + w;
    var y3 = y2;
    dc.drawLine(x2, y2, x3, y3);

    // Bottom Segment (The "Zag")
    var x4 = x;
    var y4 = y + h;
    dc.drawLine(x3, y3, x4, y4);
  }

  hidden function drawSnowFlake(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    color as ColorType
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    // Radius is half the total width
    var radius = (width / 2).toNumber();
    var angle = 0;

    // Use a step of 45 degrees for a standard 8-pointed flake
    while (angle < 360) {
      var p1 = point2DOnCircle(x, y, radius, angle);
      dc.drawLine(x, y, p1[0], p1[1]);
      angle += 45;
    }
  }

  // hidden function getHailPoints(
  //   x as Number,
  //   y as Number,
  //   radius as Number
  // ) as Polygon {
  //   var pts = [];

  //   var angle = 0;
  //   while (angle < 360) {
  //     pts.add(point2DOnCircle(x, y, radius, angle));
  //     angle = angle + 60;
  //   }

  //   return pts as Polygon;
  // }

  hidden function drawHail(
    dc as Dc,
    x as Number, // Center of cloud
    y as Number, // Bottom of cloud
    width as Number, // Width of the impact area
    height as Number, // Height of the impact area
    color as ColorType
  ) as Void {
    if (width <= 0 || height <= 0) {
      return;
    }

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    var stoneSize = (width * 0.15).toNumber(); // Small stones
    if (stoneSize < 3) {
      stoneSize = 3;
    } // Safety check

    // Draw 5-7 individual hailstones
    for (var i = 0; i < 6; i++) {
      var randomXOffset = (Math.rand() % width).toNumber();
      var randomYOffset = (Math.rand() % height).toNumber();

      // Randomize position within the width/height box
      var hx = x - (width / 2).toNumber() + randomXOffset;
      var hy = y + randomYOffset;

      drawHailStone(dc, hx, hy, stoneSize, color);
    }
  }
  // hidden function getHailPoints(x, y, width) as Polygon {
  //   var pts = [];
  //   var radius = (width / 2).toNumber();
  //   // 45-degree steps create an octagon, which looks like a rough stone
  //   var angle = 0;
  //   while (angle < 360) {
  //     pts.add(point2DOnCircle(x, y, radius, angle));
  //     angle += 45;
  //   }
  //   return pts as Polygon;
  // }

  hidden function drawHailStone(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    color as ColorType
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var r = (width / 2).toNumber();
    var angle = 0;
    var lastPt = null;
    var firstPt = null;

    while (angle < 360) {
      var pt = point2DOnCircle(x, y, r, angle);
      if (lastPt != null) {
        dc.drawLine(lastPt[0], lastPt[1], pt[0], pt[1]);
      } else {
        firstPt = pt;
      }
      lastPt = pt;
      angle += 60; // Back to 60 for efficiency (6 lines total)
    }
    // Close the shape
    dc.drawLine(lastPt[0], lastPt[1], firstPt[0], firstPt[1]);
  }

  hidden function drawRainDrops(
    dc as Dc,
    x as Number, // Center of the cloud
    y as Number, // Bottom of the cloud
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    // Safety check: If there is no width or height to draw in, just exit
    // modulo (%) 0 is undefined
    if (width <= 0 || height <= 0) {
      return;
    }

    dc.setColor(color, Graphics.COLOR_TRANSPARENT);

    var dropLength = 4;
    var slant = 2; // Gives a slight wind effect

    // We use a fixed seed if you want the rain to stay in one place,
    // or Math.getRandom() for 'animated' flickering rain.
    for (var i = 0; i < 10; i++) {
      // Ensure Math.rand() result is positive and explicitly cast width/height
      //to absolute numbers
      var randomXOffset = (Math.rand() % width).toNumber();
      var randomYOffset = (Math.rand() % height).toNumber();

      // Calculate final coordinates ensuring everything stays an integer
      var rx = x - (width / 2).toNumber() + randomXOffset;
      var ry = y + randomYOffset;

      dc.drawLine(rx, ry, rx - slant, ry + dropLength);
    }    
  }

  hidden function drawMoon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    border as ColorType,
    color as ColorType
  ) as Void {
    // The total width is roughly (radius + (penWidth / 2)).
    // To maintain your original proportions (penWidth = 1.5 * radius):
    // width = radius + 0.75 * radius  => width = 1.75 * radius
    var radius = (width / 1.75).toNumber();
    var penWidth = (radius * 1.5).toNumber();

    // We adjust the x-position slightly so the moon stays centered
    // within the provided width bounds.
    var xAdjusted = x - (width * 0.1).toNumber();

    dc.setPenWidth(3);
    dc.setColor(border, Graphics.COLOR_TRANSPARENT);
    dc.drawArc(xAdjusted, y, radius, Graphics.ARC_COUNTER_CLOCKWISE, 95, 275);

    dc.setPenWidth(penWidth);
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawArc(xAdjusted, y, radius, Graphics.ARC_COUNTER_CLOCKWISE, 95, 275);

    // Reset pen width to default
    dc.setPenWidth(1.0);
  }

  hidden function drawConditionClear(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    increment as Number,
    nightTime as Boolean,
    border as ColorType,
    color as ColorType
  ) as Void {
    if (nightTime) {
      drawMoon(dc, x, y, (width / 2).toNumber(), border, color);
      return;
    }

    // radiusOuter is the boundary of the total width
    var radiusOuter = (width / 2).toNumber();
    // The sun's core is typically 60% of the total width
    var radiusInner = (radiusOuter * 0.6).toNumber();

    // Draw the sun's core
    dc.setPenWidth(3);
    dc.setColor(border, Graphics.COLOR_TRANSPARENT);
    dc.fillCircle(x, y, radiusInner);
    dc.setPenWidth(1);
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.fillCircle(x, y, radiusInner);

    if (increment <= 0) {
      return;
    }

    // Draw the rays
    var angle = 0;
    while (angle < 360) {
      var p1 = point2DOnCircle(x, y, radiusInner, angle);
      var p2 = point2DOnCircle(x, y, radiusOuter, angle);

      dc.drawLine(p1[0], p1[1], p2[0], p2[1]);
      angle = angle + increment;
    }
  }

  // --
  public function drawWindArrow(
    dc as Dc,
    x as Number,
    y as Number,
    wp as WindPoint,
    activityBearing as Number,
    bigArrow as Boolean
  ) as Void {
    // Option to show it relative to activity direction
    var bearingDegrees = wp.bearing - activityBearing;
    var wsFont = Graphics.FONT_XTINY;
    if (bigArrow) {
      wsFont = Graphics.FONT_SMALL;
    }

    var radius = 5;
    var padding = 5;

    var windGustLevel = wp.gustLevel;
    var iconColor = ds.COLOR_WIND_ICON;
    var hasAlert = wp.speedAlert;
    if (hasAlert) {
      iconColor = Graphics.COLOR_RED;
    }
    if (wp.gustAlert) {
      iconColor = Graphics.COLOR_RED;
      hasAlert = true;
    } else if (windGustLevel >= 3) {
      iconColor = Graphics.COLOR_PURPLE;
    } else if (windGustLevel == 2) {
      iconColor = Graphics.COLOR_PINK;
    } else if (windGustLevel == 1) {
      iconColor = 0xe06666; // TODO night mode color
    }
    var text = wp.text;

    if (hasAlert) {
      var circleMaxWidth;
      if (bigArrow) {
        // only 1 windpoint in center of screen
        circleMaxWidth = (dc.getWidth() / 5).toNumber();
      } else {
        // half columnwidth
        circleMaxWidth = (ds.columnWidth - ds.columnWidth / 2).toNumber();
      }
      wsFont = $.getMatchingFont(dc, ds.alertFonts, circleMaxWidth, text, -1);
    }

    // Only get font if bigArrow
    if (bigArrow && hasAlert) {
      // only 1 windpoint in center of screen
      var circleMaxWidth = (dc.getWidth() / 5).toNumber();
      wsFont = $.getMatchingFont(dc, ds.alertFonts, circleMaxWidth, text, -1);
    }
    // Only displaying numbers. They are vertical and horizontal aligned in the circle.
    // But still some space below base line (because of py etc charcters, but numbers are all above baseline)
    // Do a correction, lower the placement some pixels.
    var yOffset = (dc.getFontDescent(wsFont) / 2).toNumber();

    var textWidth = dc.getTextWidthInPixels(text, wsFont);
    radius = (textWidth / 2).toNumber() + padding;

    // Bearing arrow
    if (bearingDegrees != 0 && wp.speed != 0 && wp.speed > NO_BEARING_SPEED) {
      // Correction 0 is horizontal, should be North so -90 degrees
      // Wind comes from x but goes to y (opposite) direction so +160 degrees
      // Total is + 90 degrees
      bearingDegrees = bearingDegrees + 90;
      dc.setColor(iconColor, Graphics.COLOR_TRANSPARENT);

      var pA, pB, pC, pD;
      var gustOuter = 0;
      var gustInner = 0;
      var factor = 0;
      if (bigArrow) {
        factor = (wp.speed / 4.0).toNumber();
        pA = point2DOnCircle(
          x,
          y,
          factor + radius * 2.4,
          bearingDegrees - 35 - 180
        );
        pB = point2DOnCircle(x, y, factor + radius * 1.5, bearingDegrees - 180);
        pC = point2DOnCircle(
          x,
          y,
          factor + radius * 2.4,
          bearingDegrees + 35 - 180
        );
        pD = point2DOnCircle(x, y, factor + radius * 3.0, bearingDegrees);

        gustOuter = 2.6;
        gustInner = 1.8;
      } else {
        pA = point2DOnCircle(x, y, radius * 1.5, bearingDegrees - 35 - 180);
        pB = point2DOnCircle(x, y, radius * 1.0, bearingDegrees - 180);
        pC = point2DOnCircle(x, y, radius * 1.5, bearingDegrees + 35 - 180);
        pD = point2DOnCircle(x, y, radius * 1.9, bearingDegrees);

        gustOuter = 1.6;
        gustInner = 1.2;
      }
      dc.fillPolygon([pA, pB, pC, pD] as Polygon);

      if (windGustLevel >= 1) {
        dc.setColor(ds.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);

        factor = factor + 2;
        pA = point2DOnCircle(
          x,
          y,
          factor + radius * gustOuter,
          bearingDegrees - 30 - 180
        );
        pB = point2DOnCircle(
          x,
          y,
          factor + radius * gustInner,
          bearingDegrees - 180
        );
        pC = point2DOnCircle(
          x,
          y,
          factor + radius * gustOuter,
          bearingDegrees + 30 - 180
        );

        dc.drawLine(pA[0], pA[1], pB[0], pB[1]);
        dc.drawLine(pB[0], pB[1], pC[0], pC[1]);

        //  dc.fillPolygon([pA, pB, pC] as Polygon); this will give stack overflow error
        if (windGustLevel >= 2) {
          factor = factor + 3;
          pA = point2DOnCircle(
            x,
            y,
            factor + radius * gustOuter,
            bearingDegrees - 30 - 180
          );
          pB = point2DOnCircle(
            x,
            y,
            factor + radius * gustInner,
            bearingDegrees - 180
          );
          pC = point2DOnCircle(
            x,
            y,
            factor + radius * gustOuter,
            bearingDegrees + 30 - 180
          );
          dc.drawLine(pA[0], pA[1], pB[0], pB[1]);
          dc.drawLine(pB[0], pB[1], pC[0], pC[1]);
        }
        if (windGustLevel >= 3) {
          factor = factor + 3;
          pA = point2DOnCircle(
            x,
            y,
            factor + radius * gustOuter,
            bearingDegrees - 30 - 180
          );
          pB = point2DOnCircle(
            x,
            y,
            factor + radius * gustInner,
            bearingDegrees - 180
          );
          pC = point2DOnCircle(
            x,
            y,
            factor + radius * gustOuter,
            bearingDegrees + 30 - 180
          );
          dc.drawLine(pA[0], pA[1], pB[0], pB[1]);
          dc.drawLine(pB[0], pB[1], pC[0], pC[1]);
        }
        dc.setPenWidth(1);
      }
    }

    // The circle
    var textColor = Graphics.COLOR_BLACK;
    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawCircle(x, y, radius);
    if (hasAlert && !bigArrow) {
      // https://rgbcolorcode.com/color/FF0080  rgb(255,0,128)
      dc.setColor(0xff0080, Graphics.COLOR_TRANSPARENT);
      textColor = Graphics.COLOR_WHITE;
    } else {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
    dc.fillCircle(x, y, radius - 1);

    // Windspeed
    dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      x,
      y + yOffset,
      wsFont,
      text,
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );
  }

  hidden function point2DOnCircleSlow(
    x as Number,
    y as Number,
    radius as Lang.Numeric,
    angleInDegrees as Lang.Numeric
  ) as Point2D {
    // Convert from degrees to radians
    try {
      var xP = radius * Math.cos((angleInDegrees * Math.PI) / 180) + x;
      var yP = radius * Math.sin((angleInDegrees * Math.PI) / 180) + y;

      return [xP.toNumber(), yP.toNumber()] as Point2D;
    } catch (ex) {
      // Stack overflow error
      System.println(ex.getErrorMessage());
      ex.printStackTrace();
      return [0, 0] as Point2D;
    }
  }

  hidden var SIN_TABLE = [] as Array<Number>;
  hidden var COS_TABLE = [] as Array<Number>;
  hidden function point2DOnCircle(
    x as Number,
    y as Number,
    radius as Lang.Numeric,
    angleInDegrees as Lang.Numeric
  ) as Point2D {
    if (SIN_TABLE.size() == 0) {
      var DEG_TO_RAD = Math.PI / 180;
      var angle = 0;
      while (angle < 360) {
        SIN_TABLE.add(Math.sin(angle * DEG_TO_RAD));
        COS_TABLE.add(Math.cos(angle * DEG_TO_RAD));
        angle = angle + 1;
      }
    }
    var angleInt = (angleInDegrees.toNumber() % 360).toNumber();
    if (angleInt < 0) {
      angleInt = angleInt + 360;
    }
    var xP = radius * COS_TABLE[angleInt] + x;
    var yP = radius * SIN_TABLE[angleInt] + y;

    return [xP.toNumber(), yP.toNumber()] as Point2D;
  }

  hidden function dashedLine(
    dc as Dc,
    x1 as Number,
    x2 as Number,
    y as Number,
    size as Number
  ) as Void {
    var x = x1;
    var space = (size / 3).toNumber();
    while (x <= x2) {
      dc.drawLine(x, y, x + size, y);
      x = x + size + space;
    }
  }

  hidden function drawClouds(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    border as ColorType,
    color as ColorType
  ) as Void {
    var pts = [];
    // Calculate a base radius from width (approx 1/3 of total span)
    var r = (width / 2.8).toNumber();
    var step = 20; // Increased step for efficiency

    // 1. Left Arch (Starts at x - width/2)
    var xLeft = x - (width / 2).toNumber() + (r * 0.3).toNumber();
    for (var d = -180; d <= -90; d += step) {
      pts.add(point2DOnCircle(xLeft, y, r * 0.4, d));
    }

    // 2. Center Arch (Main Body)
    for (var d = -180; d <= 0; d += step) {
      pts.add(point2DOnCircle(x, y, r, d));
    }

    // 3. Right Arch (Ends at x + width/2)
    var xRight = x + (width / 2).toNumber() - (r * 0.6).toNumber();
    for (var d = -90; d <= 0; d += step) {
      pts.add(point2DOnCircle(xRight, y, r * 0.7, d));
    }
    dc.setPenWidth(3);
    dc.setColor(border, Graphics.COLOR_TRANSPARENT);
    dc.fillPolygon(pts as Polygon);
    dc.setPenWidth(1);
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.fillPolygon(pts as Polygon);
  }
}
