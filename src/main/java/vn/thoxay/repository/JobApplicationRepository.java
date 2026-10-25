package vn.thoxay.repository;

import vn.thoxay.entity.ApplicationStatus;
import vn.thoxay.entity.JobApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface JobApplicationRepository extends JpaRepository<JobApplication, Long> {
    boolean existsByJobIdAndWorkerId(Long jobId, Long workerId);
    List<JobApplication> findByJobIdOrderByAppliedAtDesc(Long jobId);
    List<JobApplication> findByWorkerIdOrderByAppliedAtDesc(Long workerId);
    long countByJobIdAndStatus(Long jobId, ApplicationStatus status);
    void deleteByJobId(Long jobId);
}
