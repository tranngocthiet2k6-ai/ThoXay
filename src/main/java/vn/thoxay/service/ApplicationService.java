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
    private final NotificationService notifications;
    private final WorkerRatingService workerLocks;
    private final vn.thoxay.scheduling.WorkerCalendarService calendar;
    private final vn.thoxay.scheduling.CommitmentService commitments;
    private final java.time.Clock clock;

    @Transactional
    public ApplicationResponse apply(ApplicationRequest request) {
        User worker = current.require(Role.ROLE_WORKER);
        Job job = lockedJob(request.jobId());
        requireRecruitingDate(job);
        worker = workerLocks.lockWorkers(List.of(worker.getId())).get(0);
        if (!worker.isAvailable()) throw new ApiException(HttpStatus.CONFLICT, "Bạn đang Offline. Bật trạng thái nhận việc để ứng tuyển.");
        if (applications.existsByJobIdAndWorkerId(job.getId(), worker.getId()))
            throw new ApiException(HttpStatus.CONFLICT, "Bạn đã ứng tuyển công trình này");
        if ((job.getStatus() != JobStatus.OPEN && job.getStatus() != JobStatus.IN_PROGRESS) || !job.getContractor().isActive()
            || applications.countByJobIdAndStatus(job.getId(), ApplicationStatus.ACCEPTED) >= job.getRequiredWorkers())
            throw new ApiException(HttpStatus.CONFLICT, "Công trình đã ngừng tuyển thợ");
        JobApplication application = new JobApplication(); application.setJob(job); application.setWorker(worker);
        application.setProposedDailyRate(request.proposedDailyRate()); application.setWageNote(request.wageNote()==null?null:request.wageNote().trim());
        if(Boolean.TRUE.equals(request.acceptedTerms())) {
            if(!java.util.Objects.equals(request.termsVersion(),job.getTermsVersion()))
                throw new ApiException(HttpStatus.CONFLICT,"Điều khoản đã thay đổi; hãy xem lại công trình");
            application.setConsentVersion(job.getTermsVersion()); application.setAcceptedTermsAt(clock.instant());
        }
        if(job.getStartsOn()!=null && application.getAcceptedTermsAt()==null)
            throw new ApiException(HttpStatus.BAD_REQUEST,"Cần đọc và đồng ý cam kết nhận việc");
        applications.saveAndFlush(application);
        notifications.create(job.getContractor(), job, "application:" + application.getId(), "APPLICATION_RECEIVED",
            "Có đơn ứng tuyển mới", "Một người thợ vừa ứng tuyển công trình: " + job.getTitle());
        return ApplicationResponse.of(application);
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
        return decide(id,request,false);
    }

    /** Internal entry point: CrewService holds the job and every member lock in ID order. */
    @Transactional
    public ApplicationResponse updateCrewMemberStatus(Long id, ApplicationStatusRequest request) {
        return decide(id,request,true);
    }
    private ApplicationResponse decide(Long id, ApplicationStatusRequest request,boolean crewDecision) {
        Long jobId = applications.findJobIdById(id).orElseThrow(() -> notFound("Đơn ứng tuyển"));
        Job job = lockedJob(jobId);
        current.requireOwner(job.getContractor().getId(), Role.ROLE_CONTRACTOR);
        JobApplication application = applications.findById(id).orElseThrow(() -> notFound("Đơn ứng tuyển"));
        if(application.getCrewBatch()!=null && !crewDecision)
            throw new ApiException(HttpStatus.CONFLICT,"Đơn thuộc tổ đội; hãy duyệt hoặc từ chối toàn bộ tổ");
        ApplicationStatus status = ApplicationStatus.valueOf(request.status());
        if (application.getStatus() == status) {
            if(status==ApplicationStatus.ACCEPTED && request.acceptCounterOffer()!=null && application.getAgreedDailyRate()!=null) {
                long selected=Boolean.TRUE.equals(request.acceptCounterOffer())&&application.getProposedDailyRate()!=null?application.getProposedDailyRate():vn.thoxay.scheduling.CommitmentService.original(job);
                if(selected!=application.getAgreedDailyRate()) throw new ApiException(HttpStatus.CONFLICT,"Lương đã chốt không thể sửa");
            }
            return ApplicationResponse.of(application);
        }
        if (application.getStatus() != ApplicationStatus.PENDING)
            throw new ApiException(HttpStatus.CONFLICT, "Đơn ứng tuyển đã được xử lý");
        if (job.getStatus() == JobStatus.COMPLETED || job.getStatus() == JobStatus.CANCELLED)
            throw new ApiException(HttpStatus.CONFLICT, "Công trình đã kết thúc");
        if (status == ApplicationStatus.ACCEPTED) {
            requireRecruitingDate(job);
            User worker = workerLocks.lockWorkers(List.of(application.getWorker().getId())).get(0);
            if (!worker.isAvailable()) throw new ApiException(HttpStatus.CONFLICT, "Thợ đã tạm ngưng nhận việc mới");
            if (!application.getWorker().isActive())
                throw new ApiException(HttpStatus.CONFLICT, "Tài khoản thợ đã bị khóa");
            if(job.getStartsOn()!=null && (!Boolean.TRUE.equals(request.acceptedTerms())||!java.util.Objects.equals(request.termsVersion(),job.getTermsVersion())))
                throw new ApiException(HttpStatus.CONFLICT,"Cần xác nhận đúng phiên bản cam kết trước khi nhận thợ");
            calendar.requireAvailable(worker,job,application.getId());
            commitments.requireWorkerConsent(application);
            long accepted = applications.countByJobIdAndStatus(jobId, ApplicationStatus.ACCEPTED);
            if (accepted >= job.getRequiredWorkers())
                throw new ApiException(HttpStatus.CONFLICT, "Công trình đã đủ số lượng thợ");
            if (accepted + 1 >= job.getRequiredWorkers()) job.setStatus(JobStatus.IN_PROGRESS);
            commitments.freeze(application,Boolean.TRUE.equals(request.acceptCounterOffer()));
        }
        application.setStatus(status);
        applications.saveAndFlush(application);
        notifications.create(application.getWorker(), job, "decision:" + id + ":" + status, "APPLICATION_" + status,
            status == ApplicationStatus.ACCEPTED ? "Đơn ứng tuyển đã được duyệt" : "Kết quả ứng tuyển",
            status == ApplicationStatus.ACCEPTED ? "Chủ thầu đã nhận bạn. Mở ứng dụng để liên hệ và trao đổi công việc."
                : "Đơn ứng tuyển chưa được nhận. Bạn có thể tìm thêm công trình phù hợp.");
        return ApplicationResponse.of(application);
    }

    private void requireRecruitingDate(Job job) {
        if (job.getEndsOn() != null && job.getEndsOn().isBefore(java.time.LocalDate.now(clock)))
            throw new ApiException(HttpStatus.CONFLICT, "Công trình đã hết thời gian tuyển");
    }
    private Job lockedJob(Long id) { return jobs.findLockedById(id).orElseThrow(() -> notFound("Công trình")); }
    private ApiException notFound(String resource) { return new ApiException(HttpStatus.NOT_FOUND, resource + " không tồn tại"); }
}
