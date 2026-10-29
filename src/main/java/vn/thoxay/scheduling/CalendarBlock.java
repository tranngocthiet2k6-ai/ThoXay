package vn.thoxay.scheduling;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import vn.thoxay.entity.User;

@Entity @Table(name="worker_calendar_blocks", uniqueConstraints=@UniqueConstraint(columnNames={"worker_id","work_day"}))
@Getter @Setter
public class CalendarBlock {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="worker_id",nullable=false)
    @org.hibernate.annotations.OnDelete(action=org.hibernate.annotations.OnDeleteAction.CASCADE)
    private User worker;
    @Column(name="work_day",nullable=false) private LocalDate day;
    @Column(nullable=false,length=200) private String note="";
}
