package vn.thoxay.attendance;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import java.time.LocalDate;
import java.util.*;
public interface AttendanceRepository extends JpaRepository<AttendanceRecord,Long> {
 Optional<AttendanceRecord> findByApplicationIdAndWorkDay(Long id,LocalDate day);
 boolean existsByApplicationId(Long id);
 @Query("select new vn.thoxay.attendance.AttendanceView(a.id,a.application.id,a.application.worker.id,a.application.worker.fullName,a.workDay,a.checkedInAt,a.checkedOutAt,a.checkinMethod,a.checkoutMethod,w.id,w.caption,w.status,w.feedback,w.version) from AttendanceRecord a left join WorkLog w on w.attendance=a where a.application.id=:id and a.workDay<:before order by a.workDay desc")
 List<AttendanceView> history(@Param("id")Long id,@Param("before")LocalDate before,Pageable page);
 @Query("select new vn.thoxay.attendance.AttendanceView(a.id,a.application.id,a.application.worker.id,a.application.worker.fullName,a.workDay,a.checkedInAt,a.checkedOutAt,a.checkinMethod,a.checkoutMethod,w.id,w.caption,w.status,w.feedback,w.version) from AttendanceRecord a left join WorkLog w on w.attendance=a where a.application.job.id=:id and a.workDay=:day order by a.application.worker.id")
 List<AttendanceView> byJob(@Param("id")Long id,@Param("day")LocalDate day,Pageable page);
 @Query("select count(a) from AttendanceRecord a where a.application.id=:id") long total(@Param("id")Long id);
 @Query("select count(a) from AttendanceRecord a join WorkLog w on w.attendance=a where a.application.id=:id and a.checkedOutAt is not null and w.status='APPROVED'") long approved(@Param("id")Long id);
}
