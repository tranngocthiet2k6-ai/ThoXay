package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record CccdRequest(
    @NotBlank @Size(max = 500) @Pattern(regexp = "https://[^\\s]+", message = "Ảnh mặt trước CCCD phải là URL HTTPS")
    String cccdFrontImage,
    @NotBlank @Size(max = 500) @Pattern(regexp = "https://[^\\s]+", message = "Ảnh mặt sau CCCD phải là URL HTTPS")
    String cccdBackImage) { }
