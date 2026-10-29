package vn.thoxay.favorites;
import lombok.RequiredArgsConstructor;
import jakarta.validation.constraints.Positive;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import vn.thoxay.dto.*;
import java.util.*;
@RestController @RequestMapping("/api/users/me/saved") @RequiredArgsConstructor @Validated
public class FavoriteController {
    private final FavoriteService service;
    @GetMapping("/jobs") public List<JobResponse> jobs(){return service.jobs();}
    @PutMapping("/jobs/{id}") public Map<String,Boolean> saveJob(@PathVariable @Positive Long id){service.job(id,true);return Map.of("saved",true);}
    @DeleteMapping("/jobs/{id}") public Map<String,Boolean> removeJob(@PathVariable @Positive Long id){service.job(id,false);return Map.of("saved",false);}
    @GetMapping("/workers") public List<WorkerProfileResponse> workers(){return service.workers();}
    @PutMapping("/workers/{id}") public Map<String,Boolean> saveWorker(@PathVariable @Positive Long id){service.worker(id,true);return Map.of("saved",true);}
    @DeleteMapping("/workers/{id}") public Map<String,Boolean> removeWorker(@PathVariable @Positive Long id){service.worker(id,false);return Map.of("saved",false);}
}
