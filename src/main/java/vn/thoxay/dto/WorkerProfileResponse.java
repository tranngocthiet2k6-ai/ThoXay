package vn.thoxay.dto;

import vn.thoxay.entity.User;
import java.util.List;

public record WorkerProfileResponse(Long id, String fullName, boolean verified, double rating,
    int experienceYears, String experienceSummary, List<String> skills, List<String> projectImages,
    int reputationScore, int completedJobs, String workerTier) {
    public static WorkerProfileResponse of(User u) {
        u.recalculateTier();
        return new WorkerProfileResponse(u.getId(), u.getFullName(), u.isVerified(), u.getRating(), u.getExperienceYears(),
            u.getExperienceSummary(), List.copyOf(u.getSkills()), List.copyOf(u.getProjectImages()), u.getReputationScore(), u.getCompletedJobs(), u.getWorkerTier().name());
    }
}
