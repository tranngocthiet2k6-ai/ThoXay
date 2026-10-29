package vn.thoxay.favorites;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import vn.thoxay.entity.*;
import java.time.Instant;

@Entity @Table(name="saved_jobs",uniqueConstraints=@UniqueConstraint(columnNames={"owner_id","job_id"}))
@Getter @Setter
public class SavedJob {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="owner_id") @OnDelete(action=OnDeleteAction.CASCADE) private User owner;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="job_id") @OnDelete(action=OnDeleteAction.CASCADE) private Job job;
    @Column(nullable=false) private Instant createdAt=Instant.now();
}
