package vn.thoxay.favorites;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController @RequestMapping("/api/users/me/team") @RequiredArgsConstructor @Validated
public class ContractorTeamController {
    private final ContractorTeamService service;
    public record Name(@NotBlank @Size(max = 80) String name) {}
    public record Invitation(@NotNull @Positive Long jobId, @NotEmpty @Size(max = 100) List<@NotNull @Positive Long> workerIds) {}
    @GetMapping("/groups") public List<ContractorTeamService.Group> groups() { return service.groups(); }
    @PostMapping("/groups") public ContractorTeamService.Group create(@Valid @RequestBody Name request) { return service.create(request.name()); }
    @DeleteMapping("/groups/{id}") public void delete(@PathVariable @Positive Long id) { service.delete(id); }
    @PutMapping("/groups/{id}/members/{workerId}") public ContractorTeamService.Group add(@PathVariable @Positive Long id, @PathVariable @Positive Long workerId) { return service.member(id, workerId, true); }
    @DeleteMapping("/groups/{id}/members/{workerId}") public ContractorTeamService.Group remove(@PathVariable @Positive Long id, @PathVariable @Positive Long workerId) { return service.member(id, workerId, false); }
    @GetMapping("/contacts") public List<ContractorTeamService.Contact> contacts() { return service.contacts(); }
    @PostMapping("/invitations") public Map<String, Boolean> invite(@Valid @RequestBody Invitation request) { service.invite(request.jobId(), request.workerIds()); return Map.of("invited", true); }
}
