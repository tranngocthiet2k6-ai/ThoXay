package vn.thoxay.attendance;
import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.JobApplication;
import java.time.*;
@Entity @Table(name="attendance_records",uniqueConstraints=@UniqueConstraint(columnNames={"application_id","work_day"})) @Getter @Setter
public class AttendanceRecord {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="application_id",nullable=false) @org.hibernate.annotations.OnDelete(action=org.hibernate.annotations.OnDeleteAction.CASCADE) private JobApplication application;
 @Column(nullable=false) private LocalDate workDay;
 @Column(nullable=false) private Instant checkedInAt;
 private Instant checkedOutAt;
 @Column(nullable=false,length=10) private String checkinMethod;
 @Column(length=10) private String checkoutMethod;
 private Double checkinLatitude,checkinLongitude,checkinAccuracy,checkoutLatitude,checkoutLongitude,checkoutAccuracy;
}
