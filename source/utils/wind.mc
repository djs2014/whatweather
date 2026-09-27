import Toybox.System;
import Toybox.Math;
import Toybox.Lang;
import Toybox.Activity;

public class Wind {
    // Returns Gust Severity Level: 0 (Safe) to 3 (Hazard)
    // Accepts wind metrics in either km/h or m/s (set unitInKmh = true for km/h)
    public static function calculateOptimalGustLevel(
        windSpeed as Float?,
        windGust as Float?,
        unitInKmh as Boolean
    ) as Number {
        // 1. Guard Nulls & Uninitialized Values
        if (windSpeed == null || windGust == null || windGust <= 0.0f) {
            return 0;
        }

        // 2. Standardize to km/h internally for consistent threshold logic
        var speedKmh = unitInKmh ? windSpeed : windSpeed * 3.6f;
        var gustKmh = unitInKmh ? windGust : windGust * 3.6f;

        // 3. Noise Floor: Ignore gusts when total wind is light (< 12 km/h / ~3.3 m/s)
        if (gustKmh < 12.0f) {
            return 0;
        }

        var gustDelta = gustKmh - speedKmh;

        // 4. Level 3 (Critical Hazard)
        // Absolute gust >= 45 km/h OR sudden delta >= 30 km/h (~8.3 m/s jump)
        if (gustKmh >= 45.0f || gustDelta >= 30.0f) {
            return 3;
        }

        // 5. Level 2 (Moderate Caution / Deep-Rim Warning)
        // Absolute gust >= 32 km/h OR sudden delta >= 20 km/h (~5.5 m/s jump)
        if (gustKmh >= 32.0f || gustDelta >= 20.0f) {
            return 2;
        }

        // 6. Level 1 (Light Alert / Noticeable Twitch)
        // Absolute gust >= 22 km/h OR sudden delta >= 12 km/h (~3.3 m/s jump)
        if (gustKmh >= 22.0f || gustDelta >= 12.0f) {
            return 1;
        }

        return 0;
    }
}
