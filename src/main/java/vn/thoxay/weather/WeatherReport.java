package vn.thoxay.weather;
import java.time.Instant;

public record WeatherReport(boolean available, boolean stale, double latitude, double longitude,
    Observation current, Instant fetchedAt, String sourceUrl) {
    public record Observation(double temperature, double apparentTemperature, int weatherCode,
        double precipitation, double windSpeed, boolean isDay, Instant observedAt) { }
}
