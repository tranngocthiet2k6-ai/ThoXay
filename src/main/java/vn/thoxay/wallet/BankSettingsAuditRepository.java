package vn.thoxay.wallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import java.util.List;
public interface BankSettingsAuditRepository extends JpaRepository<BankSettingsAudit,Long>{List<BankSettingsAudit> findAllByOrderByIdDesc(Pageable page);}
