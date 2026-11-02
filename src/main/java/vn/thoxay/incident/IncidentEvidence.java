package vn.thoxay.incident;
import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;
@Entity @Table(name="incident_evidence") @Getter @Setter
public class IncidentEvidence {
 @Id @Column(name="incident_id") private Long incidentId;
 @Column(nullable=false,columnDefinition="bytea") private byte[] content;
 @Column(nullable=false) private Instant createdAt;
}
