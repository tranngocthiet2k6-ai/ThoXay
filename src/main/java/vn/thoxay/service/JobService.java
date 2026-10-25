package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.*;
import vn.thoxay.entity.*;
import vn.thoxay.repository.JobRepository;
import vn.thoxay.security.CurrentUser;
import java.util.List;

@Service @RequiredArgsConstructor
public class JobService {
    private final JobRepository jobs;
    private final CurrentUser current;

    @Transactional
    public JobResponse create(JobRequest request) {
        User contractor = current.require(Role.ROLE_CONTRACTOR);
        Job job = new Job(); job.setContractor(contractor); job.setTitle(request.title().trim());
        job.setDescription(request.description()); job.setJobType(request.jobType());
        job.setSalaryPerDay(request.salaryPerDay()); job.setAddress(request.address().trim());
        job.setLatitude(request.latitude()); job.setLongitude(request.longitude());
        job.setRequiredWorkers(request.requiredWorkers());
        return JobResponse.of(jobs.save(job), null);
    }
    @Transactional(readOnly = true)
    public List<JobResponse> nearby(double lat, double lng, double radius) {
        current.require(Role.ROLE_WORKER);
        return jobs.findNearby(lat, lng, radius).stream()
            .map(j -> JobResponse.of(j, distance(lat, lng, j.getLatitude(), j.getLongitude()))).toList();
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
