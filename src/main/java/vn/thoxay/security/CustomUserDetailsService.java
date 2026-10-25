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
        return org.springframework.security.core.userdetails.User.withUsername(user.getPhoneNumber())
            .password(user.getPassword()).authorities(user.getRole().name()).disabled(!user.isActive()).build();
    }
}
