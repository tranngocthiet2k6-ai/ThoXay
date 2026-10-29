package vn.thoxay.attendance;
import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.Job;
import java.time.Instant;
@Entity @Table(name="attendance_shift_codes") @Getter @Setter
public class ShiftCode {
 @Id private Long jobId;
 @OneToOne(fetch=FetchType.LAZY,optional=false) @MapsId @JoinColumn(name="job_id") @org.hibernate.annotations.OnDelete(action=org.hibernate.annotations.OnDeleteAction.CASCADE) private Job job;
 @Column(nullable=false,length=64) private String tokenHash;
 @Column(nullable=false) private Instant expiresAt;
}
