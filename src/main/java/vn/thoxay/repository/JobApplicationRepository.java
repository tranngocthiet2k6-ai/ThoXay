package vn.thoxay.repository;

import vn.thoxay.entity.ApplicationStatus;
import vn.thoxay.entity.JobApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface JobApplicationRepository extends JpaRepository<JobApplication, Long> {
    @Query("select a from JobApplication a join fetch a.job j where a.worker.id=:workerId "
        + "and a.status=vn.thoxay.entity.ApplicationStatus.ACCEPTED "
        + "and j.status in (vn.thoxay.entity.JobStatus.OPEN,vn.thoxay.entity.JobStatus.IN_PROGRESS) "
        + "and j.startsOn<=:end and j.endsOn>=:start")
    List<JobApplication> overlapping(@Param("workerId") Long workerId, @Param("start") java.time.LocalDate start,
        @Param("end") java.time.LocalDate end);
    boolean existsByJobIdAndWorkerId(Long jobId, Long workerId);
    boolean existsByJobIdAndWorkerIdAndStatus(Long jobId, Long workerId, ApplicationStatus status);
    List<JobApplication> findByJobIdOrderByAppliedAtDesc(Long jobId);
    List<JobApplication> findByJobIdOrderByAppliedAtDesc(Long jobId,org.springframework.data.domain.Pageable page);
    List<JobApplication> findByWorkerIdOrderByAppliedAtDesc(Long workerId);
    long countByJobIdAndStatus(Long jobId, ApplicationStatus status);
    void deleteByJobId(Long jobId);
    @Query("select a.job.id from JobApplication a where a.id = :id")
    Optional<Long> findJobIdById(@Param("id") Long id);
    @Query("select avg(a.workerRating) from JobApplication a where a.worker.id = :id "
        + "and a.status = vn.thoxay.entity.ApplicationStatus.ACCEPTED "
        + "and a.job.status = vn.thoxay.entity.JobStatus.COMPLETED")
    Double averageRatingByWorkerId(@Param("id") Long id);
    @Query("select count(a) from JobApplication a where a.worker.id = :id and a.workerRating is not null "
        + "and a.status = vn.thoxay.entity.ApplicationStatus.ACCEPTED and a.job.status = vn.thoxay.entity.JobStatus.COMPLETED")
    long completedRatings(@Param("id") Long id);
    @Query("select a from JobApplication a where a.worker.id = :id and a.workerRating is not null "
        + "and a.status = vn.thoxay.entity.ApplicationStatus.ACCEPTED and a.job.status = vn.thoxay.entity.JobStatus.COMPLETED "
        + "and a.id < :before order by a.id desc")
    List<JobApplication> reviews(@Param("id") Long id, @Param("before") long before, org.springframework.data.domain.Pageable page);
}
