package vn.thoxay.scheduling;

import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.*;

public interface CalendarBlockRepository extends JpaRepository<CalendarBlock,Long> {
    List<CalendarBlock> findByWorkerIdAndDayBetweenOrderByDay(Long workerId,LocalDate from,LocalDate to);
    Optional<CalendarBlock> findByIdAndWorkerId(Long id,Long workerId);
}
