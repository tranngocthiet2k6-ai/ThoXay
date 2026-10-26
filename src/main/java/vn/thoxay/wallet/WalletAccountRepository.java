package vn.thoxay.wallet;
import org.springframework.data.jpa.repository.*;
import jakarta.persistence.LockModeType;
import java.util.Optional;
public interface WalletAccountRepository extends JpaRepository<WalletAccount,Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select w from WalletAccount w where w.userId=:id") Optional<WalletAccount> lock(Long id);
}
