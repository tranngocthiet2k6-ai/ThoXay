package vn.thoxay.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.JobResponse;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.service.WorkerRatingService;
import java.util.List;

@Service @RequiredArgsConstructor
public class AdminService {
    private final UserRepository users;
    private final JobRepository jobs;
    private final JobApplicationRepository applications;
    private final CurrentUser current;
    private final WorkerRatingService ratings;
    private final vn.thoxay.service.NotificationService notifications;
    private final jakarta.persistence.EntityManager entityManager;

    public record AdminUser(Long id, String fullName, String phoneNumber, String role,
        boolean verified, boolean active, double rating, String cccdFrontImage, String cccdBackImage,
        boolean cccdComplete) { }
    public record Dashboard(List<AdminUser> users, List<JobResponse> jobs, long pendingVerification,
        long activeUsers, long openJobs) {
        public long verifiedUsers() { return users.stream().filter(AdminUser::verified).count(); }
        public long verificationRate() { return users.isEmpty() ? 0 : Math.round(verifiedUsers() * 100.0 / users.size()); }
    }

    @Transactional(readOnly = true)
    public Dashboard dashboard() {
        current.require(Role.ROLE_ADMIN);
        List<AdminUser> people = users.findAll().stream().map(u -> new AdminUser(u.getId(), u.getFullName(),
            u.getPhoneNumber(), u.getRole().name(), u.isVerified(), u.isActive(), u.getRating(),
            validImage(u.getCccdFrontImage()) ? u.getCccdFrontImage() : null,
            validImage(u.getCccdBackImage()) ? u.getCccdBackImage() : null, u.hasCompleteCccd())).toList();
        List<JobResponse> listings = jobs.findAll().stream().map(j -> JobResponse.of(j, null)).toList();
        return new Dashboard(people, listings, people.stream().filter(u -> !u.verified() && u.cccdComplete()).count(),
            people.stream().filter(AdminUser::active).count(), listings.stream().filter(j -> "OPEN".equals(j.status())).count());
    }

    @Transactional
    public void verify(Long id, String expectedFrontImage, String expectedBackImage) {
        current.require(Role.ROLE_ADMIN);
        User user = user(id);
        entityManager.refresh(user, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
        if (!user.hasCompleteCccd())
            throw new ApiException(HttpStatus.BAD_REQUEST, "Tài khoản phải cung cấp đủ ảnh mặt trước và mặt sau CCCD HTTPS hợp lệ");
        if (!java.util.Objects.equals(expectedFrontImage, user.getCccdFrontImage())
            || !java.util.Objects.equals(expectedBackImage, user.getCccdBackImage()))
            throw new ApiException(HttpStatus.CONFLICT, "Ảnh CCCD đã thay đổi. Hãy tải lại và kiểm tra cả hai ảnh mới trước khi xác thực.");
        if (!user.isVerified()) {
            user.setVerified(true);
            notifications.create(user, null, "kyc:" + id + ":" + vn.thoxay.service.NotificationService.hash(expectedFrontImage + "\n" + expectedBackImage),
                "KYC_VERIFIED", "Danh tính đã được xác thực", "Hồ sơ CCCD hai mặt của bạn đã được quản trị viên xác thực thành công.");
        }
    }
    @Transactional
    public void toggleActive(Long id) {
        User admin = current.require(Role.ROLE_ADMIN);
        if (admin.getId().equals(id)) throw new ApiException(HttpStatus.CONFLICT, "Bạn không thể tự khóa tài khoản đang sử dụng");
        User user = user(id);
        if (user.getRole() == Role.ROLE_ADMIN)
            throw new ApiException(HttpStatus.CONFLICT, "Không thể khóa tài khoản quản trị viên");
        user.setActive(!user.isActive());
    }
    @Transactional
    public void deleteJob(Long id) {
        current.require(Role.ROLE_ADMIN);
        Job job = jobs.findLockedById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Công trình không tồn tại"));
        List<User> workers = ratings.lockWorkers(applications.findByJobIdOrderByAppliedAtDesc(id).stream()
            .filter(a -> a.getWorkerRating() != null).map(a -> a.getWorker().getId()).toList());
        applications.deleteByJobId(id); applications.flush(); jobs.delete(job);
        ratings.recompute(workers);
    }
    private User user(Long id) {
        return users.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Tài khoản không tồn tại"));
    }
    private boolean validImage(String url) { return url != null && url.matches("https://[^\\s]+"); }
}
