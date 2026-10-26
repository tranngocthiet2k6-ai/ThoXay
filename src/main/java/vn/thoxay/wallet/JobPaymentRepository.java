package vn.thoxay.wallet;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface JobPaymentRepository extends JpaRepository<JobPayment,Long> {
    Optional<JobPayment> findByApplicationId(Long id);
    List<JobPayment> findByJobIdOrderByIdDesc(Long id);
}
