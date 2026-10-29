package vn.thoxay.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import vn.thoxay.entity.Message;

public interface MessageRepository extends JpaRepository<Message, Long> {
    // Identical ACL for inbox and badge: accepted pair, active accounts, actual worker role.
    String ACTIVE_PAIR = " FROM messages m JOIN jobs j ON j.id=m.job_id "
        + "JOIN job_applications a ON a.job_id=m.job_id AND a.worker_id=CASE WHEN m.sender_id=j.contractor_id THEN m.recipient_id ELSE m.sender_id END AND a.status='ACCEPTED' "
        + "JOIN users w ON w.id=a.worker_id AND w.is_active=TRUE AND w.role='ROLE_WORKER' "
        + "JOIN users c ON c.id=j.contractor_id AND c.is_active=TRUE "
        + "LEFT JOIN chat_read_states r ON r.job_id=m.job_id AND r.user_id=:actor AND r.peer_id=CASE WHEN m.sender_id=:actor THEN m.recipient_id ELSE m.sender_id END "
        + "WHERE (m.sender_id=:actor OR m.recipient_id=:actor) AND (m.sender_id=j.contractor_id OR m.recipient_id=j.contractor_id) ";
    interface InboxRow { Long getLatestId(); Long getUnreadCount(); }
    @Query(value = "SELECT MAX(m.id) AS latestId, SUM(CASE WHEN m.recipient_id=:actor AND m.id>COALESCE(r.last_read_message_id,0) THEN 1 ELSE 0 END) AS unreadCount "
        + ACTIVE_PAIR + "GROUP BY m.job_id,CASE WHEN m.sender_id=:actor THEN m.recipient_id ELSE m.sender_id END "
        + "HAVING MAX(m.id)<:before ORDER BY MAX(m.id) DESC", nativeQuery = true)
    List<InboxRow> inbox(@Param("actor") Long actor, @Param("before") Long before, Pageable page);
    @Query(value = "SELECT COUNT(*) " + ACTIVE_PAIR + "AND m.recipient_id=:actor AND m.id>COALESCE(r.last_read_message_id,0)", nativeQuery = true)
    long unread(@Param("actor") Long actor);
    @EntityGraph(attributePaths = {"job", "job.contractor", "sender", "recipient"})
    List<Message> findByIdIn(List<Long> ids);
    Optional<Message> findBySenderIdAndClientMessageId(Long senderId, String clientMessageId);

    @Query("select m from Message m where m.job.id = :job and "
        + "((m.sender.id = :actor and m.recipient.id = :peer) or (m.sender.id = :peer and m.recipient.id = :actor)) "
        + "and m.id < :before order by m.id desc")
    List<Message> older(@Param("job") Long job, @Param("actor") Long actor, @Param("peer") Long peer,
        @Param("before") long before, Pageable page);

    @Query("select m from Message m where m.job.id = :job and "
        + "((m.sender.id = :actor and m.recipient.id = :peer) or (m.sender.id = :peer and m.recipient.id = :actor)) "
        + "and m.id > :after order by m.id asc")
    List<Message> newer(@Param("job") Long job, @Param("actor") Long actor, @Param("peer") Long peer,
        @Param("after") long after, Pageable page);
}
