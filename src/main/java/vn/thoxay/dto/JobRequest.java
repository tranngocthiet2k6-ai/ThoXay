package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record JobRequest(
    @NotBlank @Size(max = 200) String title,
    @Size(max = 20000) String description,
    @NotBlank @Pattern(regexp = "Thợ chính|Phụ hồ", message = "Chọn Thợ chính hoặc Phụ hồ") String jobType,
    @NotNull @DecimalMin("1") @DecimalMax("1000000000") Double salaryPerDay,
    @NotBlank @Size(max = 255) String address,
    @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
    @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude,
    @NotNull @Min(1) @Max(10000) Integer requiredWorkers,
    java.time.LocalDate startsOn, java.time.LocalDate endsOn) {
    public JobRequest(String title, String description, String jobType, Double salaryPerDay, String address,
                      Double latitude, Double longitude, Integer requiredWorkers) {
        this(title, description, jobType, salaryPerDay, address, latitude, longitude, requiredWorkers, null, null);
    }
}
