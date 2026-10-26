package vn.thoxay.notification;

import java.util.Map;

public interface PushGateway {
    enum Result { ACCEPTED, INVALID_TOKEN, RETRY, FAILED }
    boolean enabled();
    Result send(String token, String title, String body, Map<String, String> data);
}
