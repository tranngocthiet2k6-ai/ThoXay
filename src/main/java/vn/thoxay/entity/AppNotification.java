package vn.thoxay.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import java.time.Instant;

@Entity @Getter @Setter
@Table(name = "notifications", indexes = {
    @Index(name = "idx_notifications_recipient", columnList = "recipient_id,id"),
    @Index(name = "idx_notifications_outbox", columnList = "push_status,next_attempt_at")})
public class AppNotification {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "recipient_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE) private User recipient;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "job_id")
    @OnDelete(action = OnDeleteAction.SET_NULL) private Job job;
    @Column(name = "event_key", nullable = false, unique = true, length = 200) private String eventKey;
    @Column(nullable = false, length = 40) private String type;
    @Column(nullable = false, length = 120) private String title;
    @Column(nullable = false, length = 500) private String body;
    @Column(name = "created_at", nullable = false, updatable = false) private Instant createdAt = Instant.now();
    @Column(name = "read_at") private Instant readAt;
    @Column(name = "push_status", nullable = false, length = 20) private String pushStatus = "DISABLED";
    @Column(name = "push_attempts", nullable = false) private int pushAttempts;
    @Column(name = "next_attempt_at", nullable = false) private Instant nextAttemptAt = Instant.now();
}
