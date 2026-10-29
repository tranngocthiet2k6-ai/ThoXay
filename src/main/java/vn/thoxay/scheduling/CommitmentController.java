package vn.thoxay.scheduling;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController @RequiredArgsConstructor
public class CommitmentController {
    private final CommitmentService commitments;
    public record Consent(@NotNull @Positive Integer termsVersion,@NotNull Boolean accepted) { }
    @GetMapping("/api/jobs/{id}/terms") public CommitmentService.Document terms(@PathVariable @Positive Long id,
        @RequestParam(required=false) @Min(1) @Max(1000000000) Long proposedDailyRate) { return commitments.jobTerms(id,proposedDailyRate); }
    @GetMapping("/api/applications/{id}/commitment") public CommitmentService.Document read(@PathVariable @Positive Long id,
        @RequestParam(defaultValue="false") boolean acceptCounterOffer) { return commitments.read(id,acceptCounterOffer); }
    @PutMapping("/api/applications/{id}/commitment") public CommitmentService.Document confirm(@PathVariable @Positive Long id,
        @Valid @RequestBody Consent input) { return commitments.confirm(id,input.termsVersion(),input.accepted()); }
}
