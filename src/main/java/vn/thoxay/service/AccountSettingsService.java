package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.controller.AccountSettingsController.*;
import vn.thoxay.dto.AuthResponse;
import vn.thoxay.entity.User;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.*;
import java.nio.charset.StandardCharsets;

@Service @RequiredArgsConstructor
public class AccountSettingsService {
    private final CurrentUser current;
    private final UserRepository users;
    private final BCryptPasswordEncoder encoder;
    private final JwtUtil jwt;
    private final jakarta.persistence.EntityManager em;
    private User locked() {
        User user = current.get();
        em.refresh(user, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
        if (!user.isActive()) throw new vn.thoxay.exception.AccountLockedException();
        return user;
    }
    private void confirm(User user, String password) {
        if (!encoder.matches(password, user.getPassword())) throw new ApiException(HttpStatus.BAD_REQUEST, "Mật khẩu hiện tại không đúng");
    }
    private AuthResponse session(User user) {
        users.saveAndFlush(user);
        return AuthResponse.of(jwt.generateToken(user.getPhoneNumber(), user.getSecurityVersion(), user.getId()), jwt.expiresInSeconds(), user);
    }
    @Transactional public AuthResponse password(PasswordRequest request) {
        User user = locked(); confirm(user, request.currentPassword());
        String password = request.newPassword();
        if (password.getBytes(StandardCharsets.UTF_8).length > 72 || !password.matches("(?s).*[\\p{L}].*") || !password.matches("(?s).*[0-9].*"))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Mật khẩu cần ít nhất 8 ký tự, có chữ và số, tối đa 72 byte UTF-8");
        if (encoder.matches(password, user.getPassword())) throw new ApiException(HttpStatus.BAD_REQUEST, "Mật khẩu mới phải khác mật khẩu hiện tại");
        user.setPassword(encoder.encode(password)); user.setSecurityVersion(user.getSecurityVersion() + 1);
        return session(user);
    }
    @Transactional public AuthResponse phone(PhoneRequest request) {
        User user = locked(); confirm(user, request.currentPassword());
        if (request.phoneNumber().equals(user.getPhoneNumber())) return session(user);
        if (users.existsByPhoneNumber(request.phoneNumber())) throw new ApiException(HttpStatus.CONFLICT, "Số điện thoại đã được đăng ký");
        user.setPhoneNumber(request.phoneNumber()); user.setSecurityVersion(user.getSecurityVersion() + 1);
        return session(user);
    }
    @Transactional(readOnly=true) public PushPreferences notifications() {
        User user = current.get(); return new PushPreferences(user.isJobPushEnabled(), user.isChatPushEnabled());
    }
    @Transactional public PushPreferences notifications(PushPreferences request) {
        User user = locked(); user.setJobPushEnabled(request.jobPushEnabled()); user.setChatPushEnabled(request.chatPushEnabled());
        return request;
    }
}
