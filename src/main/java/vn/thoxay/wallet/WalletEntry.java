package vn.thoxay.wallet;
import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.User;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import java.time.Instant;

@Entity @Table(name="wallet_entries",uniqueConstraints=@UniqueConstraint(columnNames="reference"),indexes=@Index(name="idx_wallet_entry_user",columnList="user_id,id")) @Getter @Setter
@org.hibernate.annotations.Check(constraints="amount > 0 AND main_after >= 0 AND escrow_after >= 0 AND held_after >= 0")
public class WalletEntry {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id",nullable=false) @OnDelete(action=OnDeleteAction.CASCADE) private User user;
    @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="request_id") @OnDelete(action=OnDeleteAction.SET_NULL) private WalletRequest request;
    @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="payment_id") @OnDelete(action=OnDeleteAction.SET_NULL) private JobPayment payment;
    @Column(nullable=false,length=30) private String kind;
    @Column(nullable=false) private long amount;
    @Column(name="main_delta",nullable=false) private long mainDelta;
    @Column(name="escrow_delta",nullable=false) private long escrowDelta;
    @Column(name="held_delta",nullable=false) private long heldDelta;
    @Column(name="main_after",nullable=false) private long mainAfter;
    @Column(name="escrow_after",nullable=false) private long escrowAfter;
    @Column(name="held_after",nullable=false) private long heldAfter;
    @Column(nullable=false,length=150) private String reference;
    @Column(nullable=false,length=250) private String description;
    @Column(name="created_at",nullable=false,updatable=false) private Instant createdAt=Instant.now();
}
