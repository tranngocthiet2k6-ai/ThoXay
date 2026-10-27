package vn.thoxay.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "users")
@Getter @Setter
@org.hibernate.annotations.DynamicUpdate
@org.hibernate.annotations.Check(constraints = "NOT is_verified OR ((COALESCE(cccd_front_image, '') LIKE 'https://_%' OR COALESCE(cccd_front_image, '') LIKE '/admin/kyc/images/%') AND (COALESCE(cccd_back_image, '') LIKE 'https://_%' OR COALESCE(cccd_back_image, '') LIKE '/admin/kyc/images/%'))")
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "phone_number", nullable = false, unique = true, length = 15)
    private String phoneNumber;
    @Column(nullable = false, length = 255)
    private String password;
    @Column(name = "full_name", nullable = false, length = 100)
    private String fullName;
    @Column(name = "date_of_birth") private LocalDate dateOfBirth;
    @Column(name = "experience_years", nullable = false) @org.hibernate.annotations.ColumnDefault("0")
    private int experienceYears;
    @Column(name = "experience_summary", length = 2000) private String experienceSummary = "";
    @ElementCollection @CollectionTable(name = "user_skills", joinColumns = @JoinColumn(name = "user_id", nullable = false))
    @OrderColumn(name = "sort_order") @Column(name = "skill", nullable = false, length = 50)
    @org.hibernate.annotations.OnDelete(action = org.hibernate.annotations.OnDeleteAction.CASCADE)
    private List<String> skills = new ArrayList<>();
    @ElementCollection @CollectionTable(name = "user_project_images", joinColumns = @JoinColumn(name = "user_id", nullable = false))
    @OrderColumn(name = "sort_order") @Column(name = "image_url", nullable = false, length = 500)
    @org.hibernate.annotations.OnDelete(action = org.hibernate.annotations.OnDeleteAction.CASCADE)
    private List<String> projectImages = new ArrayList<>();
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
    @Column(name = "reputation_score", nullable = false) @org.hibernate.annotations.ColumnDefault("100")
    private int reputationScore = 100;
    @Column(name = "completed_jobs", nullable = false) @org.hibernate.annotations.ColumnDefault("0")
    private int completedJobs;
    @Column(name = "cancelled_jobs", nullable = false) @org.hibernate.annotations.ColumnDefault("0")
    private int cancelledJobs;
    @Enumerated(EnumType.STRING) @Column(name = "worker_tier", nullable = false, length = 12) @org.hibernate.annotations.ColumnDefault("'SILVER'")
    private WorkerTier workerTier = WorkerTier.SILVER;
    @Column(name = "is_active", nullable = false)
    private boolean active = true;
    @Column(name = "is_available", nullable = false) @org.hibernate.annotations.ColumnDefault("true")
    private boolean available = true;
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public boolean hasCompleteCccd() {
        return validCccdImage(cccdFrontImage) && validCccdImage(cccdBackImage);
    }

    @PrePersist @PreUpdate
    private void enforceCccdVerification() {
        if (!hasCompleteCccd()) verified = false;
        recalculateTier();
    }
    public void recalculateTier() { workerTier = WorkerTier.of(this); }

    public static boolean validCccdImage(String image) {
        return image != null && (image.matches("https://[^\\s]+")
            || image.matches("/admin/kyc/images/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"));
    }
}
