package vn.thoxay.wallet;
import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.User;
@Entity @Table(name="receiving_bank_audit") @Getter @Setter
public class BankSettingsAudit {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="actor_id") @org.hibernate.annotations.OnDelete(action=org.hibernate.annotations.OnDeleteAction.SET_NULL) private User actor;
 @Column(nullable=false) private boolean enabled;
 @Column(length=6) private String bankBin;
 @Column(length=100) private String bankName;
 @Column(length=19) private String accountNo;
 @Column(length=100) private String accountName;
 @Column(nullable=false) private long revision;
 @Column(nullable=false) private java.time.Instant changedAt;
}
