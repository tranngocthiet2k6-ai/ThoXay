package vn.thoxay.dto;

import vn.thoxay.entity.Job;
import java.time.LocalDateTime;

public record JobResponse(Long id, Long contractorId, String contractorName, String contractorPhone,
    String title, String description, String jobType, double salaryPerDay, String address,
    double latitude, double longitude, int requiredWorkers, String status, LocalDateTime createdAt,
    Double distanceKm) {
    public static JobResponse of(Job job, Double distanceKm) {
        var owner = job.getContractor();
        return new JobResponse(job.getId(), owner.getId(), owner.getFullName(), owner.getPhoneNumber(),
            job.getTitle(), job.getDescription(), job.getJobType(), job.getSalaryPerDay(), job.getAddress(),
            job.getLatitude(), job.getLongitude(), job.getRequiredWorkers(), job.getStatus().name(),
            job.getCreatedAt(), distanceKm);
    }
}
