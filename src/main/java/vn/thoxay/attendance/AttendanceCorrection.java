package vn.thoxay.attendance;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

/** Append a record for each correction; preserve the original GPS/QR evidence. */
@Entity @Table(name="attendance_corrections") @Getter @Setter
public class AttendanceCorrection {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="attendance_id",nullable=false)
 @org.hibernate.annotations.OnDelete(action=org.hibernate.annotations.OnDeleteAction.CASCADE)
 private AttendanceRecord attendance;
 @Column(nullable=false) private Instant originalCheckedOutAt;
 @Column(nullable=false,length=10) private String originalMethod;
 private Double originalLatitude,originalLongitude,originalAccuracy;
 @Column(nullable=false,length=30) private String status;
 @Column(nullable=false,length=500) private String reason;
 @Column(nullable=false) private Instant requestedAt;
 @Column(nullable=false) private Long requestedBy;
 private Instant reviewedAt;
 private Long reviewedBy;
 @Column(nullable=false,length=500) private String feedback="";
 private Instant correctedCheckedOutAt;
}
