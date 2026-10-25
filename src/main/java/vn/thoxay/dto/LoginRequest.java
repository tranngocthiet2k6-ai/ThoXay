package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record LoginRequest(
    @NotBlank @Pattern(regexp = "0[0-9]{9,14}", message = "Số điện thoại không hợp lệ") String phoneNumber,
    @NotBlank @Size(min = 8, max = 72) String password) { }
