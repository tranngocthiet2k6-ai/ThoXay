package vn.thoxay.repository;

import vn.thoxay.entity.ApplicationStatus;
import vn.thoxay.entity.JobApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface JobApplicationRepository extends JpaRepository<JobApplication, Long> {
    boolean existsByJobIdAndWorkerId(Long jobId, Long workerId);
    List<JobApplication> findByJobIdOrderByAppliedAtDesc(Long jobId);
    List<JobApplication> findByWorkerIdOrderByAppliedAtDesc(Long workerId);
    long countByJobIdAndStatus(Long jobId, ApplicationStatus status);
    void deleteByJobId(Long jobId);
    @Query("select a.job.id from JobApplication a where a.id = :id")
    Optional<Long> findJobIdById(@Param("id") Long id);
}
