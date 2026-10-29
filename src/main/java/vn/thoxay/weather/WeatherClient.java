package vn.thoxay.weather;

import com.fasterxml.jackson.databind.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import java.net.URI;
import java.net.http.*;
import java.time.*;

@Component
public class WeatherClient implements WeatherProvider {
    private final HttpClient http;
    private final ObjectMapper json;
    @Autowired public WeatherClient(ObjectMapper json) {
        this(HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(2)).followRedirects(HttpClient.Redirect.NEVER).build(), json);
    }
    WeatherClient(HttpClient http, ObjectMapper json) { this.http=http; this.json=json; }
    @Override public WeatherReport.Observation fetch(double latitude, double longitude) throws Exception {
        // Fixed HTTPS host, rounded numeric parameters only; never forward the user's JWT or exact GPS.
        var uri=URI.create("https://api.open-meteo.com/v1/forecast?latitude="+latitude+"&longitude="+longitude
            +"&current=temperature_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m"
            +"&temperature_unit=celsius&wind_speed_unit=kmh&precipitation_unit=mm&timeformat=unixtime&timezone=Asia%2FHo_Chi_Minh&forecast_days=1");
        var response=http.send(HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(3)).header("Accept","application/json").GET().build(), HttpResponse.BodyHandlers.ofString());
        if(response.statusCode()!=200 || response.body()==null || response.body().length()>65536) throw new IllegalStateException("Weather unavailable");
        JsonNode current=json.readTree(response.body()).path("current");
        double temperature=number(current,"temperature_2m"), apparent=number(current,"apparent_temperature");
        double rain=number(current,"precipitation"), wind=number(current,"wind_speed_10m");
        if(!current.path("time").isIntegralNumber() || !current.path("time").canConvertToLong() || !current.path("weather_code").isIntegralNumber()
            || !current.path("is_day").isIntegralNumber() || rain<0 || wind<0) throw new IllegalStateException("Invalid weather data");
        int day=current.path("is_day").intValue(); if(day!=0&&day!=1) throw new IllegalStateException("Invalid weather day");
        return new WeatherReport.Observation(temperature,apparent,current.path("weather_code").intValue(),rain,wind,
            day==1,Instant.ofEpochSecond(current.path("time").longValue()));
    }
    private double number(JsonNode node,String field) {
        JsonNode value=node.path(field);
        if(!value.isNumber() || !Double.isFinite(value.doubleValue())) throw new IllegalStateException("Missing weather data");
        return value.doubleValue();
    }
}
