package vn.thoxay.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.*;
import vn.thoxay.service.UserProfileService;

@RestController @RequestMapping("/api/users/me") @RequiredArgsConstructor
public class UserProfileController {
    private final UserProfileService profiles;
    @GetMapping
    public UserProfileResponse profile() { return profiles.profile(); }
    @PutMapping
    public UserProfileResponse update(@Valid @RequestBody ProfileRequest request) { return profiles.update(request); }
    @PutMapping("/cccd")
    public UserProfileResponse updateCccd(@Valid @RequestBody CccdRequest request) {
        return profiles.updateCccd(request);
    }
}
