package vn.thoxay.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.*;
import vn.thoxay.service.UserProfileService;

@RestController @RequestMapping("/api/users/me") @RequiredArgsConstructor
public class UserProfileController {
    private final UserProfileService profiles;
    private final vn.thoxay.service.ReputationService reputation;
    @GetMapping("/reputation") public vn.thoxay.service.ReputationService.History reputation(
        @RequestParam(required = false) @jakarta.validation.constraints.Positive Long beforeId,
        @RequestParam(defaultValue = "30") @jakarta.validation.constraints.Min(1) @jakarta.validation.constraints.Max(100) int limit) {
        return reputation.history(beforeId, limit);
    }
    @GetMapping
    public UserProfileResponse profile() { return profiles.profile(); }
    @PutMapping
    public UserProfileResponse update(@Valid @RequestBody ProfileRequest request) { return profiles.update(request); }
    @PutMapping("/cccd")
    public UserProfileResponse updateCccd(@Valid @RequestBody CccdRequest request) {
        return profiles.updateCccd(request);
    }
}
