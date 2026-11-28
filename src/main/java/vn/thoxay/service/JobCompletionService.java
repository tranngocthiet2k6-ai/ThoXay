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
    private final java.time.Clock clock;

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
        if (job.getRatingsFinalizedAt() != null || job.getStatus() == JobStatus.COMPLETED) {
            if (accepted.stream().allMatch(a -> Objects.equals(a.getWorkerRating(), scores.get(a.getWorker().getId()))))
                return JobResponse.of(job, null);
            throw new ApiException(HttpStatus.CONFLICT, "Đánh giá đã chốt, không thể chấm lại");
        }
        if (job.getStatus() != JobStatus.IN_PROGRESS)
            throw new ApiException(HttpStatus.CONFLICT, "Chỉ có thể hoàn thành công trình đang thi công");
        for (JobApplication application : accepted) {
            application.setWorkerRating(scores.get(application.getWorker().getId()));
            application.setReviewedAt(clock.instant());
        }
        job.setRatingsFinalizedAt(clock.instant());
        job.setRecruitmentClosed(true);
        allApplications.stream().filter(a -> a.getStatus() == ApplicationStatus.PENDING)
            .forEach(a -> a.setStatus(ApplicationStatus.REJECTED));
        applications.flush();
        for (JobApplication a : accepted) notifications.create(a.getWorker(), job, "ratings-finalized:" + a.getId(), "JOB_RATINGS_FINALIZED",
            "Đã chốt đánh giá, chờ thanh toán", "Bạn được đánh giá " + a.getWorkerRating() + "/5 sao. Công trình vẫn đang làm đến khi chủ thầu thanh toán đủ: " + job.getTitle());
        return JobResponse.of(job, null);
    }

    /** Called by the payment transaction while it still holds the job lock. */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public void completeAfterPayment(Job job) {
        if (job.getStatus() != JobStatus.IN_PROGRESS || job.getRatingsFinalizedAt() == null) return;
        var accepted = applications.findByJobIdOrderByAppliedAtDesc(job.getId()).stream()
            .filter(a -> a.getStatus() == ApplicationStatus.ACCEPTED).toList();
        if (accepted.isEmpty() || accepted.stream().anyMatch(a -> a.getWorkerRating() == null || a.getPaidAt() == null)) return;
        var workers = ratings.lockWorkers(accepted.stream().map(a -> a.getWorker().getId()).toList());
        job.setStatus(JobStatus.COMPLETED);
        applications.flush();
        ratings.recompute(workers);
        for (var a : accepted) {
            reputation.apply(a.getWorker(), a, "COMPLETED", ReputationService.COMPLETION_BONUS);
            notifications.create(a.getWorker(), job, "completed:" + a.getId(), "JOB_COMPLETED",
                "Công trình đã hoàn thành", "Toàn bộ thợ đã được thanh toán. Công trình hoàn thành: " + job.getTitle());
        }
    }
}
