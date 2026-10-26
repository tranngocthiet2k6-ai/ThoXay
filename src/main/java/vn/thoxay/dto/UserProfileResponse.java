package vn.thoxay.dto;

import vn.thoxay.entity.User;
import java.time.LocalDate;
import java.util.List;

public record UserProfileResponse(Long id, String fullName, String phoneNumber, String role,
    boolean verified, String cccdFrontImage, String cccdBackImage, double rating,
    LocalDate dateOfBirth, int experienceYears, String experienceSummary, List<String> skills, List<String> projectImages) {
    public static UserProfileResponse of(User user) {
        return new UserProfileResponse(user.getId(), user.getFullName(), user.getPhoneNumber(),
            user.getRole().name(), user.isVerified(), user.getCccdFrontImage(), user.getCccdBackImage(), user.getRating(),
            user.getDateOfBirth(), user.getExperienceYears(), user.getExperienceSummary(), List.copyOf(user.getSkills()), List.copyOf(user.getProjectImages()));
    }
}
