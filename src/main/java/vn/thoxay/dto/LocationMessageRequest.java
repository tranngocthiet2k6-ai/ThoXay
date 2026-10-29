package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record LocationMessageRequest(@NotNull @Positive Long recipientId,
    @NotBlank @Pattern(regexp = "[A-Za-z0-9_-]{1,64}") String clientMessageId,
    @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
    @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude) {
    @Override public String toString() { return "LocationMessageRequest[private location]"; }
}
