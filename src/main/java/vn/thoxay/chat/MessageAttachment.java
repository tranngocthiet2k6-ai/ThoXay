package vn.thoxay.chat;

import jakarta.persistence.*;
import lombok.*;
import vn.thoxay.entity.Message;

@Entity @Table(name = "message_attachments") @Getter @Setter
public class MessageAttachment {
    @Id private Long id;
    @OneToOne(fetch = FetchType.LAZY, optional = false) @MapsId
    @JoinColumn(name = "message_id")
    @org.hibernate.annotations.OnDelete(action = org.hibernate.annotations.OnDeleteAction.CASCADE)
    private Message message;
    @Column(nullable = false, columnDefinition = "bytea") private byte[] content;
}
