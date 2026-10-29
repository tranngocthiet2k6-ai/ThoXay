package vn.thoxay.attendance;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;
public interface WorkLogRepository extends JpaRepository<WorkLog,Long>{
 Optional<WorkLog> findByAttendanceId(Long id);
 @Query("select w.attendance.application.id from WorkLog w where w.id=:id") Optional<Long> applicationId(@Param("id")Long id);
}
