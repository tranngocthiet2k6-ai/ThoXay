package vn.thoxay.chat;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
public interface ChatReadStateRepository extends JpaRepository<ChatReadState, Long> {
    Optional<ChatReadState> findByUserIdAndJobIdAndPeerId(Long userId, Long jobId, Long peerId);
}
