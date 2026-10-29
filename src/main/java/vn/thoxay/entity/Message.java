package vn.thoxay.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import java.time.Instant;

@Entity @Getter @Setter
@Table(name = "messages", uniqueConstraints = @UniqueConstraint(columnNames = {"sender_id", "client_message_id"}),
    indexes = @Index(name = "idx_messages_conversation", columnList = "job_id,sender_id,recipient_id,id"))
@org.hibernate.annotations.Check(constraints = "sender_id <> recipient_id AND length(trim(content)) > 0")
public class Message {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "sender_id", nullable = false)
    private User sender;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "job_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Job job;
    @Column(nullable = false, length = 2000)
    private String content;
    @Column(nullable = false, length = 16)
    private String kind = "TEXT";
    private Double latitude;
    private Double longitude;
    @Column(name = "image_hash", length = 64)
    private String imageHash;
    @Column(name = "client_message_id", nullable = false, length = 64)
    private String clientMessageId;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
