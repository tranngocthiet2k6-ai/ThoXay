package vn.thoxay.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import java.time.Instant;

@Entity @Getter @Setter
@Table(name = "reputation_events", uniqueConstraints = @UniqueConstraint(columnNames = {"application_id", "type"}),
    indexes = @Index(name = "idx_reputation_user", columnList = "user_id,id"))
public class ReputationEvent {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE) private User user;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "job_id") @OnDelete(action = OnDeleteAction.SET_NULL) private Job job;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "application_id") @OnDelete(action = OnDeleteAction.SET_NULL) private JobApplication application;
    @Column(name = "job_title", nullable = false, length = 200) private String jobTitle;
    @Column(nullable = false, length = 30) private String type;
    @Column(nullable = false) private int delta;
    @Column(name = "score_after", nullable = false) private int scoreAfter;
    @Column(name = "created_at", nullable = false, updatable = false) private Instant createdAt = Instant.now();
}
