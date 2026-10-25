package vn.thoxay.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.*;
import vn.thoxay.service.ApplicationService;
import java.util.List;

@RestController @RequestMapping("/api/applications") @RequiredArgsConstructor
public class ApplicationController {
    private final ApplicationService applications;
    @PostMapping("/apply") @ResponseStatus(HttpStatus.CREATED)
    public ApplicationResponse apply(@Valid @RequestBody ApplicationRequest request) { return applications.apply(request); }
    @GetMapping("/job/{jobId}")
    public List<ApplicationResponse> byJob(@PathVariable @Positive Long jobId) { return applications.byJob(jobId); }
    @GetMapping("/worker/{workerId}")
    public List<ApplicationResponse> byWorker(@PathVariable @Positive Long workerId) { return applications.byWorker(workerId); }
    @PutMapping("/{id}/status")
    public ApplicationResponse updateStatus(@PathVariable @Positive Long id, @Valid @RequestBody ApplicationStatusRequest request) {
        return applications.updateStatus(id, request);
    }
}
