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

@Service @RequiredArgsConstructor
public class MessageService {
    private final MessageRepository messages;
    private final JobRepository jobs;
    private final UserRepository users;
    private final CurrentUser current;
    private final ChatAccessService access;
    private final ApplicationEventPublisher events;

    public record MessageSent(ChatAccessService.Conversation conversation, MessageResponse message) { }
    public record History(List<MessageResponse> messages, boolean hasMore) { }

    @Transactional
    public MessageResponse send(Long jobId, MessageRequest request) {
        // Serialize sends within a job: cursor IDs follow commit order, and deletion/acceptance uses the same lock.
        Job job = jobs.findLockedById(jobId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Công trình không tồn tại"));
        User sender = current.get();
        var conversation = access.authorize(sender, job, request.recipientId());
        String content = request.content().strip();
        if (content.isBlank()) throw new ApiException(HttpStatus.BAD_REQUEST, "Nội dung tin nhắn không được để trống");
        var existing = messages.findBySenderIdAndClientMessageId(sender.getId(), request.clientMessageId());
        if (existing.isPresent()) {
            Message m = existing.get();
            if (!m.getJob().getId().equals(jobId) || !m.getRecipient().getId().equals(request.recipientId()) || !m.getContent().equals(content))
                throw new ApiException(HttpStatus.CONFLICT, "Mã tin nhắn đã được dùng cho nội dung khác");
            return MessageResponse.of(m);
        }
        Message m = new Message(); m.setJob(job); m.setSender(sender);
        m.setRecipient(users.getReferenceById(request.recipientId())); m.setContent(content);
        m.setClientMessageId(request.clientMessageId());
        MessageResponse response = MessageResponse.of(messages.saveAndFlush(m));
        events.publishEvent(new MessageSent(conversation, response));
        return response;
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
