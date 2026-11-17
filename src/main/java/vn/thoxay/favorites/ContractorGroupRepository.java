package vn.thoxay.favorites;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import java.util.*;

public interface ContractorGroupRepository extends JpaRepository<ContractorGroup, Long> {
    List<ContractorGroup> findByOwnerIdOrderByIdDesc(Long id);
    long countByOwnerId(Long id);
    boolean existsByOwnerIdAndNameIgnoreCase(Long id, String name);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select g from ContractorGroup g where g.id = :id and g.owner.id = :ownerId")
    Optional<ContractorGroup> owned(Long id, Long ownerId);
}
