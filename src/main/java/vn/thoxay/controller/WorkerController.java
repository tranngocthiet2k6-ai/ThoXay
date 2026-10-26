package vn.thoxay.controller;

import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.WorkerProfileResponse;
import vn.thoxay.service.UserProfileService;

@RestController @RequestMapping("/api/workers") @RequiredArgsConstructor
public class WorkerController {
    private final UserProfileService profiles;
    private final vn.thoxay.service.WorkerRankingService rankings;
    @GetMapping("/leaderboard") public java.util.List<vn.thoxay.service.WorkerRankingService.Rank> leaderboard(@RequestParam(defaultValue = "20") @Min(1) @Max(100) int limit) { return rankings.leaderboard(limit); }
    @GetMapping("/{id}/reviews") public vn.thoxay.service.WorkerRankingService.Reviews reviews(@PathVariable @Positive Long id,
        @RequestParam(required = false) @Positive Long beforeId, @RequestParam(defaultValue = "20") @Min(1) @Max(100) int limit) { return rankings.reviews(id, beforeId, limit); }
    @GetMapping("/{id}/profile") public WorkerProfileResponse profile(@PathVariable @Positive Long id) { return profiles.worker(id); }
}
