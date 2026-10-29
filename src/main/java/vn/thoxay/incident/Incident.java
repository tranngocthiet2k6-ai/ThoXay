package vn.thoxay.incident;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import vn.thoxay.entity.*;
import java.time.Instant;
@Entity @Table(name="incidents",uniqueConstraints=@UniqueConstraint(columnNames={"reporter_id","client_request_id"})) @Getter @Setter
public class Incident {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="job_id") @OnDelete(action=OnDeleteAction.SET_NULL) private Job job;
 @Column(nullable=false) private Long originalJobId;
 @Column(nullable=false,length=200) private String jobTitle;
 @Column(nullable=false,length=255) private String jobAddress;
 @Column(nullable=false) private double jobLatitude,jobLongitude;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="reporter_id") @OnDelete(action=OnDeleteAction.SET_NULL) private User reporter;
 @Column(nullable=false,length=100) private String reporterName;
 @Column(nullable=false,length=15) private String reporterPhone;
 @Column(nullable=false,length=80) private String clientRequestId;
 @Column(nullable=false,length=30) private String type;
 @Column(nullable=false,length=30) private String status="NEW";
 @Column(nullable=false,length=2000) private String description;
 private Double reportedLatitude,reportedLongitude;
 @Column(nullable=false,length=1000) private String adminNote="";
 @Column(nullable=false) private Instant createdAt;
 private Instant updatedAt;
 @Version @Column(nullable=false) private Long version;
}
