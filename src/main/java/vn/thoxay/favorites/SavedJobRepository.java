package vn.thoxay.favorites;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import java.util.*;
public interface SavedJobRepository extends JpaRepository<SavedJob,Long> {
    List<SavedJob> findByOwnerIdOrderByIdDesc(Long ownerId,Pageable page);
    Optional<SavedJob> findByOwnerIdAndJobId(Long ownerId,Long targetId);
    long countByOwnerId(Long ownerId);
}
