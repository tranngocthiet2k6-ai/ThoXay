package vn.thoxay.chat;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import vn.thoxay.dto.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.service.ChatAccessService;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor
public class ChatInboxService {
    private final CurrentUser current;
    private final MessageRepository messages;
    private final JobRepository jobs;
    private final UserRepository users;
    private final ChatReadStateRepository reads;
    private final ChatAccessService access;
    public record Conversation(JobResponse job, Long peerId, String peerName, MessageResponse latest, long unreadCount) { }
    public record Inbox(List<Conversation> conversations, boolean hasMore, long unreadCount) { }

    private User actor() {
        User user = current.get();
        if (user.getRole() != Role.ROLE_WORKER && user.getRole() != Role.ROLE_CONTRACTOR)
            throw new ApiException(HttpStatus.FORBIDDEN, "Hộp thư dành cho thợ và chủ thầu");
        return user;
    }
    @Transactional(readOnly = true)
    public long unread() { return messages.unread(actor().getId()); }

    @Transactional(readOnly = true)
    public Inbox inbox(Long beforeId) {
        User user = actor();
        var rows = messages.inbox(user.getId(), beforeId == null ? Long.MAX_VALUE : beforeId, PageRequest.of(0,31));
        var page = rows.subList(0, Math.min(30, rows.size()));
        var loaded = messages.findByIdIn(page.stream().map(MessageRepository.InboxRow::getLatestId).toList())
            .stream().collect(Collectors.toMap(Message::getId, Function.identity()));
        var result = new ArrayList<Conversation>();
        for (var row : page) {
            Message m = loaded.get(row.getLatestId());
            if (m == null) continue; // A job may be deleted between the read-only statements.
            User peer = m.getSender().getId().equals(user.getId()) ? m.getRecipient() : m.getSender();
            result.add(new Conversation(JobResponse.of(m.getJob(), null, false), peer.getId(), peer.getFullName(),
                MessageResponse.of(m), row.getUnreadCount()));
        }
        return new Inbox(result, rows.size() > 30, messages.unread(user.getId()));
    }

    @Transactional
    public long read(Long jobId, Long peerId, Long messageId) {
        Job job = jobs.findLockedById(jobId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Công trình không tồn tại"));
        User actor = actor(); access.authorize(actor, job, peerId);
        Message message = messages.findById(messageId).orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "Tin nhắn không tồn tại"));
        if (!message.getJob().getId().equals(jobId) ||
            !(message.getSender().getId().equals(actor.getId()) && message.getRecipient().getId().equals(peerId)
              || message.getSender().getId().equals(peerId) && message.getRecipient().getId().equals(actor.getId())))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Con trỏ đọc không thuộc cuộc trò chuyện");
        var state = reads.findByUserIdAndJobIdAndPeerId(actor.getId(), jobId, peerId).orElseGet(() -> {
            var value = new ChatReadState(); value.setJob(job); value.setUser(actor); value.setPeer(users.getReferenceById(peerId)); return value;
        });
        state.setLastReadMessageId(Math.max(state.getLastReadMessageId(), messageId));
        reads.saveAndFlush(state);
        return state.getLastReadMessageId();
    }
}
