package vn.thoxay.weather;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.validation.annotation.Validated;

@RestController @RequiredArgsConstructor @Validated
public class WeatherController {
    private final WeatherService service;
    @GetMapping("/api/weather")
    public WeatherReport weather(@RequestParam @DecimalMin("-90") @DecimalMax("90") double latitude,
        @RequestParam @DecimalMin("-180") @DecimalMax("180") double longitude) {
        return service.weather(latitude,longitude);
    }
}
