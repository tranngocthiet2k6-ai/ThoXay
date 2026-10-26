package vn.thoxay.wallet;
import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import java.time.Instant;

@Entity @Table(name="job_payments",uniqueConstraints=@UniqueConstraint(columnNames="application_id")) @Getter @Setter
@org.hibernate.annotations.Check(constraints="work_days BETWEEN 1 AND 365 AND daily_rate > 0 AND tip >= 0 AND bonus >= 0 AND base = work_days * daily_rate AND total = base + tip + bonus")
public class JobPayment {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="application_id") @OnDelete(action=OnDeleteAction.SET_NULL) private JobApplication application;
    @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="job_id") @OnDelete(action=OnDeleteAction.SET_NULL) private Job job;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="contractor_id",nullable=false) @OnDelete(action=OnDeleteAction.CASCADE) private User contractor;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="worker_id",nullable=false) @OnDelete(action=OnDeleteAction.CASCADE) private User worker;
    @Column(name="job_title",nullable=false,length=200) private String jobTitle;
    @Column(name="work_days",nullable=false) private int workDays;
    @Column(name="daily_rate",nullable=false) private long dailyRate;
    @Column(nullable=false) private long base;
    @Column(nullable=false) private long tip;
    @Column(nullable=false) private long bonus;
    @Column(nullable=false) private long total;
    @Column(name="created_at",nullable=false,updatable=false) private Instant createdAt=Instant.now();
}
