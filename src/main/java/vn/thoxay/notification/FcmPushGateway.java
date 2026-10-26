package vn.thoxay.notification;

import com.google.firebase.messaging.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;
import java.util.Map;

@Component @RequiredArgsConstructor
public class FcmPushGateway implements PushGateway {
    private final ObjectProvider<FirebaseMessaging> messaging;
    @Override public boolean enabled() { return messaging.getIfAvailable() != null; }
    @Override public Result send(String token, String title, String body, Map<String, String> data) {
        FirebaseMessaging client = messaging.getIfAvailable();
        if (client == null) return Result.FAILED;
        try {
            client.send(Message.builder().setFid(token).putAllData(data)
                .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                .setAndroidConfig(AndroidConfig.builder().setPriority(AndroidConfig.Priority.HIGH)
                    .setNotification(AndroidNotification.builder().setTag("notification-" + data.get("notificationId")).build()).build())
                .setApnsConfig(ApnsConfig.builder().setAps(Aps.builder().setSound("default").build()).build()).build());
            return Result.ACCEPTED;
        } catch (FirebaseMessagingException e) {
            if (e.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED) return Result.INVALID_TOKEN;
            if (e.getMessagingErrorCode() == MessagingErrorCode.UNAVAILABLE || e.getMessagingErrorCode() == MessagingErrorCode.INTERNAL
                || e.getMessagingErrorCode() == MessagingErrorCode.QUOTA_EXCEEDED) return Result.RETRY;
            return Result.FAILED;
        }
    }
}
