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
    private final jakarta.persistence.EntityManager entityManager;

    public record AdminUser(Long id, String fullName, String phoneNumber, String role,
        boolean verified, boolean active, double rating, String cccdImage) { }
    public record Dashboard(List<AdminUser> users, List<JobResponse> jobs, long pendingVerification,
        long activeUsers, long openJobs) { }

    @Transactional(readOnly = true)
    public Dashboard dashboard() {
        current.require(Role.ROLE_ADMIN);
        List<AdminUser> people = users.findAll().stream().map(u -> new AdminUser(u.getId(), u.getFullName(),
            u.getPhoneNumber(), u.getRole().name(), u.isVerified(), u.isActive(), u.getRating(),
            validImage(u.getCccdImage()) ? u.getCccdImage() : null)).toList();
        List<JobResponse> listings = jobs.findAll().stream().map(j -> JobResponse.of(j, null)).toList();
        return new Dashboard(people, listings, people.stream().filter(u -> !u.verified() && u.cccdImage() != null).count(),
            people.stream().filter(AdminUser::active).count(), listings.stream().filter(j -> "OPEN".equals(j.status())).count());
    }

    @Transactional
    public void verify(Long id, String expectedImage) {
        current.require(Role.ROLE_ADMIN);
        User user = user(id);
        entityManager.refresh(user, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
        if (!validImage(user.getCccdImage())) throw new ApiException(HttpStatus.BAD_REQUEST, "Tài khoản chưa cung cấp ảnh CCCD HTTPS hợp lệ");
        if (!java.util.Objects.equals(expectedImage, user.getCccdImage()))
            throw new ApiException(HttpStatus.CONFLICT, "Ảnh CCCD đã thay đổi. Hãy tải lại và kiểm tra ảnh mới trước khi xác thực.");
        user.setVerified(true);
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
