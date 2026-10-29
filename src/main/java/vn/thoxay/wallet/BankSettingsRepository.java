package vn.thoxay.wallet;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import java.util.Optional;
public interface BankSettingsRepository extends JpaRepository<BankSettings,Long>{
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select b from BankSettings b where b.id=1") Optional<BankSettings> locked();
}
