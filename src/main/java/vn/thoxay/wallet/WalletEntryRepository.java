package vn.thoxay.wallet;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.domain.Pageable;
import java.time.Instant;
import java.util.*;
public interface WalletEntryRepository extends JpaRepository<WalletEntry,Long> {
    Optional<WalletEntry> findByReference(String reference);
    List<WalletEntry> findByUserIdAndIdLessThanOrderByIdDesc(Long userId,Long before,Pageable page);
    interface Totals { Long getBase(); Long getTip(); Long getBonus(); Long getJobs(); }
    @Query("""
      select coalesce(sum(case when e.kind='WORK_EARNING' then e.amount else 0 end),0) as base,
      coalesce(sum(case when e.kind='TIP' then e.amount else 0 end),0) as tip,
      coalesce(sum(case when e.kind='BONUS' then e.amount else 0 end),0) as bonus,
      sum(case when e.kind='WORK_EARNING' then 1 else 0 end) as jobs
      from WalletEntry e where e.user.id=:userId and e.createdAt>=:start and e.createdAt<:end
      and e.kind in ('WORK_EARNING','TIP','BONUS')
      """) Totals earnings(Long userId,Instant start,Instant end);
}
