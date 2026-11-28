package vn.thoxay.attendance;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface AttendanceCorrectionRepository extends JpaRepository<AttendanceCorrection,Long> {
 List<AttendanceCorrection> findByAttendanceIdOrderByIdDesc(Long attendanceId);
}
