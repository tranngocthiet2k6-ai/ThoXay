package vn.thoxay.wallet;
import jakarta.persistence.*;
import lombok.*;
@Entity @Table(name="receiving_bank_settings") @Getter @Setter
public class BankSettings {
 @Id private Long id=1L;
 @Column(nullable=false) private boolean enabled;
 @Column(length=6) private String bankBin;
 @Column(length=100) private String bankName;
 @Column(length=19) private String accountNo;
 @Column(length=100) private String accountName;
 @Version @Column(nullable=false) private Long version;
}
