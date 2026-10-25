package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record ApplicationStatusRequest(
    @NotBlank @Pattern(regexp = "ACCEPTED|REJECTED", message = "Chọn ACCEPTED hoặc REJECTED") String status) { }
