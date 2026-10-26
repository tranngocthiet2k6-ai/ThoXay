package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import java.util.*;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor
public class JobCompletionService {
    private final JobRepository jobs;
    private final JobApplicationRepository applications;
    private final CurrentUser current;
    private final WorkerRatingService ratings;
    private final NotificationService notifications;
    private final ReputationService reputation;

    @Transactional
    public JobResponse complete(Long id, CompleteJobRequest request) {
        Job job = jobs.findLockedById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Công trình không tồn tại"));
        current.requireOwner(job.getContractor().getId(), Role.ROLE_CONTRACTOR);
        List<JobApplication> allApplications = applications.findByJobIdOrderByAppliedAtDesc(id);
        List<JobApplication> accepted = allApplications.stream()
            .filter(a -> a.getStatus() == ApplicationStatus.ACCEPTED).toList();
        Map<Long, Integer> scores = new HashMap<>();
        for (var rating : request.ratings()) {
            if (scores.putIfAbsent(rating.workerId(), rating.stars()) != null)
                throw new ApiException(HttpStatus.BAD_REQUEST, "Mỗi thợ chỉ được chấm điểm một lần trong công trình");
        }
        Set<Long> workerIds = accepted.stream().map(a -> a.getWorker().getId()).collect(Collectors.toSet());
        if (workerIds.isEmpty() || !workerIds.equals(scores.keySet()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Phải chấm điểm đầy đủ và chỉ cho thợ đã được nhận");
        if (job.getStatus() == JobStatus.COMPLETED) {
            if (accepted.stream().allMatch(a -> Objects.equals(a.getWorkerRating(), scores.get(a.getWorker().getId()))))
                return JobResponse.of(job, null);
            throw new ApiException(HttpStatus.CONFLICT, "Công trình đã hoàn thành và đã lưu đánh giá");
        }
        if (job.getStatus() != JobStatus.IN_PROGRESS)
            throw new ApiException(HttpStatus.CONFLICT, "Chỉ có thể hoàn thành công trình đang thi công");
        List<User> workers = ratings.lockWorkers(workerIds);
        for (JobApplication application : accepted) {
            application.setWorkerRating(scores.get(application.getWorker().getId()));
            application.setReviewedAt(java.time.Instant.now());
        }
        job.setStatus(JobStatus.COMPLETED);
        allApplications.stream().filter(a -> a.getStatus() == ApplicationStatus.PENDING)
            .forEach(a -> a.setStatus(ApplicationStatus.REJECTED));
        applications.flush();
        ratings.recompute(workers);
        for (JobApplication a : accepted) reputation.apply(a.getWorker(), a, "COMPLETED", ReputationService.COMPLETION_BONUS);
        for (JobApplication a : accepted) notifications.create(a.getWorker(), job, "completed:" + a.getId(), "JOB_COMPLETED",
            "Công trình đã hoàn thành", "Bạn được đánh giá " + a.getWorkerRating() + "/5 sao cho công trình: " + job.getTitle());
        return JobResponse.of(job, null);
    }
}
