package vn.thoxay.incident;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import vn.thoxay.entity.User;
import java.time.Instant;
@Entity @Table(name="incident_audit") @Getter @Setter
public class IncidentAudit {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="incident_id") @OnDelete(action=OnDeleteAction.CASCADE) private Incident incident;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="actor_id") @OnDelete(action=OnDeleteAction.SET_NULL) private User actor;
 @Column(nullable=false,length=30) private String status;
 @Column(nullable=false,length=1000) private String note;
 @Column(nullable=false) private Instant createdAt;
}
