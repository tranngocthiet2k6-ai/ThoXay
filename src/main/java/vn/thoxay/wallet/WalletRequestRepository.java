package vn.thoxay.wallet;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;
import java.util.*;
public interface WalletRequestRepository extends JpaRepository<WalletRequest,Long> {
    Optional<WalletRequest> findByUserIdAndClientRequestId(Long userId,String clientRequestId);
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select r from WalletRequest r where r.id=:id") Optional<WalletRequest> lock(Long id);
    List<WalletRequest> findByUserIdAndIdLessThanOrderByIdDesc(Long userId,Long before,Pageable page);
    List<WalletRequest> findByStatusAndIdLessThanOrderByIdDesc(WalletRequest.Status status,Long before,Pageable page);
    boolean existsByExternalReference(String reference);
}
