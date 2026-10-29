package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record ApplicationRequest(@NotNull @Positive Long jobId,
    @Min(1) @Max(1000000000) Long proposedDailyRate, @Size(max=500) String wageNote,
    Boolean acceptedTerms, @Positive Integer termsVersion) {
    public ApplicationRequest(Long jobId) { this(jobId, null, null, null, null); }
}
