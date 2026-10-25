package vn.thoxay.dto;

import vn.thoxay.entity.JobApplication;
import java.time.LocalDateTime;

public record ApplicationResponse(Long id, JobResponse job, Long workerId, String workerName,
    String workerPhone, double workerRating, boolean workerVerified, boolean workerActive,
    String status, LocalDateTime appliedAt) {
    public static ApplicationResponse of(JobApplication application) {
        var worker = application.getWorker();
        return new ApplicationResponse(application.getId(), JobResponse.of(application.getJob(), null),
            worker.getId(), worker.getFullName(), worker.getPhoneNumber(), worker.getRating(),
            worker.isVerified(), worker.isActive(), application.getStatus().name(), application.getAppliedAt());
    }
}
