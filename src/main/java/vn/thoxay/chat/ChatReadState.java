package vn.thoxay.chat;

import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.*;

@Entity @Table(name = "chat_read_states", uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "job_id", "peer_id"}))
@Getter @Setter
public class ChatReadState {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id", nullable = false)
    @org.hibernate.annotations.OnDelete(action = org.hibernate.annotations.OnDeleteAction.CASCADE) private User user;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "peer_id", nullable = false)
    @org.hibernate.annotations.OnDelete(action = org.hibernate.annotations.OnDeleteAction.CASCADE) private User peer;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "job_id", nullable = false)
    @org.hibernate.annotations.OnDelete(action = org.hibernate.annotations.OnDeleteAction.CASCADE) private Job job;
    @Column(name = "last_read_message_id", nullable = false) private Long lastReadMessageId = 0L;
}
