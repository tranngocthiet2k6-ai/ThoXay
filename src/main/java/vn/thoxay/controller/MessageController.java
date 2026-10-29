package vn.thoxay.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.*;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.*;
import vn.thoxay.service.MessageService;

@RestController @RequestMapping("/api/jobs/{jobId}/messages") @RequiredArgsConstructor @Validated
public class MessageController {
    private final MessageService messages;
    @PostMapping(value = "/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE) @ResponseStatus(HttpStatus.CREATED)
    public MessageResponse photo(@PathVariable @Positive Long jobId, @RequestParam @Positive Long recipientId,
        @RequestParam @Pattern(regexp = "[A-Za-z0-9_-]{1,64}") String clientMessageId,
        @RequestParam(defaultValue = "") @Size(max = 2000) String caption, @RequestPart MultipartFile photo) {
        return messages.sendPhoto(jobId, recipientId, clientMessageId, caption, photo);
    }
    @PostMapping("/location") @ResponseStatus(HttpStatus.CREATED)
    public MessageResponse location(@PathVariable @Positive Long jobId, @RequestBody @Valid LocationMessageRequest request) {
        return messages.sendLocation(jobId, request);
    }
    @GetMapping("/{messageId}/photo")
    public ResponseEntity<byte[]> photo(@PathVariable @Positive Long jobId, @PathVariable @Positive Long messageId) {
        return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG).cacheControl(CacheControl.noStore())
            .header("X-Content-Type-Options", "nosniff").body(messages.photo(jobId, messageId));
    }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public MessageResponse send(@PathVariable @Positive Long jobId, @Valid @RequestBody MessageRequest request) {
        return messages.send(jobId, request);
    }
    @GetMapping
    public MessageService.History history(@PathVariable @Positive Long jobId, @RequestParam @Positive Long peerId,
        @RequestParam(required = false) @PositiveOrZero Long afterId,
        @RequestParam(required = false) @Positive Long beforeId, @RequestParam(defaultValue = "50") @Min(1) @Max(100) int limit) {
        return messages.history(jobId, peerId, afterId, beforeId, limit);
    }
}
