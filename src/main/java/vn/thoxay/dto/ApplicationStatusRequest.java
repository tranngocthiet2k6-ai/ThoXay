package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record ApplicationStatusRequest(
    @NotBlank @Pattern(regexp = "ACCEPTED|REJECTED", message = "Chọn ACCEPTED hoặc REJECTED") String status,
    Boolean acceptCounterOffer, Boolean acceptedTerms, @Positive Integer termsVersion) {
    public ApplicationStatusRequest(String status) { this(status, null, null, null); }
}
