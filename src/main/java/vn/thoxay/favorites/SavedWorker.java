package vn.thoxay.favorites;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import vn.thoxay.entity.*;
import java.time.Instant;

@Entity @Table(name="saved_workers",uniqueConstraints=@UniqueConstraint(columnNames={"owner_id","worker_id"}))
@Getter @Setter
public class SavedWorker {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="owner_id") @OnDelete(action=OnDeleteAction.CASCADE) private User owner;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="worker_id") @OnDelete(action=OnDeleteAction.CASCADE) private User worker;
    @Column(nullable=false) private Instant createdAt=Instant.now();
}
