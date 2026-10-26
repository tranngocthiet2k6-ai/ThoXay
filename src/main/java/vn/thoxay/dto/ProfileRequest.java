package vn.thoxay.dto;

import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.List;

public record ProfileRequest(@NotBlank @Size(max = 100) String fullName, @Past LocalDate dateOfBirth,
    @NotNull @Min(0) @Max(60) Integer experienceYears, @Size(max = 2000) String experienceSummary,
    @NotNull @Size(max = 20) List<@NotBlank @Size(max = 50) String> skills,
    @NotNull @Size(max = 10) List<@NotBlank @Size(max = 500) @Pattern(regexp = "https://[^\\s]+") String> projectImages) { }
