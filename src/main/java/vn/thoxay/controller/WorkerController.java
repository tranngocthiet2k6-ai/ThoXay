package vn.thoxay.controller;

import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.WorkerProfileResponse;
import vn.thoxay.service.UserProfileService;

@RestController @RequestMapping("/api/workers") @RequiredArgsConstructor
public class WorkerController {
    private final UserProfileService profiles;
    @GetMapping("/{id}/profile") public WorkerProfileResponse profile(@PathVariable @Positive Long id) { return profiles.worker(id); }
}
