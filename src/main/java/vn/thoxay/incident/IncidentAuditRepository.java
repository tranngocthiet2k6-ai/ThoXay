package vn.thoxay.incident;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import java.util.*;
public interface IncidentAuditRepository extends JpaRepository<IncidentAudit,Long>{List<IncidentAudit> findByIncidentIdOrderByIdDesc(Long id,Pageable page);}
