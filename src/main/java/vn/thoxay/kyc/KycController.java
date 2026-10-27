package vn.thoxay.kyc;

import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import vn.thoxay.dto.UserProfileResponse;
import java.util.UUID;

@RestController @RequiredArgsConstructor
public class KycController {
    private final KycService service;
    @PostMapping(value = "/api/users/me/cccd/photos", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public UserProfileResponse upload(@RequestPart MultipartFile front, @RequestPart MultipartFile back) {
        return service.upload(front, back);
    }
    @GetMapping("/api/users/me/cccd/images/{id}")
    public ResponseEntity<byte[]> own(@PathVariable UUID id) { return response(service.read(id, false)); }
    @GetMapping("/admin/kyc/images/{id}")
    public ResponseEntity<byte[]> admin(@PathVariable UUID id) { return response(service.read(id, true)); }
    private ResponseEntity<byte[]> response(byte[] bytes) {
        return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG).cacheControl(CacheControl.noStore())
            .header("Content-Disposition", "inline; filename=cccd.jpg").header("X-Content-Type-Options", "nosniff")
            .header("Referrer-Policy", "no-referrer").body(bytes);
    }
}
