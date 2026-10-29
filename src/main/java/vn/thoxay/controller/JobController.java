package vn.thoxay.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.*;
import vn.thoxay.service.JobService;
import vn.thoxay.service.JobCompletionService;
import java.util.List;

@RestController @RequestMapping("/api/jobs") @RequiredArgsConstructor
public class JobController {
    private final JobService jobs;
    private final JobCompletionService completions;
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public JobResponse create(@Valid @RequestBody JobRequest request) { return jobs.create(request); }
    @GetMapping("/{id}") public JobResponse detail(@PathVariable @Positive Long id) { return jobs.detail(id); }
    @PutMapping("/{id}") public JobResponse update(@PathVariable @Positive Long id,@Valid @RequestBody JobRequest request) { return jobs.update(id,request); }
    @GetMapping("/nearby")
    public List<JobResponse> nearby(
        @RequestParam @DecimalMin("-90") @DecimalMax("90") double lat,
        @RequestParam @DecimalMin("-180") @DecimalMax("180") double lng,
        @RequestParam(defaultValue = "10") @DecimalMin("0.1") @DecimalMax("200") double radius,
        @RequestParam(required = false) @Pattern(regexp = "Thợ chính|Phụ hồ") String jobType,
        @RequestParam(defaultValue = "DISTANCE") @Pattern(regexp = "DISTANCE|SALARY_DESC") String sort) {
        return jobs.nearby(lat, lng, radius, jobType, sort);
    }
    @PutMapping("/{id}/complete")
    public JobResponse complete(@PathVariable @Positive Long id, @Valid @RequestBody CompleteJobRequest request) {
        return completions.complete(id, request);
    }
    @GetMapping("/contractor/{contractorId}")
    public List<JobResponse> byContractor(@PathVariable @Positive Long contractorId) { return jobs.byContractor(contractorId); }
}
