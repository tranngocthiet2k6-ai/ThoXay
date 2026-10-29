package vn.thoxay.dto;

import vn.thoxay.entity.Message;
import java.time.Instant;

public record MessageResponse(Long id, Long senderId, Long recipientId, Long jobId,
    String content, Instant createdAt, String clientMessageId, String kind,
    Double latitude, Double longitude, String imagePath) {
    public static MessageResponse of(Message m) {
        return new MessageResponse(m.getId(), m.getSender().getId(), m.getRecipient().getId(),
            m.getJob().getId(), m.getContent(), m.getCreatedAt(), m.getClientMessageId(), m.getKind(),
            m.getLatitude(), m.getLongitude(), "IMAGE".equals(m.getKind())
                ? "/api/jobs/" + m.getJob().getId() + "/messages/" + m.getId() + "/photo" : null);
    }
}
