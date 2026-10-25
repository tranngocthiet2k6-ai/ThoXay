package vn.thoxay.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.*;
import vn.thoxay.service.JobService;
import java.util.List;

@RestController @RequestMapping("/api/jobs") @RequiredArgsConstructor
public class JobController {
    private final JobService jobs;
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public JobResponse create(@Valid @RequestBody JobRequest request) { return jobs.create(request); }
    @GetMapping("/nearby")
    public List<JobResponse> nearby(
        @RequestParam @DecimalMin("-90") @DecimalMax("90") double lat,
        @RequestParam @DecimalMin("-180") @DecimalMax("180") double lng,
        @RequestParam(defaultValue = "10") @DecimalMin("0.1") @DecimalMax("200") double radius) {
        return jobs.nearby(lat, lng, radius);
    }
    @GetMapping("/contractor/{contractorId}")
    public List<JobResponse> byContractor(@PathVariable @Positive Long contractorId) { return jobs.byContractor(contractorId); }
}
