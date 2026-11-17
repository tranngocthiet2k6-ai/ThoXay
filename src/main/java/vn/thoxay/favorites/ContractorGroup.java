package vn.thoxay.favorites;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import vn.thoxay.entity.User;

@Entity @Table(name = "contractor_groups", uniqueConstraints = @UniqueConstraint(columnNames = {"owner_id", "name"}))
@Getter @Setter
public class ContractorGroup {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "owner_id")
    @OnDelete(action = OnDeleteAction.CASCADE) private User owner;
    @Column(nullable = false, length = 80) private String name;
}
