package vn.thoxay.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CancelApplicationRequest(@NotBlank @Size(max = 500) String reason) { }
