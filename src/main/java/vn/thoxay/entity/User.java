package vn.thoxay.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter @Setter
@org.hibernate.annotations.DynamicUpdate
@org.hibernate.annotations.Check(constraints = "NOT is_verified OR (COALESCE(cccd_front_image, '') LIKE 'https://_%' AND COALESCE(cccd_back_image, '') LIKE 'https://_%')")
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "phone_number", nullable = false, unique = true, length = 15)
    private String phoneNumber;
    @Column(nullable = false, length = 255)
    private String password;
    @Column(name = "full_name", nullable = false, length = 100)
    private String fullName;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30)
    private Role role;
    @Column(name = "is_verified", nullable = false)
    @org.hibernate.annotations.ColumnDefault("false")
    private boolean verified = false;
    @Column(name = "cccd_image", length = 500)
    private String cccdImage;
    @Column(name = "cccd_front_image", length = 500)
    private String cccdFrontImage;
    @Column(name = "cccd_back_image", length = 500)
    private String cccdBackImage;
    @Column(nullable = false)
    private double rating = 5.0;
    @Column(name = "is_active", nullable = false)
    private boolean active = true;
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public boolean hasCompleteCccd() {
        return validCccdImage(cccdFrontImage) && validCccdImage(cccdBackImage);
    }

    @PrePersist @PreUpdate
    private void enforceCccdVerification() {
        if (!hasCompleteCccd()) verified = false;
    }

    private boolean validCccdImage(String image) {
        return image != null && image.matches("https://[^\\s]+");
    }
}
