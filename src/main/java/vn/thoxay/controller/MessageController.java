package vn.thoxay.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.*;
import vn.thoxay.service.MessageService;

@RestController @RequestMapping("/api/jobs/{jobId}/messages") @RequiredArgsConstructor
public class MessageController {
    private final MessageService messages;
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
