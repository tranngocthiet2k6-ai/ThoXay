package vn.thoxay.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import vn.thoxay.entity.DeviceToken;
import java.time.Instant;
import java.util.*;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    Optional<DeviceToken> findByTokenHash(String hash);
    List<DeviceToken> findByUserIdAndLastSeenAtAfter(Long user, Instant after);
    void deleteByUserIdAndTokenHash(Long user, String hash);
}
