package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import java.time.Instant;
import java.util.*;

@Service @RequiredArgsConstructor
public class WorkerRankingService {
    private final UserRepository users;
    private final JobApplicationRepository applications;
    private final CurrentUser current;
    public record Rank(int rank, Long workerId, String fullName, WorkerTier workerTier, int reputationScore,
        double rating, int completedJobs, boolean verified, int experienceYears) { }
    public record Review(Long id, Long jobId, String jobTitle, String contractorName, int stars, Instant reviewedAt) { }
    public record Reviews(List<Review> items, boolean hasMore) { }
    @Transactional(readOnly = true)
    public List<Rank> leaderboard(int limit) {
        current.get();
        // Enum strings sort DIAMOND, GOLD, SILVER; stable tie-breakers keep rank deterministic.
        var people = users.findByRoleAndActiveTrueAndCompletedJobsGreaterThan(Role.ROLE_WORKER, 0,
            PageRequest.of(0, limit, Sort.by("workerTier").ascending().and(Sort.by("reputationScore").descending())
                .and(Sort.by("rating").descending()).and(Sort.by("completedJobs").descending()).and(Sort.by("id").ascending())));
        var result = new ArrayList<Rank>();
        for (int i = 0; i < people.size(); i++) { var u = people.get(i); result.add(new Rank(i + 1, u.getId(), u.getFullName(),
            u.getWorkerTier(), u.getReputationScore(), u.getRating(), u.getCompletedJobs(), u.isVerified(), u.getExperienceYears())); }
        return result;
    }
    @Transactional(readOnly = true)
    public Reviews reviews(Long id, Long beforeId, int limit) {
        current.get();
        users.findById(id).filter(u -> u.getRole() == Role.ROLE_WORKER && u.isActive())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy thợ đang hoạt động"));
        var rows = applications.reviews(id, beforeId == null ? Long.MAX_VALUE : beforeId, PageRequest.of(0, limit + 1));
        return new Reviews(rows.stream().limit(limit).map(a -> new Review(a.getId(), a.getJob().getId(), a.getJob().getTitle(),
            a.getJob().getContractor().getFullName(), a.getWorkerRating(), a.getReviewedAt())).toList(), rows.size() > limit);
    }
}
