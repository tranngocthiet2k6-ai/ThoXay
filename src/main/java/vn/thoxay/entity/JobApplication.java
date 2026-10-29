package vn.thoxay.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "job_applications", uniqueConstraints = @UniqueConstraint(columnNames = {"job_id", "worker_id"}))
@Getter @Setter
@org.hibernate.annotations.Check(constraints = "worker_rating IS NULL OR (worker_rating BETWEEN 1 AND 5 AND status = 'ACCEPTED')")
public class JobApplication {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "job_id", nullable = false)
    private Job job;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "worker_id", nullable = false)
    private User worker;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30)
    private ApplicationStatus status = ApplicationStatus.PENDING;
    @Column(name = "worker_rating")
    private Integer workerRating;
    @Column(name = "reviewed_at") private java.time.Instant reviewedAt;
    @Column(name = "cancellation_reason", length = 500) private String cancellationReason;
    @Column(name = "cancelled_at") private java.time.Instant cancelledAt;
    @Column(name = "cancellation_penalty", nullable = false) @org.hibernate.annotations.ColumnDefault("0")
    private int cancellationPenalty;
    @Column(name = "applied_at", nullable = false, updatable = false)
    private LocalDateTime appliedAt = LocalDateTime.now();
    @Column(name = "proposed_daily_rate") private Long proposedDailyRate;
    @Column(name = "wage_note", length = 500) private String wageNote;
    @Column(name = "agreed_daily_rate") private Long agreedDailyRate;
    @Column(name = "consent_version") private Integer consentVersion;
    @Column(name = "accepted_terms_at") private java.time.Instant acceptedTermsAt;
    @Column(name = "contract_snapshot", columnDefinition = "TEXT") private String contractSnapshot;
    @Column(name = "contract_hash", length = 64) private String contractHash;
    @Column(name = "contractor_confirmed_at") private java.time.Instant contractorConfirmedAt;
}
