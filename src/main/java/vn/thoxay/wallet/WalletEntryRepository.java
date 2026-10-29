package vn.thoxay.wallet;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.domain.Pageable;
import java.time.Instant;
import java.util.*;
public interface WalletEntryRepository extends JpaRepository<WalletEntry,Long> {
    Optional<WalletEntry> findByReference(String reference);
    List<WalletEntry> findByUserIdAndIdLessThanOrderByIdDesc(Long userId,Long before,Pageable page);
    interface DailyTotals {
        String getCalendarDate();
        default java.time.LocalDate getIncomeDay() { return java.time.LocalDate.parse(getCalendarDate()); }
        Long getBase(); Long getTip(); Long getBonus(); Long getJobs();
    }
    // H2 CAST(timestamptz AS DATE) follows the session timezone, unlike PostgreSQL's AT TIME ZONE result.
    // Format the Vietnam wall-clock date explicitly, then parse ISO text without JDBC Date conversions.
    String DAILY_SQL = "SELECT TO_CHAR(created_at AT TIME ZONE 'Asia/Ho_Chi_Minh','YYYY-MM-DD') AS calendarDate, "
        + "SUM(CASE WHEN kind='WORK_EARNING' THEN amount ELSE 0 END) AS base, "
        + "SUM(CASE WHEN kind='TIP' THEN amount ELSE 0 END) AS tip, "
        + "SUM(CASE WHEN kind='BONUS' THEN amount ELSE 0 END) AS bonus, "
        + "SUM(CASE WHEN kind='WORK_EARNING' THEN 1 ELSE 0 END) AS jobs "
        + "FROM wallet_entries WHERE user_id=:userId AND created_at>=:start AND created_at<:end "
        + "AND kind IN ('WORK_EARNING','TIP','BONUS') "
        + "GROUP BY TO_CHAR(created_at AT TIME ZONE 'Asia/Ho_Chi_Minh','YYYY-MM-DD') ORDER BY calendarDate";
    @Query(value=DAILY_SQL,nativeQuery=true)
    List<DailyTotals> daily(Long userId,Instant start,Instant end);
}
