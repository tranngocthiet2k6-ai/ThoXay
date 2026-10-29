package vn.thoxay.weather;
public interface WeatherProvider {
    WeatherReport.Observation fetch(double latitude, double longitude) throws Exception;
}
