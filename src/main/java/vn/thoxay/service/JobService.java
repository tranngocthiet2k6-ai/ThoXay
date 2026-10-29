package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.*;
import vn.thoxay.entity.*;
import vn.thoxay.repository.JobRepository;
import vn.thoxay.security.CurrentUser;
import java.util.List;
import java.util.Comparator;

@Service @RequiredArgsConstructor
public class JobService {
    private final JobRepository jobs;
    private final CurrentUser current;
    private final vn.thoxay.repository.JobApplicationRepository applications;
    private final java.time.Clock clock;
    private final NotificationService notifications;

    @Transactional
    public JobResponse create(JobRequest request) {
        User contractor = current.require(Role.ROLE_CONTRACTOR);
        validateDates(request);
        Job job = new Job(); job.setContractor(contractor); job.setTitle(request.title().trim());
        job.setDescription(request.description()); job.setJobType(request.jobType());
        job.setSalaryPerDay(request.salaryPerDay()); job.setAddress(request.address().trim());
        job.setLatitude(request.latitude()); job.setLongitude(request.longitude());
        job.setRequiredWorkers(request.requiredWorkers());
        job.setStartsOn(request.startsOn()); job.setEndsOn(request.endsOn());
        return JobResponse.of(jobs.save(job), null);
    }
    @Transactional
    public JobResponse update(Long id,JobRequest request) {
        var job=jobs.findLockedById(id).orElseThrow(() -> new vn.thoxay.exception.ApiException(org.springframework.http.HttpStatus.NOT_FOUND,"Công trình không tồn tại"));
        current.requireOwner(job.getContractor().getId(),Role.ROLE_CONTRACTOR); validateDates(request);
        if(job.getStatus()!=vn.thoxay.entity.JobStatus.OPEN || applications.countByJobIdAndStatus(id,ApplicationStatus.ACCEPTED)>0)
            throw new vn.thoxay.exception.ApiException(org.springframework.http.HttpStatus.CONFLICT,"Chỉ sửa công trình chưa nhận thợ");
        job.setTitle(request.title().trim()); job.setDescription(request.description()); job.setJobType(request.jobType());
        job.setSalaryPerDay(request.salaryPerDay()); job.setAddress(request.address().trim());
        job.setLatitude(request.latitude()); job.setLongitude(request.longitude()); job.setRequiredWorkers(request.requiredWorkers());
        job.setStartsOn(request.startsOn()); job.setEndsOn(request.endsOn()); job.setTermsVersion(job.getTermsVersion()+1);
        for(var a:applications.findByJobIdOrderByAppliedAtDesc(id)) if(a.getStatus()==ApplicationStatus.PENDING)
            notifications.create(a.getWorker(),job,"terms:"+a.getId()+":"+job.getTermsVersion(),"JOB_TERMS_CHANGED","Điều khoản công trình đã đổi","Mở đơn ứng tuyển và xác nhận lại điều khoản trước khi được duyệt.");
        return JobResponse.of(job,null);
    }
    @Transactional(readOnly=true)
    public JobResponse detail(Long id) {
        var user=current.get(); var job=jobs.findById(id).orElseThrow(() -> new vn.thoxay.exception.ApiException(org.springframework.http.HttpStatus.NOT_FOUND,"Công trình không tồn tại"));
        if(!job.getContractor().isActive()) throw new vn.thoxay.exception.ApiException(org.springframework.http.HttpStatus.NOT_FOUND,"Công trình không tồn tại");
        boolean contact=user.getId().equals(job.getContractor().getId()) || applications.existsByJobIdAndWorkerIdAndStatus(id,user.getId(),ApplicationStatus.ACCEPTED);
        return JobResponse.of(job,null,contact);
    }
    private void validateDates(JobRequest request) {
        var from=request.startsOn(); var to=request.endsOn();
        if((from==null)!=(to==null) || (from!=null&&(to.isBefore(from)||java.time.temporal.ChronoUnit.DAYS.between(from,to)>365||from.isBefore(java.time.LocalDate.now(clock)))))
            throw new vn.thoxay.exception.ApiException(org.springframework.http.HttpStatus.BAD_REQUEST,"Chọn lịch từ hôm nay, đủ ngày bắt đầu/kết thúc và tối đa 366 ngày");
    }
    @Transactional(readOnly = true)
    public List<JobResponse> nearby(double lat, double lng, double radius, String jobType, String sort) {
        if (!current.require(Role.ROLE_WORKER).isAvailable()) return List.of();
        var results = jobs.findNearby(lat, lng, radius).stream()
            .filter(j -> j.getEndsOn()==null||!j.getEndsOn().isBefore(java.time.LocalDate.now(clock)))
            .filter(j -> jobType == null || jobType.equals(j.getJobType()))
            .map(j -> JobResponse.of(j, distance(lat, lng, j.getLatitude(), j.getLongitude()), false));
        if ("SALARY_DESC".equals(sort)) results = results.sorted(Comparator.comparingDouble(JobResponse::salaryPerDay)
            .reversed().thenComparingDouble(JobResponse::distanceKm).thenComparing(JobResponse::id));
        return results.toList();
    }
    @Transactional(readOnly = true)
    public List<JobResponse> byContractor(Long id) {
        current.requireOwner(id, Role.ROLE_CONTRACTOR);
        return jobs.findByContractorIdOrderByCreatedAtDesc(id).stream().map(j -> JobResponse.of(j, null)).toList();
    }
    private double distance(double lat, double lng, double targetLat, double targetLng) {
        double a = Math.pow(Math.sin(Math.toRadians(targetLat - lat) / 2), 2)
            + Math.cos(Math.toRadians(lat)) * Math.cos(Math.toRadians(targetLat))
            * Math.pow(Math.sin(Math.toRadians(targetLng - lng) / 2), 2);
        return 6371 * 2 * Math.asin(Math.sqrt(Math.max(0, Math.min(1, a))));
    }
}
