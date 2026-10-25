package vn.thoxay.dto;

import vn.thoxay.entity.User;

public record UserProfileResponse(Long id, String fullName, String phoneNumber, String role,
    boolean verified, String cccdImage, double rating) {
    public static UserProfileResponse of(User user) {
        return new UserProfileResponse(user.getId(), user.getFullName(), user.getPhoneNumber(),
            user.getRole().name(), user.isVerified(), user.getCccdImage(), user.getRating());
    }
}
