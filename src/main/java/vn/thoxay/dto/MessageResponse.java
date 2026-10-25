package vn.thoxay.dto;

import vn.thoxay.entity.Message;
import java.time.Instant;

public record MessageResponse(Long id, Long senderId, Long recipientId, Long jobId,
    String content, Instant createdAt, String clientMessageId) {
    public static MessageResponse of(Message m) {
        return new MessageResponse(m.getId(), m.getSender().getId(), m.getRecipient().getId(),
            m.getJob().getId(), m.getContent(), m.getCreatedAt(), m.getClientMessageId());
    }
}
