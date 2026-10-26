package vn.thoxay.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import vn.thoxay.entity.ReputationEvent;
import java.util.List;

public interface ReputationEventRepository extends JpaRepository<ReputationEvent, Long> {
    boolean existsByApplicationIdAndType(Long application, String type);
    List<ReputationEvent> findByUserIdAndIdLessThanOrderByIdDesc(Long user, Long before, Pageable page);
}
