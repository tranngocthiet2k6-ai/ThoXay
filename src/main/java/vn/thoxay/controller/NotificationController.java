package vn.thoxay.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.service.NotificationService;

@RestController @RequestMapping("/api/notifications") @RequiredArgsConstructor
public class NotificationController {
    private final NotificationService notifications;
    public record TokenRequest(@NotBlank @Size(max = 4096) String token) { }
    @GetMapping public NotificationService.History history(@RequestParam(required = false) @Positive Long beforeId,
        @RequestParam(defaultValue = "30") @Min(1) @Max(100) int limit) { return notifications.history(beforeId, limit); }
    @PutMapping("/{id}/read") @ResponseStatus(HttpStatus.NO_CONTENT) public void read(@PathVariable @Positive Long id) { notifications.read(id); }
    @PutMapping("/read-all") @ResponseStatus(HttpStatus.NO_CONTENT) public void readAll() { notifications.read(null); }
    @PutMapping("/devices") @ResponseStatus(HttpStatus.NO_CONTENT) public void register(@RequestBody @Valid TokenRequest request) { notifications.register(request.token()); }
    @PostMapping("/devices/unregister") @ResponseStatus(HttpStatus.NO_CONTENT) public void unregister(@RequestBody @Valid TokenRequest request) { notifications.unregister(request.token()); }
}
