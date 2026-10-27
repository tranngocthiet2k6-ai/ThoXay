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
import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.*;

@Service @RequiredArgsConstructor
public class KycService {
    private final CurrentUser current;
    private final EntityManager em;
    private final KycImageRepository images;

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

    private byte[] sanitize(MultipartFile file) {
        if (file.isEmpty()) throw bad("Cần đủ hai ảnh CCCD");
        if (file.getSize() > 5 * 1024 * 1024) throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "Mỗi ảnh tối đa 5 MB");
        try (var input = new javax.imageio.stream.MemoryCacheImageInputStream(new ByteArrayInputStream(file.getBytes()))) {
            var readers = ImageIO.getImageReaders(input);
            if (!readers.hasNext()) throw bad("Ảnh CCCD phải là JPEG hoặc PNG hợp lệ");
            var reader = readers.next();
            try {
                String format = reader.getFormatName();
                if (!format.equalsIgnoreCase("JPEG") && !format.equalsIgnoreCase("PNG")) throw bad("Chỉ hỗ trợ ảnh JPEG hoặc PNG");
                reader.setInput(input, true, true);
                int w = reader.getWidth(0), h = reader.getHeight(0);
                if (Math.min(w, h) < 200 || Math.max(w, h) < 320 || w > 6000 || h > 6000 || (long) w * h > 16000000)
                    throw bad("Ảnh cần rõ nét, từ 320×200 và không quá 16 triệu điểm ảnh / 6000 px mỗi cạnh");
                var source = reader.read(0);
                var clean = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
                var graphics = clean.createGraphics();
                try { graphics.setColor(Color.WHITE); graphics.fillRect(0, 0, w, h); graphics.drawImage(source, 0, 0, null); }
                finally { graphics.dispose(); source.flush(); }
                var output = new ByteArrayOutputStream();
                try { ImageIO.write(clean, "jpg", output); } finally { clean.flush(); }
                if (output.size() > 5 * 1024 * 1024) throw bad("Ảnh sau xử lý quá lớn, hãy chụp lại");
                return output.toByteArray();
            } finally { reader.dispose(); }
        } catch (IOException | IllegalArgumentException ex) { throw bad("Không đọc được ảnh CCCD. Hãy chụp lại ảnh JPEG hoặc PNG"); }
    }
    private ApiException bad(String message) { return new ApiException(HttpStatus.BAD_REQUEST, message); }
}
