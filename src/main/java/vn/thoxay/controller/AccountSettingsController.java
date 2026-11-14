package vn.thoxay.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.AuthResponse;
import vn.thoxay.service.AccountSettingsService;

@RestController @RequestMapping("/api/users/me/settings") @RequiredArgsConstructor
public class AccountSettingsController {
    private final AccountSettingsService settings;
    public record PasswordRequest(@NotBlank @Size(max=72) String currentPassword,
        @NotBlank @Size(min=8,max=72) String newPassword) { }
    public record PhoneRequest(@NotBlank @Pattern(regexp="0[0-9]{9,14}") String phoneNumber,
        @NotBlank @Size(max=72) String currentPassword) { }
    public record PushPreferences(@NotNull Boolean jobPushEnabled, @NotNull Boolean chatPushEnabled) { }
    public record RoleRequest(@NotBlank @Pattern(regexp="ROLE_WORKER|ROLE_CONTRACTOR") String role) { }
    @PutMapping("/role") public AuthResponse role(@Valid @RequestBody RoleRequest request) { return settings.role(request); }
    @PutMapping("/password") public AuthResponse password(@Valid @RequestBody PasswordRequest request) { return settings.password(request); }
    @PutMapping("/phone") public AuthResponse phone(@Valid @RequestBody PhoneRequest request) { return settings.phone(request); }
    @GetMapping("/notifications") public PushPreferences notifications() { return settings.notifications(); }
    @PutMapping("/notifications") public PushPreferences notifications(@Valid @RequestBody PushPreferences request) { return settings.notifications(request); }
}
