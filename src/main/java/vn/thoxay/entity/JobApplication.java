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
    @Column(name = "applied_at", nullable = false, updatable = false)
    private LocalDateTime appliedAt = LocalDateTime.now();
}
