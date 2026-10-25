package vn.thoxay.dto;

import jakarta.validation.constraints.*;

public record MessageRequest(@NotNull @Positive Long recipientId,
    @NotBlank @Size(max = 2000) String content,
    @NotBlank @Pattern(regexp = "[A-Za-z0-9_-]{1,64}") String clientMessageId) { }
