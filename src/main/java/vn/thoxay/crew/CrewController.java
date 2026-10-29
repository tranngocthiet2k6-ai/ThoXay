package vn.thoxay.crew;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.*;
import java.util.List;
@RestController @RequiredArgsConstructor @Validated
public class CrewController {
 private final CrewService service;
 public record Name(@NotBlank @Size(max=100) String name){}
 public record Invite(@NotBlank @Pattern(regexp="[0-9]{9,15}") String phoneNumber){}
 public record Membership(@NotNull Boolean accepted){}
 @GetMapping("/api/crews") public List<CrewService.Team> mine(){return service.mine();}
 @PostMapping("/api/crews") public CrewService.Team create(@Valid @RequestBody Name body){return service.create(body.name());}
 @PostMapping("/api/crews/{id}/invitations") public CrewService.Team invite(@PathVariable @Positive Long id,@Valid @RequestBody Invite body){return service.invite(id,body.phoneNumber());}
 @PutMapping("/api/crews/{id}/membership") public CrewService.Team membership(@PathVariable @Positive Long id,@Valid @RequestBody Membership body){return service.membership(id,body.accepted());}
 @PostMapping("/api/crews/{id}/applications") public CrewService.Batch apply(@PathVariable @Positive Long id,@Valid @RequestBody ApplicationRequest body){return service.apply(id,body);}
 @PutMapping("/api/crew-applications/{id}/status") public CrewService.Batch decide(@PathVariable @Positive Long id,@Valid @RequestBody ApplicationStatusRequest body){return service.decide(id,body);}
 @DeleteMapping("/api/crew-applications/{id}/participation") public CrewService.Batch withdraw(@PathVariable @Positive Long id){return service.withdraw(id);}
 @GetMapping("/api/jobs/{id}/crew-applications") public List<CrewService.Batch> byJob(@PathVariable @Positive Long id){return service.byJob(id);}
}
