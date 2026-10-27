package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.*;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.entity.Role;
import vn.thoxay.exception.ApiException;
import org.springframework.http.HttpStatus;
import java.util.ArrayList;
import java.util.Objects;

@Service @RequiredArgsConstructor
public class UserProfileService {
    private final CurrentUser current;
    private final jakarta.persistence.EntityManager entityManager;
    private final UserRepository users;
    private final vn.thoxay.kyc.KycImageRepository images;

    @Transactional(readOnly = true)
    public UserProfileResponse profile() { return UserProfileResponse.of(current.get()); }

    @Transactional
    public UserProfileResponse update(ProfileRequest request) {
        var user = current.get();
        entityManager.refresh(user, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
        String name = request.fullName().strip();
        if (name.isBlank() || request.skills().stream().anyMatch(String::isBlank))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Họ tên và kỹ năng không được để trống");
        if (!Objects.equals(name, user.getFullName()) || !Objects.equals(request.dateOfBirth(), user.getDateOfBirth())) user.setVerified(false);
        user.setFullName(name); user.setDateOfBirth(request.dateOfBirth()); user.setExperienceYears(request.experienceYears());
        user.setExperienceSummary(request.experienceSummary() == null ? "" : request.experienceSummary().strip());
        user.setSkills(new ArrayList<>(request.skills().stream().map(String::strip).distinct().toList()));
        user.setProjectImages(new ArrayList<>(request.projectImages().stream().distinct().toList()));
        return UserProfileResponse.of(user);
    }
    @Transactional(readOnly = true)
    public WorkerProfileResponse worker(Long id) {
        current.get();
        var user = users.findById(id).filter(u -> u.getRole() == Role.ROLE_WORKER && u.isActive())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy hồ sơ thợ đang hoạt động"));
        return WorkerProfileResponse.of(user);
    }

    @Transactional
    public UserProfileResponse updateCccd(CccdRequest request) {
        var user = current.get();
        entityManager.refresh(user, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
        images.deleteForUser(user.getId());
        user.setCccdFrontImage(request.cccdFrontImage());
        user.setCccdBackImage(request.cccdBackImage());
        user.setVerified(false);
        return UserProfileResponse.of(user);
    }
}
