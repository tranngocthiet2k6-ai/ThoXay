package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record CccdRequest(
    @NotBlank @Size(max = 500) @Pattern(regexp = "https://[^\\s]+", message = "Ảnh CCCD phải là URL HTTPS")
    String cccdImage) { }
