package vn.thoxay.media;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.*;
@RestController @RequiredArgsConstructor @Validated
public class PortfolioController {
 private final PortfolioService service;
 @GetMapping("/api/users/{id}/portfolio") public List<PhotoSummary> list(@PathVariable @Positive Long id){return service.list(id);}
 @PostMapping(value="/api/users/me/portfolio",consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
 public PhotoSummary upload(@RequestPart MultipartFile photo,@RequestParam(defaultValue="") @Size(max=160) String caption){return service.upload(photo,caption);}
 @GetMapping("/api/portfolio/photos/{id}") public ResponseEntity<byte[]> read(@PathVariable UUID id){return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG).cacheControl(CacheControl.noStore()).header("X-Content-Type-Options","nosniff").body(service.read(id));}
 @DeleteMapping("/api/users/me/portfolio/{id}") public Map<String,Boolean> delete(@PathVariable UUID id){service.delete(id);return Map.of("deleted",true);}
}
