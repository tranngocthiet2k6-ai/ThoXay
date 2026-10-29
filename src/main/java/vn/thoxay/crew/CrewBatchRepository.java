package vn.thoxay.crew;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface CrewBatchRepository extends JpaRepository<CrewBatch,Long> {
 @org.springframework.data.jpa.repository.Query("select b.job.id from CrewBatch b where b.id=:id")
 Optional<Long> findJobId(@org.springframework.data.repository.query.Param("id") Long id);
 boolean existsByCrewIdAndJobId(Long crew,Long job);
 List<CrewBatch> findByJobIdOrderByIdDesc(Long job);
}
