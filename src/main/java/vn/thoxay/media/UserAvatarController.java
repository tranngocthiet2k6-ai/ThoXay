package vn.thoxay.media;

import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import vn.thoxay.dto.UserProfileResponse;

@RestController @RequiredArgsConstructor
public class UserAvatarController {
    private final UserAvatarService avatars;
    @PutMapping(value="/api/users/me/avatar", consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    public UserProfileResponse upload(@RequestPart MultipartFile photo) { return avatars.upload(photo); }
    @GetMapping("/api/users/{id}/avatar")
    public ResponseEntity<byte[]> read(@PathVariable Long id) {
        return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG).cacheControl(CacheControl.noStore())
            .header("X-Content-Type-Options", "nosniff").body(avatars.read(id));
    }
}
