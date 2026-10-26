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
import java.time.Instant;
import java.util.List;

@Service @RequiredArgsConstructor
public class ApplicationCancellationService {
    private final JobApplicationRepository applications;
    private final JobRepository jobs;
    private final CurrentUser current;
    private final WorkerRatingService workers;
    private final ReputationService reputation;
    private final NotificationService notifications;

    @Transactional
    public ApplicationResponse cancel(Long id, CancelApplicationRequest request) {
        User actor = current.require(Role.ROLE_WORKER);
        Long jobId = applications.findJobIdById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Đơn ứng tuyển không tồn tại"));
        // Same lock order as accepting/completing work: job, then worker.
        Job job = jobs.findLockedById(jobId).orElseThrow();
        JobApplication application = applications.findById(id).orElseThrow();
        if (!application.getWorker().getId().equals(actor.getId()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Bạn chỉ được hủy đơn của chính mình");
        if (application.getStatus() == ApplicationStatus.CANCELLED) return ApplicationResponse.of(application);
        if (application.getStatus() != ApplicationStatus.ACCEPTED || job.getStatus() != JobStatus.IN_PROGRESS || application.getWorkerRating() != null)
            throw new ApiException(HttpStatus.CONFLICT, "Chỉ được hủy đơn đã nhận của công trình đang thi công");
        User worker = workers.lockWorkers(List.of(actor.getId())).get(0);
        int before = worker.getReputationScore();
        worker.setCancelledJobs(worker.getCancelledJobs() + 1);
        reputation.apply(worker, application, "CANCELLED", -ReputationService.CANCELLATION_PENALTY);
        application.setStatus(ApplicationStatus.CANCELLED);
        application.setCancellationReason(request.reason().strip());
        application.setCancelledAt(Instant.now());
        application.setCancellationPenalty(before - worker.getReputationScore());
        applications.flush();
        notifications.create(job.getContractor(), job, "cancelled:owner:" + id, "WORKER_CANCELLED",
            "Thợ đã hủy việc đang làm", "Công trình có vị trí trống. Bạn có thể tuyển người thay thế: " + job.getTitle());
        notifications.create(worker, job, "cancelled:worker:" + id, "APPLICATION_CANCELLED",
            "Đã hủy việc", "Uy tín bị trừ " + application.getCancellationPenalty() + " điểm. Bậc thợ đã được tính lại.");
        return ApplicationResponse.of(application);
    }
}
