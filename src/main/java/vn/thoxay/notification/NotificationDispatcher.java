package vn.thoxay.notification;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.repository.*;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;

@Service @RequiredArgsConstructor
public class NotificationDispatcher {
    private final NotificationRepository notifications;
    private final DeviceTokenRepository devices;
    private final PushGateway push;

    @Transactional
    public void deliver(Long id) {
        var n = notifications.locked(id).orElse(null);
        if (n == null || !"PENDING".equals(n.getPushStatus()) || n.getNextAttemptAt().isAfter(Instant.now())) return;
        if (!push.enabled()) return;
        if (!n.getRecipient().isActive() || n.getReadAt() != null) { n.setPushStatus("SKIPPED"); return; }
        var targets = devices.findByUserIdAndLastSeenAtAfter(n.getRecipient().getId(), Instant.now().minus(60, ChronoUnit.DAYS));
        if (targets.isEmpty()) { n.setPushStatus("SKIPPED"); return; }
        n.setPushAttempts(n.getPushAttempts() + 1);
        boolean retry = false, accepted = false, failed = false;
        for (var device : targets) {
            PushGateway.Result result;
            try { result = push.send(device.getToken(), n.getTitle(), n.getBody(), Map.of("notificationId", n.getId().toString(), "type", n.getType(), "userId", n.getRecipient().getId().toString())); }
            catch (Exception e) { result = PushGateway.Result.RETRY; }
            switch (result) {
                case ACCEPTED -> accepted = true;
                case INVALID_TOKEN -> devices.delete(device);
                case RETRY -> retry = true;
                case FAILED -> failed = true;
            }
        }
        if (retry && n.getPushAttempts() < 3) { n.setNextAttemptAt(Instant.now().plusSeconds(10L * n.getPushAttempts())); }
        else n.setPushStatus(retry || failed ? "FAILED" : accepted ? "ACCEPTED" : "SKIPPED");
    }
}
