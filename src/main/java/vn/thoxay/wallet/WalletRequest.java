package vn.thoxay.wallet;
import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.User;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import java.time.Instant;

@Entity @Table(name="wallet_requests", uniqueConstraints={@UniqueConstraint(columnNames={"user_id","client_request_id"}),@UniqueConstraint(columnNames="external_reference")}) @Getter @Setter
@org.hibernate.annotations.Check(constraints="amount BETWEEN 1000 AND 100000000")
public class WalletRequest {
    public enum Kind { TOP_UP, WITHDRAW }
    public enum Status { PENDING, APPROVED, REJECTED }
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id",nullable=false) @OnDelete(action=OnDeleteAction.CASCADE) private User user;
    @Enumerated(EnumType.STRING) @Column(nullable=false,length=15) private Kind kind;
    @Enumerated(EnumType.STRING) @Column(nullable=false,length=15) private Status status=Status.PENDING;
    @Column(nullable=false) private long amount;
    @Column(name="client_request_id",nullable=false,length=80) private String clientRequestId;
    @Column(name="transfer_reference",length=200) private String transferReference;
    @Column(name="bank_name",length=100) private String bankName;
    @Column(name="bank_account",length=34) private String bankAccount;
    @Column(name="account_name",length=100) private String accountName;
    @Column(name="external_reference",length=100) private String externalReference;
    @Column(length=300) private String note;
    @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="processed_by") @OnDelete(action=OnDeleteAction.SET_NULL) private User processedBy;
    @Column(name="created_at",nullable=false,updatable=false) private Instant createdAt=Instant.now();
    @Column(name="processed_at") private Instant processedAt;
}
