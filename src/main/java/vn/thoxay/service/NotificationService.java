package vn.thoxay.service;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.notification.PushGateway;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.*;

@Service @RequiredArgsConstructor
public class NotificationService {
    private final NotificationRepository notifications;
    private final DeviceTokenRepository devices;
    private final CurrentUser current;
    private final PushGateway push;
    private final EntityManager em;
    public record Item(Long id, String type, String title, String body, Long jobId, Instant createdAt, Instant readAt) {
        static Item of(AppNotification n) { return new Item(n.getId(), n.getType(), n.getTitle(), n.getBody(),
            n.getJob() == null ? null : n.getJob().getId(), n.getCreatedAt(), n.getReadAt()); }
    }
    public record History(List<Item> items, boolean hasMore, long unreadCount) { }

    @Transactional(propagation = Propagation.MANDATORY)
    public void create(User recipient, Job job, String eventKey, String type, String title, String body) {
        if (!recipient.isActive() || notifications.existsByEventKey(eventKey)) return;
        AppNotification n = new AppNotification(); n.setRecipient(recipient); n.setJob(job); n.setEventKey(eventKey);
        n.setType(type); n.setTitle(title); n.setBody(body);
        n.setPushStatus(push.enabled() ? "PENDING" : "DISABLED"); notifications.save(n);
    }
    @Transactional(readOnly = true)
    public History history(Long before, int limit) {
        Long id = current.get().getId();
        var rows = notifications.findByRecipientIdAndIdLessThanOrderByIdDesc(id, before == null ? Long.MAX_VALUE : before, PageRequest.of(0, limit + 1));
        return new History(rows.stream().limit(limit).map(Item::of).toList(), rows.size() > limit, notifications.countByRecipientIdAndReadAtIsNull(id));
    }
    @Transactional
    public void read(Long id) {
        Long user = current.get().getId();
        if (id != null && !notifications.existsByIdAndRecipientId(id, user)) throw new ApiException(HttpStatus.NOT_FOUND, "Thông báo không tồn tại");
        notifications.markRead(user, id, Instant.now());
    }
    @Transactional
    public void register(String token) {
        User user = current.get();
        em.refresh(user, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
        DeviceToken device = devices.findByTokenHash(hash(token)).orElseGet(DeviceToken::new);
        device.setUser(user); device.setToken(token); device.setTokenHash(hash(token)); device.setLastSeenAt(Instant.now()); devices.save(device);
    }
    @Transactional
    public void unregister(String token) { devices.deleteByUserIdAndTokenHash(current.get().getId(), hash(token)); }
    public static String hash(String value) {
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8))); }
        catch (java.security.NoSuchAlgorithmException e) { throw new IllegalStateException(e); }
    }
}
