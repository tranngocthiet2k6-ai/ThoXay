package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record JobRequest(
    @NotBlank @Size(max = 200) String title,
    @Size(max = 20000) String description,
    @NotBlank @Pattern(regexp = "Thợ chính|Phụ hồ|Thợ chính, Phụ hồ", message = "Chọn Thợ chính hoặc Phụ hồ") String jobType,
    @NotNull @DecimalMin(value = "200000", inclusive = false, message = "Lương phải trên 200.000 VND/ngày")
    @DecimalMax(value = "1000000000", message = "Lương không quá 1.000.000.000 VND/ngày") Double salaryPerDay,
    @NotBlank @Size(max = 255) String address,
    @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
    @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude,
    @NotNull @Min(1) @Max(10000) Integer requiredWorkers,
    java.time.LocalDate startsOn, java.time.LocalDate endsOn,
    @Min(0) @Max(10000) Integer skilledWorkers,
    @Min(0) @Max(10000) Integer helpers) {
    @AssertTrue(message = "Số thợ chính và phụ hồ phải có đủ hai ô, tổng từ 1 đến 10.000 và khớp loại thợ, tổng số thợ")
    public boolean isStaffingValid() {
        if (skilledWorkers == null && helpers == null) return !"Thợ chính, Phụ hồ".equals(jobType);
        if (skilledWorkers == null || helpers == null || skilledWorkers < 0 || helpers < 0) return false;
        int total = skilledWorkers + helpers;
        String type = skilledWorkers > 0 ? (helpers > 0 ? "Thợ chính, Phụ hồ" : "Thợ chính") : "Phụ hồ";
        return total >= 1 && total <= 10000 && java.util.Objects.equals(requiredWorkers, total) && type.equals(jobType);
    }
    public JobRequest(String title, String description, String jobType, Double salaryPerDay, String address,
                      Double latitude, Double longitude, Integer requiredWorkers,
                      java.time.LocalDate startsOn, java.time.LocalDate endsOn) {
        this(title, description, jobType, salaryPerDay, address, latitude, longitude, requiredWorkers, startsOn, endsOn, null, null);
    }
    public JobRequest(String title, String description, String jobType, Double salaryPerDay, String address,
                      Double latitude, Double longitude, Integer requiredWorkers) {
        this(title, description, jobType, salaryPerDay, address, latitude, longitude, requiredWorkers, null, null, null, null);
    }
}
