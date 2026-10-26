package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.exception.AccountLockedException;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.JwtUtil;
import java.nio.charset.StandardCharsets;

@Service @RequiredArgsConstructor
public class AuthService {
    private final UserRepository users;
    private final BCryptPasswordEncoder encoder;
    private final AuthenticationManager manager;
    private final JwtUtil jwt;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (request.password().getBytes(StandardCharsets.UTF_8).length > 72)
            throw new ApiException(HttpStatus.BAD_REQUEST, "Mật khẩu tối đa 72 byte UTF-8");
        if (users.existsByPhoneNumber(request.phoneNumber()))
            throw new ApiException(HttpStatus.CONFLICT, "Số điện thoại đã được đăng ký");
        User user = new User(); user.setPhoneNumber(request.phoneNumber());
        user.setPassword(encoder.encode(request.password())); user.setFullName(request.fullName().trim());
        user.setRole(Role.valueOf(request.role()));
        user.setAvailable(false);
        user.setCccdFrontImage(request.cccdFrontImage());
        user.setCccdBackImage(request.cccdBackImage());
        users.saveAndFlush(user);
        return response(user);
    }
    public AuthResponse login(LoginRequest request) {
        users.findByPhoneNumber(request.phoneNumber()).ifPresent(user -> {
            if (!user.isActive()) throw new AccountLockedException();
        });
        try {
            manager.authenticate(new UsernamePasswordAuthenticationToken(request.phoneNumber(), request.password()));
        } catch (DisabledException e) {
            throw new AccountLockedException();
        }
        User user = users.findByPhoneNumber(request.phoneNumber()).orElseThrow();
        if (!user.isActive()) throw new AccountLockedException();
        return response(user);
    }
    private AuthResponse response(User user) {
        return AuthResponse.of(jwt.generateToken(user.getPhoneNumber()), jwt.expiresInSeconds(), user);
    }
}
