package vn.thoxay.media;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import vn.thoxay.entity.User;
import java.util.UUID;

@Entity @Table(name="user_avatars") @Getter @Setter
public class UserAvatar {
    @Id private UUID id = UUID.randomUUID();
    @ManyToOne(fetch=FetchType.LAZY, optional=false)
    @JoinColumn(name="user_id", nullable=false, unique=true)
    @org.hibernate.annotations.OnDelete(action=org.hibernate.annotations.OnDeleteAction.CASCADE)
    private User user;
    @Column(nullable=false, columnDefinition="bytea") private byte[] content;
}
