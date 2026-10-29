package vn.thoxay.config;

import java.time.Clock;
import java.time.ZoneId;
import org.springframework.context.annotation.*;

@Configuration
public class BusinessClockConfig {
    @Bean Clock businessClock() { return Clock.system(ZoneId.of("Asia/Ho_Chi_Minh")); }
}
