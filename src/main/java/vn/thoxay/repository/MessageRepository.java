package vn.thoxay.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import vn.thoxay.entity.Message;

public interface MessageRepository extends JpaRepository<Message, Long> {
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
