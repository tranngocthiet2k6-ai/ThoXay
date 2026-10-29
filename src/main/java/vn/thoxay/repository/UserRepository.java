package vn.thoxay.repository;

import vn.thoxay.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, Long> {
    java.util.List<User> findByRoleAndActiveTrueAndCompletedJobsGreaterThan(vn.thoxay.entity.Role role, int completed, org.springframework.data.domain.Pageable page);
    java.util.List<User> findByRoleAndActiveTrue(vn.thoxay.entity.Role role);
    Optional<User> findByPhoneNumber(String phoneNumber);
    boolean existsByPhoneNumber(String phoneNumber);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from User u where u.id = :id")
    Optional<User> findLockedById(@Param("id") Long id);
}
