package vn.thoxay.security;

import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;
import vn.thoxay.repository.UserRepository;

@Service @RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {
    private final UserRepository users;
    @Override
    public UserDetails loadUserByUsername(String phone) {
        var user = users.findByPhoneNumber(phone).orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy tài khoản"));
        return new AccountDetails(user);
    }
    public static class AccountDetails extends org.springframework.security.core.userdetails.User {
        private final long securityVersion;
        public final Long userId;
        public AccountDetails(vn.thoxay.entity.User user) {
            super(user.getPhoneNumber(), user.getPassword(), user.isActive(), true, true, true,
                java.util.List.of(new org.springframework.security.core.authority.SimpleGrantedAuthority(user.getRole().name())));
            securityVersion = user.getSecurityVersion();
            userId = user.getId();
        }
        public long securityVersion() { return securityVersion; }
    }
}
