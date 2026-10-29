package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import java.util.*;
import vn.thoxay.chat.*;
import vn.thoxay.media.ImageSanitizer;
import org.springframework.web.multipart.MultipartFile;

@Service @RequiredArgsConstructor
public class MessageService {
    private final MessageRepository messages;
    private final JobRepository jobs;
    private final UserRepository users;
    private final CurrentUser current;
    private final ChatAccessService access;
    private final ApplicationEventPublisher events;
    private final NotificationService notifications;
    private final MessageAttachmentRepository attachments;
    private final ImageSanitizer images;

    public record MessageSent(ChatAccessService.Conversation conversation, MessageResponse message) { }
    public record History(List<MessageResponse> messages, boolean hasMore) { }

    @Transactional
    public MessageResponse send(Long jobId, MessageRequest request) {
        return persist(jobId, request.recipientId(), request.clientMessageId(), request.content().strip(),
            "TEXT", null, null, null);
    }

    @Transactional
    public MessageResponse sendPhoto(Long jobId, Long recipient, String clientId, String caption, MultipartFile photo) {
        // Reject unauthorized uploads before decoding an image. Authorization is checked again under the job lock.
        Job job = jobs.findById(jobId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Công trình không tồn tại"));
        access.authorize(current.get(), job, recipient);
        byte[] clean = images.project(photo);
        String text = caption == null || caption.isBlank() ? "Ảnh công trường" : caption.strip();
        return persist(jobId, recipient, clientId, text, "IMAGE", null, null, clean);
    }

    @Transactional
    public MessageResponse sendLocation(Long jobId, LocationMessageRequest request) {
        return persist(jobId, request.recipientId(), request.clientMessageId(), "Vị trí được chia sẻ",
            "LOCATION", request.latitude(), request.longitude(), null);
    }

    private MessageResponse persist(Long jobId, Long recipient, String clientId, String content,
            String kind, Double lat, Double lng, byte[] image) {
        // Serialize sends within a job: cursor IDs follow commit order, and deletion/acceptance uses the same lock.
        Job job = jobs.findLockedById(jobId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Công trình không tồn tại"));
        User sender = current.get();
        var conversation = access.authorize(sender, job, recipient);
        if (content.isBlank()) throw new ApiException(HttpStatus.BAD_REQUEST, "Nội dung tin nhắn không được để trống");
        String hash = image == null ? null : hash(image);
        var existing = messages.findBySenderIdAndClientMessageId(sender.getId(), clientId);
        if (existing.isPresent()) {
            Message m = existing.get();
            if (!m.getJob().getId().equals(jobId) || !m.getRecipient().getId().equals(recipient) || !m.getContent().equals(content)
                || !m.getKind().equals(kind) || !Objects.equals(m.getLatitude(), lat)
                || !Objects.equals(m.getLongitude(), lng) || !Objects.equals(m.getImageHash(), hash))
                throw new ApiException(HttpStatus.CONFLICT, "Mã tin nhắn đã được dùng cho nội dung khác");
            return MessageResponse.of(m);
        }
        Message m = new Message(); m.setJob(job); m.setSender(sender);
        m.setRecipient(users.getReferenceById(recipient)); m.setContent(content);
        m.setKind(kind); m.setLatitude(lat); m.setLongitude(lng); m.setImageHash(hash);
        m.setClientMessageId(clientId);
        MessageResponse response = MessageResponse.of(messages.saveAndFlush(m));
        if (image != null) {
            MessageAttachment attachment = new MessageAttachment(); attachment.setMessage(m); attachment.setContent(image);
            attachments.saveAndFlush(attachment);
        }
        notifications.create(m.getRecipient(), job, "message:" + m.getId(), "CHAT_MESSAGE", "Bạn có tin nhắn mới",
            "Mở cuộc trò chuyện trong Thợ Xây để xem và trả lời. Nội dung tin nhắn được giữ riêng trong ứng dụng.");
        events.publishEvent(new MessageSent(conversation, response));
        return response;
    }

    private String hash(byte[] bytes) {
        try { return HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(bytes)); }
        catch (java.security.NoSuchAlgorithmException e) { throw new IllegalStateException(e); }
    }

    @Transactional(readOnly = true)
    public byte[] photo(Long jobId, Long messageId) {
        Message m = messages.findById(messageId).filter(row -> row.getJob().getId().equals(jobId))
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Ảnh không tồn tại"));
        User actor = current.get();
        Long peer = m.getSender().getId().equals(actor.getId()) ? m.getRecipient().getId() : m.getSender().getId();
        access.authorize(actor, m.getJob(), peer);
        // The pair ACL must also include this particular message, not another worker accepted for the job.
        if (!m.getSender().getId().equals(actor.getId()) && !m.getRecipient().getId().equals(actor.getId()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Ảnh thuộc cuộc trò chuyện khác");
        return attachments.findById(messageId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Ảnh không tồn tại")).getContent();
    }

    @Transactional(readOnly = true)
    public History history(Long jobId, Long peerId, Long afterId, Long beforeId, int limit) {
        User actor = current.get();
        Job job = jobs.findById(jobId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Công trình không tồn tại"));
        access.authorize(actor, job, peerId);
        if (afterId != null && beforeId != null) throw new ApiException(HttpStatus.BAD_REQUEST, "Chỉ dùng một con trỏ lịch sử");
        var page = PageRequest.of(0, limit + 1);
        List<Message> rows = afterId != null ? messages.newer(jobId, actor.getId(), peerId, afterId, page)
            : messages.older(jobId, actor.getId(), peerId, beforeId == null ? Long.MAX_VALUE : beforeId, page);
        boolean more = rows.size() > limit;
        var result = new ArrayList<>(rows.subList(0, Math.min(rows.size(), limit)));
        if (afterId == null) Collections.reverse(result);
        return new History(result.stream().map(MessageResponse::of).toList(), more);
    }
}
