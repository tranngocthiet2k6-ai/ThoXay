package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.*;
import vn.thoxay.security.CurrentUser;

@Service @RequiredArgsConstructor
public class UserProfileService {
    private final CurrentUser current;
    private final jakarta.persistence.EntityManager entityManager;

    @Transactional(readOnly = true)
    public UserProfileResponse profile() { return UserProfileResponse.of(current.get()); }

    @Transactional
    public UserProfileResponse updateCccd(CccdRequest request) {
        var user = current.get();
        entityManager.refresh(user, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
        user.setCccdFrontImage(request.cccdFrontImage());
        user.setCccdBackImage(request.cccdBackImage());
        user.setVerified(false);
        return UserProfileResponse.of(user);
    }
}
