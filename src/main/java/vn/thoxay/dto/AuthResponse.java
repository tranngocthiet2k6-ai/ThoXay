package vn.thoxay.dto;

import vn.thoxay.entity.User;

public record AuthResponse(String token, String tokenType, long expiresIn,
                           Long userId, String phoneNumber, String fullName, String role) {
    public static AuthResponse of(String token, long expiresIn, User user) {
        return new AuthResponse(token, "Bearer", expiresIn, user.getId(),
                user.getPhoneNumber(), user.getFullName(), user.getRole().name());
    }
}
