package vn.thoxay.kyc;

import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.User;
import java.util.UUID;

/** Private image bytes, never serialized by a REST endpoint. */
@Entity @Table(name = "kyc_images", indexes = @Index(name = "idx_kyc_images_user", columnList = "user_id"))
@Getter @Setter @NoArgsConstructor
public class KycImage {
    @Id private UUID id = UUID.randomUUID();
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    @org.hibernate.annotations.OnDelete(action = org.hibernate.annotations.OnDeleteAction.CASCADE)
    private User user;
    @Column(nullable = false, columnDefinition = "bytea")
    private byte[] content;
    public String url() { return "/admin/kyc/images/" + id; }
}
