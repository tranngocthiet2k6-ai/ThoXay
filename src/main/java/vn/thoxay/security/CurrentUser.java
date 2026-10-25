package vn.thoxay.security;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.exception.AccountLockedException;
import vn.thoxay.repository.UserRepository;

@Component @RequiredArgsConstructor
public class CurrentUser {
    private final UserRepository users;
    public User get() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) throw new ApiException(HttpStatus.UNAUTHORIZED, "Vui lòng đăng nhập");
        User user = users.findByPhoneNumber(auth.getName())
            .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Không tìm thấy tài khoản"));
        if (!user.isActive()) throw new AccountLockedException();
        return user;
    }
    public User require(Role role) {
        User user = get();
        if (user.getRole() != role) throw new AccessDeniedException("Vai trò không phù hợp");
        return user;
    }
    public void requireOwner(Long id, Role role) {
        if (!require(role).getId().equals(id)) throw new AccessDeniedException("Không thuộc tài khoản của bạn");
    }
}
