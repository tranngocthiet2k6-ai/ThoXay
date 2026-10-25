package vn.thoxay.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.*;
import vn.thoxay.exception.*;
import vn.thoxay.service.ChatAccessService;
import vn.thoxay.service.MessageService.MessageSent;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component @RequiredArgsConstructor
public class ChatWebSocketHandler extends TextWebSocketHandler {
    private final ChatAccessService access;
    private final ObjectMapper json;
    private final Map<String, Client> clients = new ConcurrentHashMap<>();
    private static class Client {
        final WebSocketSession session;
        final long connectedAt = System.currentTimeMillis();
        volatile String token;
        volatile ChatAccessService.Subscription subscription;
        Client(WebSocketSession session) { this.session = new ConcurrentWebSocketSessionDecorator(session, 3000, 65536); }
    }

    @Override public void afterConnectionEstablished(WebSocketSession session) {
        session.setTextMessageSizeLimit(8192);
        clients.put(session.getId(), new Client(session));
    }
    @Override protected void handleTextMessage(WebSocketSession session, TextMessage frame) {
        Client c = clients.get(session.getId());
        if (c == null) return;
        try {
            var data = json.readTree(frame.getPayload());
            if (!"subscribe".equals(data.path("type").asText()) || c.subscription != null
                || !data.path("jobId").canConvertToLong() || data.path("jobId").asLong() <= 0
                || !data.path("peerId").canConvertToLong() || data.path("peerId").asLong() <= 0) {
                reject(c, "BAD_REQUEST", "Yêu cầu kết nối không hợp lệ"); return;
            }
            String token = data.path("token").asText("");
            var subscription = access.authenticate(token, data.path("jobId").asLong(), data.path("peerId").asLong());
            c.token = token; c.subscription = subscription;
            send(c, Map.of("type", "ready"));
        } catch (AccountLockedException e) { reject(c, AccountLockedException.CODE, e.getMessage()); }
        catch (ApiException e) { reject(c, e.getStatus().value() == 401 ? "UNAUTHORIZED" : "CHAT_FORBIDDEN", e.getMessage()); }
        catch (Exception e) { reject(c, "BAD_REQUEST", "Không thể mở cuộc trò chuyện"); }
    }

    @TransactionalEventListener
    public void messageCommitted(MessageSent event) {
        for (Client c : clients.values()) {
            var sub = c.subscription;
            if (sub != null && sub.conversation().equals(event.conversation()) && authorized(c))
                send(c, Map.of("type", "message", "message", event.message()));
        }
    }

    // Revalidate old JWTs, locked accounts and participation even when a conversation is idle.
    @Scheduled(fixedDelay = 10000)
    public void heartbeat() {
        for (Client c : clients.values()) {
            if (c.subscription == null) {
                if (System.currentTimeMillis() - c.connectedAt >= 10000) reject(c, "UNAUTHORIZED", "Vui lòng đăng nhập lại");
            } else if (authorized(c)) send(c, Map.of("type", "heartbeat"));
        }
    }
    private boolean authorized(Client c) {
        try {
            var sub = c.subscription;
            access.authenticate(c.token, sub.conversation().jobId(), sub.peerId());
            return true;
        } catch (AccountLockedException e) { reject(c, AccountLockedException.CODE, e.getMessage()); }
        catch (ApiException e) { reject(c, e.getStatus().value() == 401 ? "UNAUTHORIZED" : "CHAT_FORBIDDEN", e.getMessage()); }
        catch (Exception e) { close(c, CloseStatus.SERVER_ERROR); }
        return false;
    }
    private void send(Client c, Object value) {
        try { if (c.session.isOpen()) c.session.sendMessage(new TextMessage(json.writeValueAsString(value))); }
        catch (Exception e) { close(c, CloseStatus.SERVER_ERROR); }
    }
    private void reject(Client c, String code, String message) {
        send(c, Map.of("type", "error", "code", code, "message", message));
        close(c, CloseStatus.POLICY_VIOLATION);
    }
    private void close(Client c, CloseStatus status) {
        clients.remove(c.session.getId());
        try { if (c.session.isOpen()) c.session.close(status); } catch (IOException ignored) { }
    }
    @Override public void afterConnectionClosed(WebSocketSession session, CloseStatus status) { clients.remove(session.getId()); }
    @Override public void handleTransportError(WebSocketSession session, Throwable exception) {
        Client c = clients.get(session.getId()); if (c != null) close(c, CloseStatus.SERVER_ERROR);
    }
}
