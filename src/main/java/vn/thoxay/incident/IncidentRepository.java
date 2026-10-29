package vn.thoxay.incident;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;
import java.util.*;
public interface IncidentRepository extends JpaRepository<Incident,Long>{
 @Query("select i.originalJobId from Incident i where i.id=:id") Optional<Long> originalJob(@Param("id")Long id);
 Optional<Incident> findByReporterIdAndClientRequestId(Long reporter,String request);
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select i from Incident i where i.id=:id") Optional<Incident> locked(@Param("id") Long id);
 @Query("select i from Incident i where i.reporter.id=:user and i.id<:before and (:job is null or i.originalJobId=:job) order by i.id desc") List<Incident> mine(@Param("user") Long user,@Param("job") Long job,@Param("before") Long before,Pageable page);
 @Query("select i from Incident i where i.status=:status and (:type='' or i.type=:type) and (:q='' or lower(i.jobTitle) like concat('%',:q,'%') or lower(i.reporterName) like concat('%',:q,'%') or lower(i.description) like concat('%',:q,'%')) order by case when i.type='SOS' then 0 else 1 end,i.id desc") List<Incident> queue(@Param("status") String status,@Param("type") String type,@Param("q") String query,Pageable page);
 long countByStatusNot(String status);
 long countByTypeAndStatusNot(String type,String status);
}
