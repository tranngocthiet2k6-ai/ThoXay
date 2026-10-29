package vn.thoxay.favorites;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import java.util.*;
public interface SavedWorkerRepository extends JpaRepository<SavedWorker,Long> {
    List<SavedWorker> findByOwnerIdOrderByIdDesc(Long ownerId,Pageable page);
    Optional<SavedWorker> findByOwnerIdAndWorkerId(Long ownerId,Long targetId);
    long countByOwnerId(Long ownerId);
}
