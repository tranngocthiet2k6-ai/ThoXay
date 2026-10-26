package vn.thoxay.repository;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import vn.thoxay.entity.AppNotification;
import java.time.Instant;
import java.util.*;

public interface NotificationRepository extends JpaRepository<AppNotification, Long> {
    boolean existsByEventKey(String eventKey);
    List<AppNotification> findByRecipientIdAndIdLessThanOrderByIdDesc(Long recipient, Long before, Pageable page);
    long countByRecipientIdAndReadAtIsNull(Long recipient);
    @Modifying @Query("update AppNotification n set n.readAt = :now where n.recipient.id = :user and n.readAt is null and (:id is null or n.id = :id)")
    int markRead(@Param("user") Long user, @Param("id") Long id, @Param("now") Instant now);
    boolean existsByIdAndRecipientId(Long id, Long user);
    @Query("select n.id from AppNotification n where n.pushStatus = 'PENDING' and n.nextAttemptAt <= :now order by n.id")
    List<Long> due(@Param("now") Instant now, Pageable page);
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select n from AppNotification n where n.id = :id")
    Optional<AppNotification> locked(@Param("id") Long id);
}
