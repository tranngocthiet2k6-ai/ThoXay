package vn.thoxay.incident;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
@RestController @RequiredArgsConstructor @Validated
public class IncidentController {
 private final IncidentService service;
 public record Report(@NotBlank @Pattern(regexp="SOS|SAFETY|PAYMENT_DISPUTE|OTHER") String type,@NotBlank @Size(max=2000) String description,@NotBlank @Pattern(regexp="[A-Za-z0-9_-]{8,80}") String clientRequestId,@DecimalMin("-90") @DecimalMax("90") Double latitude,@DecimalMin("-180") @DecimalMax("180") Double longitude){@Override public String toString(){return "IncidentReport[type="+type+",details=redacted]";}}
 public record Update(@NotBlank @Pattern(regexp="IN_REVIEW|RESOLVED") String status,@NotNull @Size(max=1000) String note,@NotNull @PositiveOrZero Long version){}
 @PostMapping("/api/jobs/{id}/incidents") public IncidentService.Detail create(@PathVariable @Positive Long id,@Valid @RequestBody Report input){return service.create(id,input);}
 @GetMapping("/api/incidents/{id}") public IncidentService.Detail get(@PathVariable @Positive Long id){return service.get(id);}
 @GetMapping("/api/incidents/me") public IncidentService.Page mine(@RequestParam(required=false) @Positive Long jobId,@RequestParam(required=false) @Positive Long beforeId){return service.mine(jobId,beforeId);}
 @GetMapping("/api/admin/incidents") public IncidentService.Page queue(@RequestParam(defaultValue="NEW") String status,@RequestParam(defaultValue="") String type,@RequestParam(defaultValue="") @Size(max=100) String q,@RequestParam(defaultValue="0") @Min(0) @Max(10000) int page){return service.queue(status,type,q,page);}
 @PutMapping("/api/admin/incidents/{id}") public IncidentService.Detail update(@PathVariable @Positive Long id,@Valid @RequestBody Update input){return service.update(id,input);}
}
