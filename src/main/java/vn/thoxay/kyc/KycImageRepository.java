package vn.thoxay.kyc;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import java.util.UUID;

public interface KycImageRepository extends JpaRepository<KycImage, UUID> {
    @Modifying @Query("delete from KycImage i where i.user.id = :userId")
    void deleteForUser(Long userId);
}
