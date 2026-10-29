package vn.thoxay.kyc;

import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import vn.thoxay.dto.UserProfileResponse;
import vn.thoxay.entity.Role;
import vn.thoxay.exception.ApiException;
import vn.thoxay.security.CurrentUser;
import java.util.*;

@Service @RequiredArgsConstructor
public class KycService {
    private final CurrentUser current;
    private final EntityManager em;
    private final KycImageRepository images;
    private final vn.thoxay.media.ImageSanitizer sanitizer;

    @Transactional
    public UserProfileResponse upload(MultipartFile front, MultipartFile back) {
        var user = current.get();
        if (user.getRole() != Role.ROLE_WORKER && user.getRole() != Role.ROLE_CONTRACTOR)
            throw new ApiException(HttpStatus.FORBIDDEN, "Chỉ thợ và chủ thầu được gửi hồ sơ CCCD");
        // Validate BOTH before replacing anything. Decode and re-encode to strip metadata.
        byte[] frontBytes = sanitize(front), backBytes = sanitize(back);
        if (Arrays.equals(frontBytes, backBytes))
            throw bad("Hãy chụp riêng mặt trước và mặt sau CCCD");
        em.refresh(user, LockModeType.PESSIMISTIC_WRITE);
        images.deleteForUser(user.getId());
        KycImage f = new KycImage(), b = new KycImage();
        f.setUser(user); f.setContent(frontBytes); b.setUser(user); b.setContent(backBytes);
        images.saveAll(List.of(f, b));
        user.setCccdFrontImage(f.url()); user.setCccdBackImage(b.url()); user.setVerified(false);
        return UserProfileResponse.of(user);
    }

    @Transactional(readOnly = true)
    public byte[] read(UUID id, boolean adminOnly) {
        var user = current.get();
        if (adminOnly && user.getRole() != Role.ROLE_ADMIN)
            throw new ApiException(HttpStatus.FORBIDDEN, "Chỉ quản trị viên được xem hồ sơ này");
        var image = images.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy ảnh CCCD"));
        if (user.getRole() != Role.ROLE_ADMIN && !image.getUser().getId().equals(user.getId()))
            throw new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy ảnh CCCD");
        return image.getContent();
    }

    private byte[] sanitize(MultipartFile file) { return sanitizer.kyc(file); }
    private ApiException bad(String message) { return new ApiException(HttpStatus.BAD_REQUEST, message); }
}
