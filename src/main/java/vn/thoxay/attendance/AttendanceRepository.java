package vn.thoxay.attendance;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import java.time.LocalDate;
import java.util.*;
public interface AttendanceRepository extends JpaRepository<AttendanceRecord,Long> {
 Optional<AttendanceRecord> findByApplicationIdAndWorkDay(Long id,LocalDate day);
 boolean existsByApplicationId(Long id);
 @Query("select a.application.id from AttendanceRecord a where a.id=:id") Optional<Long> applicationId(@Param("id")Long id);
 @Query("select new vn.thoxay.attendance.AttendanceView(a.id,a.application.id,a.application.worker.id,a.application.worker.fullName,a.workDay,a.checkedInAt,a.checkedOutAt,a.checkinMethod,a.checkoutMethod,w.id,w.caption,w.status,w.feedback,w.version,case when w.detailPhoto is not null then true else false end,a.version,c.id,c.status,c.reason,c.feedback,case when a.checkoutMethod<>'ADJUSTED' and a.checkedOutAt>=:undoAfter and a.workDay=:today and (w.id is null or w.status<>'APPROVED') and a.application.job.status in (vn.thoxay.entity.JobStatus.OPEN,vn.thoxay.entity.JobStatus.IN_PROGRESS) and a.application.job.contractor.active=true and (c.id is null or c.status<>'PENDING') and not exists (select p.id from JobPayment p where p.application=a.application) then true else false end) from AttendanceRecord a left join WorkLog w on w.attendance=a left join AttendanceCorrection c on c.id=a.latestCorrectionId where a.application.id=:id and a.workDay<:before order by a.workDay desc")
 List<AttendanceView> history(@Param("id")Long id,@Param("before")LocalDate before,@Param("undoAfter")java.time.Instant undoAfter,@Param("today")LocalDate today,Pageable page);
 @Query("select new vn.thoxay.attendance.AttendanceView(a.id,a.application.id,a.application.worker.id,a.application.worker.fullName,a.workDay,a.checkedInAt,a.checkedOutAt,a.checkinMethod,a.checkoutMethod,w.id,w.caption,w.status,w.feedback,w.version,case when w.detailPhoto is not null then true else false end,a.version,c.id,c.status,c.reason,c.feedback,case when a.checkoutMethod<>'ADJUSTED' and a.checkedOutAt>=:undoAfter and a.workDay=:today and (w.id is null or w.status<>'APPROVED') and a.application.job.status in (vn.thoxay.entity.JobStatus.OPEN,vn.thoxay.entity.JobStatus.IN_PROGRESS) and a.application.job.contractor.active=true and (c.id is null or c.status<>'PENDING') and not exists (select p.id from JobPayment p where p.application=a.application) then true else false end) from AttendanceRecord a left join WorkLog w on w.attendance=a left join AttendanceCorrection c on c.id=a.latestCorrectionId where a.application.job.id=:id and a.workDay=:day order by a.application.worker.id")
 List<AttendanceView> byJob(@Param("id")Long id,@Param("day")LocalDate day,@Param("undoAfter")java.time.Instant undoAfter,@Param("today")LocalDate today,Pageable page);
 @Query("select count(a) from AttendanceRecord a where a.application.id=:id") long total(@Param("id")Long id);
 @Query("select count(a) from AttendanceRecord a join WorkLog w on w.attendance=a where a.application.id=:id and a.checkedOutAt is not null and w.status='APPROVED' and not exists (select c.id from AttendanceCorrection c where c.id=a.latestCorrectionId and c.status='PENDING')") long approved(@Param("id")Long id);
}
