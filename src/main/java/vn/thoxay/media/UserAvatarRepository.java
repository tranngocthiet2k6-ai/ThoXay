package vn.thoxay.media;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface UserAvatarRepository extends JpaRepository<UserAvatar, UUID> {
    Optional<UserAvatar> findByUserId(Long id);
}
