package vn.thoxay.chat;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequiredArgsConstructor @Validated
public class ChatInboxController {
    private final ChatInboxService service;
    public record ReadRequest(@NotNull @Positive Long peerId, @NotNull @Positive Long lastReadMessageId) { }
    @GetMapping("/api/messages/inbox")
    public ChatInboxService.Inbox inbox(@RequestParam(required = false) @Positive Long beforeId) { return service.inbox(beforeId); }
    @GetMapping("/api/messages/unread")
    public Map<String, Long> unread() { return Map.of("unreadCount", service.unread()); }
    @PutMapping("/api/jobs/{jobId}/messages/read")
    public Map<String, Long> read(@PathVariable @Positive Long jobId, @RequestBody @Valid ReadRequest request) {
        return Map.of("lastReadMessageId", service.read(jobId, request.peerId(), request.lastReadMessageId()));
    }
}
