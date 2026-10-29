package vn.thoxay.crew;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import vn.thoxay.entity.Job;
@Entity @Table(name="crew_batches",uniqueConstraints=@UniqueConstraint(columnNames={"crew_id","job_id"})) @Getter @Setter
public class CrewBatch {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="crew_id") private Crew crew;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="job_id") @OnDelete(action=OnDeleteAction.CASCADE) private Job job;
 @Column(nullable=false,length=20) private String status="PENDING";
 @Column(nullable=false) private java.time.Instant createdAt=java.time.Instant.now();
}
