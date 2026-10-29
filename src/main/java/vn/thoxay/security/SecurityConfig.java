package vn.thoxay.security;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.*;
import org.springframework.core.annotation.Order;
import org.springframework.security.authentication.*;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.access.AccessDeniedHandlerImpl;
import org.springframework.security.web.csrf.CsrfException;
import org.springframework.web.cors.*;
import java.util.List;

@Configuration @EnableMethodSecurity @RequiredArgsConstructor
public class SecurityConfig {
    private final CustomUserDetailsService users;
    private final JwtAuthenticationFilter jwtFilter;

    @Bean BCryptPasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }
    @Bean AuthenticationManager authenticationManager(BCryptPasswordEncoder encoder) {
        var provider = new DaoAuthenticationProvider(users);
        provider.setPasswordEncoder(encoder);
        return new ProviderManager(provider);
    }

    @Bean FilterRegistrationBean<JwtAuthenticationFilter> jwtRegistration() {
        var registration = new FilterRegistrationBean<>(jwtFilter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean @Order(1)
    SecurityFilterChain api(HttpSecurity http) throws Exception {
        return http.securityMatcher("/api/**").csrf(csrf -> csrf.disable()).cors(cors -> {})
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a.requestMatchers("/api/auth/**").permitAll().anyRequest().authenticated())
            .exceptionHandling(e -> e.authenticationEntryPoint((req, res, ex) -> {
                res.setStatus(401); res.setContentType("application/json;charset=UTF-8");
                res.getWriter().write("{\"status\":401,\"message\":\"Vui lòng đăng nhập lại\"}");
            }).accessDeniedHandler((req, res, ex) -> {
                res.setStatus(403); res.setContentType("application/json;charset=UTF-8");
                res.getWriter().write("{\"status\":403,\"message\":\"Bạn không có quyền truy cập\"}");
            }))
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class).build();
    }

    @Bean @Order(2)
    SecurityFilterChain web(HttpSecurity http, AuthenticationManager manager) throws Exception {
        var forbidden = new AccessDeniedHandlerImpl();
        return http.authenticationManager(manager)
            .authorizeHttpRequests(a -> a.requestMatchers("/health", "/ws/chat", "/admin/**", "/", "/error", "/css/**", "/js/**", "/vendor/**").permitAll().anyRequest().denyAll())
            .exceptionHandling(e -> e.accessDeniedHandler((request, response, exception) -> {
                if (exception instanceof CsrfException && "POST".equals(request.getMethod())
                        && (request.getContextPath() + "/admin/login").equals(request.getRequestURI())) {
                    response.sendRedirect(request.getContextPath() + "/admin/login?expired");
                    return;
                }
                forbidden.handle(request, response, exception);
            }))
            .formLogin(f -> f.loginPage("/admin/login").loginProcessingUrl("/admin/login")
                .usernameParameter("phoneNumber").defaultSuccessUrl("/admin/dashboard", true).permitAll())
            .logout(l -> l.logoutUrl("/admin/logout").logoutSuccessUrl("/admin/login?logout"))
            .build();
    }

    @Bean CorsConfigurationSource corsConfigurationSource(@Value("${app.cors.origins}") List<String> origins) {
        var config = new CorsConfiguration(); config.setAllowedOrigins(origins);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        var source = new UrlBasedCorsConfigurationSource(); source.registerCorsConfiguration("/api/**", config);
        return source;
    }
}
