package vn.thoxay.crew;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import vn.thoxay.entity.User;
@Entity @Table(name="crew_members",uniqueConstraints=@UniqueConstraint(columnNames={"crew_id","worker_id"})) @Getter @Setter
public class CrewMember {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="crew_id") @OnDelete(action=OnDeleteAction.CASCADE) private Crew crew;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="worker_id") @OnDelete(action=OnDeleteAction.CASCADE) private User worker;
 @Column(nullable=false,length=20) private String status="INVITED";
 private java.time.Instant confirmedAt;
}
