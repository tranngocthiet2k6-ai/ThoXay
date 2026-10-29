package vn.thoxay.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity @Table(name = "jobs") @Getter @Setter
public class Job {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "contractor_id", nullable = false)
    private User contractor;
    @Column(nullable = false, length = 200)
    private String title;
    @Column(columnDefinition = "TEXT")
    private String description;
    @Column(name = "job_type", nullable = false, length = 50)
    private String jobType;
    @Column(name = "salary_per_day", nullable = false)
    private double salaryPerDay;
    @Column(nullable = false, length = 255)
    private String address;
    @Column(nullable = false)
    private double latitude;
    @Column(nullable = false)
    private double longitude;
    @Column(name = "required_workers", nullable = false)
    private int requiredWorkers;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30)
    private JobStatus status = JobStatus.OPEN;
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
    @Column(name = "starts_on") private java.time.LocalDate startsOn;
    @Column(name = "ends_on") private java.time.LocalDate endsOn;
    @Column(name = "terms_version", nullable = false) @org.hibernate.annotations.ColumnDefault("1")
    private int termsVersion = 1;
    @Column(nullable=false) @org.hibernate.annotations.ColumnDefault("false") private boolean attendanceRequired;
}
