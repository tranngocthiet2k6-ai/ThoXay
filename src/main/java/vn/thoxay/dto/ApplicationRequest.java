package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record ApplicationRequest(@NotNull @Positive Long jobId) { }
