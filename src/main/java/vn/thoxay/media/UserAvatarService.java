package vn.thoxay.media;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.HttpStatus;
import vn.thoxay.dto.UserProfileResponse;
import vn.thoxay.entity.Role;
import vn.thoxay.exception.*;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.CurrentUser;

@Service @RequiredArgsConstructor
public class UserAvatarService {
    private final CurrentUser current;
    private final UserRepository users;
    private final UserAvatarRepository avatars;
    private final ImageSanitizer images;
    private final jakarta.persistence.EntityManager em;
    @Transactional public UserProfileResponse upload(MultipartFile photo) {
        var user = current.get();
        byte[] content = images.avatar(photo);
        em.refresh(user, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
        if (!user.isActive()) throw new AccountLockedException();
        if (user.getRole() == Role.ROLE_ADMIN) throw new ApiException(HttpStatus.FORBIDDEN, "Admin không có hồ sơ nghề nghiệp");
        var avatar = avatars.findByUserId(user.getId()).orElseGet(UserAvatar::new);
        avatar.setUser(user); avatar.setContent(content); avatars.saveAndFlush(avatar);
        user.setAvatarVersion(java.util.UUID.randomUUID());
        return UserProfileResponse.of(user);
    }
    @Transactional(readOnly=true) public byte[] read(Long id) {
        current.get();
        var user = users.findById(id).filter(u -> u.isActive() && u.getRole() != Role.ROLE_ADMIN)
            .orElseThrow(this::missing);
        return avatars.findByUserId(user.getId()).orElseThrow(this::missing).getContent();
    }
    private ApiException missing() { return new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy ảnh đại diện"); }
}
