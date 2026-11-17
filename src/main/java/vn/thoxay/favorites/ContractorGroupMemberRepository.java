package vn.thoxay.favorites;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface ContractorGroupMemberRepository extends JpaRepository<ContractorGroupMember, Long> {
    List<ContractorGroupMember> findByGroupIdOrderByIdAsc(Long id);
    Optional<ContractorGroupMember> findByGroupIdAndSavedWorkerWorkerId(Long groupId, Long workerId);
    long countByGroupId(Long id);
}
