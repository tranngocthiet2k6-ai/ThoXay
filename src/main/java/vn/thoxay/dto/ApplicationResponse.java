package vn.thoxay.dto;

import vn.thoxay.entity.JobApplication;
import java.time.LocalDateTime;

public record ApplicationResponse(Long id, JobResponse job, Long workerId, String workerName,
    String workerPhone, double workerRating, boolean workerVerified, boolean workerActive,
    String status, LocalDateTime appliedAt, Integer jobRating, String cancellationReason,
    java.time.Instant cancelledAt, int cancellationPenalty) {
    public static ApplicationResponse of(JobApplication application) {
        var worker = application.getWorker();
        boolean accepted = application.getStatus() == vn.thoxay.entity.ApplicationStatus.ACCEPTED;
        return new ApplicationResponse(application.getId(), JobResponse.of(application.getJob(), null, accepted),
            worker.getId(), worker.getFullName(), accepted ? worker.getPhoneNumber() : null, worker.getRating(),
            worker.isVerified(), worker.isActive(), application.getStatus().name(), application.getAppliedAt(), application.getWorkerRating(),
            application.getCancellationReason(), application.getCancelledAt(), application.getCancellationPenalty());
    }
}
