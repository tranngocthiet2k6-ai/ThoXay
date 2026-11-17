package vn.thoxay.favorites;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

@Entity @Table(name = "contractor_group_members", uniqueConstraints = @UniqueConstraint(columnNames = {"group_id", "saved_worker_id"}))
@Getter @Setter
public class ContractorGroupMember {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "group_id")
    @OnDelete(action = OnDeleteAction.CASCADE) private ContractorGroup group;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "saved_worker_id")
    @OnDelete(action = OnDeleteAction.CASCADE) private SavedWorker savedWorker;
}
