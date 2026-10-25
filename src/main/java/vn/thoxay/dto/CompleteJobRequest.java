package vn.thoxay.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

public record CompleteJobRequest(@NotEmpty @Size(max = 10000) List<@NotNull @Valid WorkerRating> ratings) {
    public record WorkerRating(@NotNull @Positive Long workerId, @NotNull @Min(1) @Max(5) Integer stars) { }
}
