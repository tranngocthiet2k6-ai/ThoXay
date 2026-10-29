package vn.thoxay;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.weather.*;
import vn.thoxay.entity.*;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.JwtUtil;
import java.time.Instant;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class WeatherApiTest {
 @Autowired MockMvc mvc;
 @Autowired UserRepository users;
 @Autowired JwtUtil jwt;
 @MockitoBean WeatherProvider provider;
 String token(){var user=new User();user.setPhoneNumber("0009888777666");user.setPassword("QA");user.setFullName("Weather QA");user.setRole(Role.ROLE_WORKER);users.saveAndFlush(user);return "Bearer "+jwt.generateToken(user.getPhoneNumber());}
 @Test void requiresJwtAndValidatesCoordinatesBeforeCallingProvider() throws Exception {
  mvc.perform(get("/api/weather").param("latitude","10").param("longitude","106")).andExpect(status().isUnauthorized());
  var token=token();
  for(String lat:new String[]{"91","-91","NaN","Infinity"}) mvc.perform(get("/api/weather").header("Authorization",token).param("latitude",lat).param("longitude","106")).andExpect(status().isBadRequest());
  verifyNoInteractions(provider);
 }
 @Test void authenticatedWeatherIsRoundedAndProviderOutageIsGraceful() throws Exception {
  var token=token();when(provider.fetch(10.76,106.66)).thenReturn(new WeatherReport.Observation(30,35,61,1,12,true,Instant.now()));
  mvc.perform(get("/api/weather").header("Authorization",token).param("latitude","10.7611").param("longitude","106.6611"))
   .andExpect(status().isOk()).andExpect(jsonPath("$.latitude").value(10.76)).andExpect(jsonPath("$.current.weatherCode").value(61));
  when(provider.fetch(12,108)).thenThrow(new IllegalStateException("offline"));
  mvc.perform(get("/api/weather").header("Authorization",token).param("latitude","12").param("longitude","108"))
   .andExpect(status().isOk()).andExpect(jsonPath("$.available").value(false)).andExpect(jsonPath("$.current").isEmpty());
 }
}
