package vn.thoxay.media;
import java.time.Instant;
import java.util.UUID;
public record PhotoSummary(UUID id,String caption,Instant createdAt){}
