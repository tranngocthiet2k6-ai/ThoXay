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
import java.util.List;

@Service @RequiredArgsConstructor
public class ApplicationService {
    private final JobApplicationRepository applications;
    private final JobRepository jobs;
    private final CurrentUser current;

    @Transactional
    public ApplicationResponse apply(ApplicationRequest request) {
        User worker = current.require(Role.ROLE_WORKER);
        Job job = lockedJob(request.jobId());
        if (applications.existsByJobIdAndWorkerId(job.getId(), worker.getId()))
            throw new ApiException(HttpStatus.CONFLICT, "Bạn đã ứng tuyển công trình này");
        if (job.getStatus() != JobStatus.OPEN || !job.getContractor().isActive())
            throw new ApiException(HttpStatus.CONFLICT, "Công trình đã ngừng tuyển thợ");
        JobApplication application = new JobApplication(); application.setJob(job); application.setWorker(worker);
        return ApplicationResponse.of(applications.saveAndFlush(application));
    }

    @Transactional(readOnly = true)
    public List<ApplicationResponse> byJob(Long id) {
        Job job = jobs.findById(id).orElseThrow(() -> notFound("Công trình"));
        current.requireOwner(job.getContractor().getId(), Role.ROLE_CONTRACTOR);
        return applications.findByJobIdOrderByAppliedAtDesc(id).stream().map(ApplicationResponse::of).toList();
    }

    @Transactional(readOnly = true)
    public List<ApplicationResponse> byWorker(Long id) {
        current.requireOwner(id, Role.ROLE_WORKER);
        return applications.findByWorkerIdOrderByAppliedAtDesc(id).stream().map(ApplicationResponse::of).toList();
    }

    @Transactional
    public ApplicationResponse updateStatus(Long id, ApplicationStatusRequest request) {
        Long jobId = applications.findJobIdById(id).orElseThrow(() -> notFound("Đơn ứng tuyển"));
        Job job = lockedJob(jobId);
        current.requireOwner(job.getContractor().getId(), Role.ROLE_CONTRACTOR);
        JobApplication application = applications.findById(id).orElseThrow(() -> notFound("Đơn ứng tuyển"));
        ApplicationStatus status = ApplicationStatus.valueOf(request.status());
        if (application.getStatus() == status) return ApplicationResponse.of(application);
        if (application.getStatus() != ApplicationStatus.PENDING)
            throw new ApiException(HttpStatus.CONFLICT, "Đơn ứng tuyển đã được xử lý");
        if (job.getStatus() == JobStatus.COMPLETED || job.getStatus() == JobStatus.CANCELLED)
            throw new ApiException(HttpStatus.CONFLICT, "Công trình đã kết thúc");
        if (status == ApplicationStatus.ACCEPTED) {
            if (!application.getWorker().isActive())
                throw new ApiException(HttpStatus.CONFLICT, "Tài khoản thợ đã bị khóa");
            long accepted = applications.countByJobIdAndStatus(jobId, ApplicationStatus.ACCEPTED);
            if (job.getStatus() != JobStatus.OPEN || accepted >= job.getRequiredWorkers())
                throw new ApiException(HttpStatus.CONFLICT, "Công trình đã đủ số lượng thợ");
            if (accepted + 1 >= job.getRequiredWorkers()) job.setStatus(JobStatus.IN_PROGRESS);
        }
        application.setStatus(status);
        applications.saveAndFlush(application);
        return ApplicationResponse.of(application);
    }

    private Job lockedJob(Long id) { return jobs.findLockedById(id).orElseThrow(() -> notFound("Công trình")); }
    private ApiException notFound(String resource) { return new ApiException(HttpStatus.NOT_FOUND, resource + " không tồn tại"); }
}
