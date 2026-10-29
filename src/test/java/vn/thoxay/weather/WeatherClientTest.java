package vn.thoxay.weather;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import java.net.http.*;
import java.time.Duration;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class WeatherClientTest {
    @Test @SuppressWarnings("unchecked") void parsesCurrentWeatherWithBoundedFixedHttpsRequestAndNoAuthHeader() throws Exception {
        HttpClient http=mock(HttpClient.class);HttpResponse<String> response=mock(HttpResponse.class);
        when(http.send(any(HttpRequest.class),org.mockito.ArgumentMatchers.<HttpResponse.BodyHandler<String>>any())).thenReturn(response);
        when(response.statusCode()).thenReturn(200);
        when(response.body()).thenReturn("""
            {"current":{"time":1793260800,"temperature_2m":31.2,"apparent_temperature":36,
            "is_day":1,"precipitation":1.2,"weather_code":97,"wind_speed_10m":12}}
            """);
        var observation=new WeatherClient(http,new ObjectMapper()).fetch(10.76,106.66);
        assertThat(observation.temperature()).isEqualTo(31.2);assertThat(observation.weatherCode()).isEqualTo(97);
        var request=ArgumentCaptor.forClass(HttpRequest.class);verify(http).send(request.capture(),any());
        assertThat(request.getValue().uri().getHost()).isEqualTo("api.open-meteo.com");
        assertThat(request.getValue().uri().getScheme()).isEqualTo("https");
        assertThat(request.getValue().uri().getQuery()).contains("timeformat=unixtime","latitude=10.76","wind_speed_unit=kmh");
        assertThat(request.getValue().headers().firstValue("Authorization")).isEmpty();
        assertThat(request.getValue().timeout()).contains(Duration.ofSeconds(3));
    }
    @Test @SuppressWarnings("unchecked") void missingFieldsAndUpstreamErrorsNeverBecomeFakeZeroDegreeWeather() throws Exception {
        HttpClient http=mock(HttpClient.class);HttpResponse<String> response=mock(HttpResponse.class);
        when(http.send(any(HttpRequest.class),org.mockito.ArgumentMatchers.<HttpResponse.BodyHandler<String>>any())).thenReturn(response);
        var client=new WeatherClient(http,new ObjectMapper());
        when(response.statusCode()).thenReturn(503);assertThatThrownBy(()->client.fetch(10,106)).isInstanceOf(IllegalStateException.class);
        when(response.statusCode()).thenReturn(200);when(response.body()).thenReturn("{\"current\":{}}");
        assertThatThrownBy(()->client.fetch(10,106)).isInstanceOf(IllegalStateException.class);
    }
}
