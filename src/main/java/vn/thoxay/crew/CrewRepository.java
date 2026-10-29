package vn.thoxay.crew;
import org.springframework.data.jpa.repository.*;
import jakarta.persistence.LockModeType;
import org.springframework.data.repository.query.Param;
import java.util.Optional;
public interface CrewRepository extends JpaRepository<Crew,Long> {
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select c from Crew c where c.id=:id") Optional<Crew> locked(@Param("id") Long id);
 long countByLeaderId(Long id);
}
