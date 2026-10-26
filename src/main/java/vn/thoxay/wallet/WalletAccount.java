package vn.thoxay.wallet;
import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.User;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

@Entity @Table(name="wallet_accounts") @Getter @Setter
@Check(constraints="main_balance >= 0 AND escrow_balance >= 0 AND held_balance >= 0 AND main_balance + escrow_balance + held_balance <= 1000000000000")
public class WalletAccount {
    @Id @Column(name="user_id") private Long userId;
    @OneToOne(fetch=FetchType.LAZY, optional=false) @MapsId @JoinColumn(name="user_id") @OnDelete(action=OnDeleteAction.CASCADE) private User user;
    @Column(name="main_balance",nullable=false) private long mainBalance;
    @Column(name="escrow_balance",nullable=false) private long escrowBalance;
    @Column(name="held_balance",nullable=false) private long heldBalance;
}
