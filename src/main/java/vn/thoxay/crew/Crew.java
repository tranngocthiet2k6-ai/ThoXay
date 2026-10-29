package vn.thoxay.crew;
import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.User;
@Entity @Table(name="crews") @Getter @Setter
public class Crew {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="leader_id") private User leader;
 @Column(nullable=false,length=100) private String name;
 @Column(nullable=false) private java.time.Instant createdAt=java.time.Instant.now();
}
