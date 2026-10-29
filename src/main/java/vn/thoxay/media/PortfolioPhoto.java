package vn.thoxay.media;
import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.User;
import java.util.UUID;
import java.time.Instant;
@Entity @Table(name="portfolio_photos") @Getter @Setter
public class PortfolioPhoto {
 @Id private UUID id=UUID.randomUUID();
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="owner_id",nullable=false) @org.hibernate.annotations.OnDelete(action=org.hibernate.annotations.OnDeleteAction.CASCADE) private User owner;
 @Column(nullable=false,length=160) private String caption="";
 @Column(nullable=false,columnDefinition="bytea") private byte[] content;
 @Column(nullable=false) private Instant createdAt=Instant.now();
}
