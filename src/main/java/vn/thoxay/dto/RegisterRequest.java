package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record RegisterRequest(
    @NotBlank @Pattern(regexp = "0[0-9]{9,14}", message = "Số điện thoại không hợp lệ") String phoneNumber,
    @NotBlank @Size(min = 8, max = 72) String password,
    @NotBlank @Size(max = 100) String fullName,
    @NotBlank @Pattern(regexp = "ROLE_WORKER|ROLE_CONTRACTOR", message = "Vai trò đăng ký không hợp lệ") String role,
    @Size(max = 500) @Pattern(regexp = "https://[^\\s]+|^$", message = "Ảnh mặt trước CCCD phải là URL HTTPS") String cccdFrontImage,
    @Size(max = 500) @Pattern(regexp = "https://[^\\s]+|^$", message = "Ảnh mặt sau CCCD phải là URL HTTPS") String cccdBackImage) { }
