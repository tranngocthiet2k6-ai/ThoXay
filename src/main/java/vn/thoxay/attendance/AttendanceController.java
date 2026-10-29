package vn.thoxay.attendance;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.*;
import lombok.RequiredArgsConstructor;
import java.time.LocalDate;
import java.util.Map;
@RestController @RequiredArgsConstructor @Validated
public class AttendanceController {
 private final AttendanceService service;
 public record Proof(@DecimalMin("-90") @DecimalMax("90") Double latitude,@DecimalMin("-180") @DecimalMax("180") Double longitude,@Positive Double accuracyMeters,@Size(max=128) String qrToken){@Override public String toString(){return "AttendanceProof[redacted]";}}
 public record Review(@NotNull Boolean approved,@NotNull @Size(max=500) String feedback,@NotNull @PositiveOrZero Long version){}
 @GetMapping("/api/applications/{id}/attendance") public AttendanceService.Page history(@PathVariable @Positive Long id,@RequestParam(required=false) LocalDate beforeDay){return service.history(id,beforeDay);}
 @GetMapping("/api/jobs/{id}/attendance") public AttendanceService.Page byJob(@PathVariable @Positive Long id,@RequestParam(required=false) LocalDate day,@RequestParam(defaultValue="0") @Min(0) @Max(1000) int page){return service.byJob(id,day,page);}
 @PostMapping("/api/jobs/{id}/attendance/shift-code") public AttendanceService.Code code(@PathVariable @Positive Long id){return service.issue(id);}
 @PostMapping("/api/applications/{id}/attendance/check-in") public AttendanceService.Page checkIn(@PathVariable @Positive Long id,@Valid @RequestBody Proof proof){return service.mark(id,proof,false);}
 @PostMapping("/api/applications/{id}/attendance/check-out") public AttendanceService.Page checkOut(@PathVariable @Positive Long id,@Valid @RequestBody Proof proof){return service.mark(id,proof,true);}
 @PostMapping(value="/api/applications/{id}/work-logs",consumes=MediaType.MULTIPART_FORM_DATA_VALUE) public AttendanceService.Page upload(@PathVariable @Positive Long id,@RequestParam LocalDate day,@RequestPart MultipartFile photo,@RequestParam(defaultValue="") @Size(max=1000) String caption){return service.upload(id,day,photo,caption);}
 @PutMapping("/api/work-logs/{id}/review") public Map<String,Boolean> review(@PathVariable @Positive Long id,@Valid @RequestBody Review body){service.review(id,body.approved(),body.feedback(),body.version());return Map.of("reviewed",true);}
 @GetMapping("/api/work-logs/{id}/photo") public ResponseEntity<byte[]> photo(@PathVariable @Positive Long id){return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG).cacheControl(CacheControl.noStore()).header("X-Content-Type-Options","nosniff").body(service.photo(id));}
}
