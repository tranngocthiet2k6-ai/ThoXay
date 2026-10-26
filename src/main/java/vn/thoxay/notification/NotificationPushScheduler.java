package vn.thoxay.notification;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import vn.thoxay.repository.NotificationRepository;
import java.time.Instant;

@Component @RequiredArgsConstructor @ConditionalOnProperty(name = "app.notifications.dispatch-enabled", matchIfMissing = true)
public class NotificationPushScheduler {
    private final PushGateway push;
    private final NotificationRepository notifications;
    private final NotificationDispatcher dispatcher;
    @Scheduled(fixedDelay = 5000) public void dispatch() {
        if (!push.enabled()) return;
        for (Long id : notifications.due(Instant.now(), PageRequest.of(0, 10))) dispatcher.deliver(id);
    }
}
