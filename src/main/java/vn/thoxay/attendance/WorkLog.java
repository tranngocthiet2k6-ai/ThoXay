package vn.thoxay.attendance;
import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;
@Entity @Table(name="work_logs") @Getter @Setter
public class WorkLog {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @OneToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="attendance_id",nullable=false,unique=true) @org.hibernate.annotations.OnDelete(action=org.hibernate.annotations.OnDeleteAction.CASCADE) private AttendanceRecord attendance;
 @Column(nullable=false,length=1000) private String caption="";
 @Column(nullable=false,columnDefinition="bytea") private byte[] photo;
 @Column(nullable=false,length=30) private String status="PENDING";
 @Column(nullable=false,length=500) private String feedback="";
 @Column(nullable=false) private Instant createdAt=Instant.now();
 private Instant reviewedAt;
 @Version @Column(nullable=false) private Long version;
}
