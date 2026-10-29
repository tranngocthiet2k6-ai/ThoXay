package vn.thoxay.crew;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface CrewMemberRepository extends JpaRepository<CrewMember,Long> {
 List<CrewMember> findByCrewIdOrderByWorkerIdAsc(Long id);
 List<CrewMember> findByWorkerIdOrderByIdDesc(Long id);
 Optional<CrewMember> findByCrewIdAndWorkerId(Long crew,Long worker);
}
