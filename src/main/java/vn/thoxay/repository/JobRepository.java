package vn.thoxay.repository;

import vn.thoxay.entity.Job;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface JobRepository extends JpaRepository<Job, Long> {
    List<Job> findByContractorIdOrderByCreatedAtDesc(Long contractorId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select j from Job j where j.id = :id")
    Optional<Job> findLockedById(@Param("id") Long id);

    @Query(value = """
        SELECT j.* FROM jobs j JOIN users u ON u.id = j.contractor_id
        WHERE j.status = 'OPEN' AND u.is_active = TRUE
        AND 6371.0 * 2 * ASIN(SQRT(LEAST(1.0, GREATEST(0.0,
          POWER(SIN(RADIANS(j.latitude - :lat) / 2), 2)
          + COS(RADIANS(:lat)) * COS(RADIANS(j.latitude))
          * POWER(SIN(RADIANS(j.longitude - :lng) / 2), 2))))) <= :radiusKm
        ORDER BY 6371.0 * 2 * ASIN(SQRT(LEAST(1.0, GREATEST(0.0,
          POWER(SIN(RADIANS(j.latitude - :lat) / 2), 2)
          + COS(RADIANS(:lat)) * COS(RADIANS(j.latitude))
          * POWER(SIN(RADIANS(j.longitude - :lng) / 2), 2))))), j.id DESC
        """, nativeQuery = true)
    List<Job> findNearby(@Param("lat") double lat, @Param("lng") double lng,
                         @Param("radiusKm") double radiusKm);
}
