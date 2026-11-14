package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.controller.AccountSettingsController.*;
import vn.thoxay.dto.AuthResponse;
import vn.thoxay.entity.User;
import vn.thoxay.entity.Role;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.*;
import java.nio.charset.StandardCharsets;

@Service @RequiredArgsConstructor
public class AccountSettingsService {
    private final CurrentUser current;
    private final UserRepository users;
    private final vn.thoxay.repository.DeviceTokenRepository devices;
    private final BCryptPasswordEncoder encoder;
    private final JwtUtil jwt;
    private final jakarta.persistence.EntityManager em;
    private User locked() {
        User user = current.get();
        em.refresh(user, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
        if (!user.isActive()) throw new vn.thoxay.exception.AccountLockedException();
        return user;
    }
    private void confirm(User user, String password) {
        if (password.getBytes(StandardCharsets.UTF_8).length > 72 || !encoder.matches(password, user.getPassword()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Mật khẩu hiện tại không đúng");
    }
    private AuthResponse session(User user) {
        users.saveAndFlush(user);
        return AuthResponse.of(jwt.generateToken(user.getPhoneNumber(), user.getSecurityVersion(), user.getId()), jwt.expiresInSeconds(), user);
    }
    @Transactional public AuthResponse password(PasswordRequest request) {
        User user = locked(); confirm(user, request.currentPassword());
        String password = request.newPassword();
        if (password.getBytes(StandardCharsets.UTF_8).length > 72 || !password.matches("(?s).*[\\p{L}].*") || !password.matches("(?s).*[0-9].*"))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Mật khẩu cần ít nhất 8 ký tự, có chữ và số, tối đa 72 byte UTF-8");
        if (encoder.matches(password, user.getPassword())) throw new ApiException(HttpStatus.BAD_REQUEST, "Mật khẩu mới phải khác mật khẩu hiện tại");
        user.setPassword(encoder.encode(password)); user.setSecurityVersion(user.getSecurityVersion() + 1);
        devices.deleteByUserId(user.getId());
        return session(user);
    }
    @Transactional public AuthResponse phone(PhoneRequest request) {
        User user = locked(); confirm(user, request.currentPassword());
        if (request.phoneNumber().equals(user.getPhoneNumber())) return session(user);
        if (users.existsByPhoneNumber(request.phoneNumber())) throw new ApiException(HttpStatus.CONFLICT, "Số điện thoại đã được đăng ký");
        user.setPhoneNumber(request.phoneNumber()); user.setSecurityVersion(user.getSecurityVersion() + 1);
        devices.deleteByUserId(user.getId());
        return session(user);
    }
    @Transactional(readOnly=true) public PushPreferences notifications() {
        User user = current.get(); return new PushPreferences(user.isJobPushEnabled(), user.isChatPushEnabled());
    }
    @Transactional public AuthResponse role(RoleRequest request) {
        User user = locked();
        if (user.getRole() == Role.ROLE_ADMIN) throw new ApiException(HttpStatus.FORBIDDEN, "Admin không thể chuyển sang vai trò công khai");
        Role target = Role.valueOf(request.role());
        if (target == user.getRole()) return session(user);
        long openJobs = em.createQuery("select count(j) from Job j where j.contractor.id=:id and j.status in (vn.thoxay.entity.JobStatus.OPEN,vn.thoxay.entity.JobStatus.IN_PROGRESS)", Long.class)
            .setParameter("id", user.getId()).getSingleResult();
        long openApplications = em.createQuery("select count(a) from JobApplication a where a.worker.id=:id and a.status in (vn.thoxay.entity.ApplicationStatus.PENDING,vn.thoxay.entity.ApplicationStatus.ACCEPTED) and a.job.status in (vn.thoxay.entity.JobStatus.OPEN,vn.thoxay.entity.JobStatus.IN_PROGRESS)", Long.class)
            .setParameter("id", user.getId()).getSingleResult();
        long unpaid = em.createQuery("select count(a) from JobApplication a where (a.worker.id=:id or a.job.contractor.id=:id) and a.status=vn.thoxay.entity.ApplicationStatus.ACCEPTED and a.job.status=vn.thoxay.entity.JobStatus.COMPLETED and not exists (select p.id from JobPayment p where p.application.id=a.id)", Long.class)
            .setParameter("id", user.getId()).getSingleResult();
        if (openJobs > 0) throw new ApiException(HttpStatus.CONFLICT, "Bạn còn công trình đang tuyển hoặc thi công. Hãy hoàn tất công việc hoặc liên hệ Admin xử lý trước khi chuyển vai trò.");
        if (openApplications > 0) throw new ApiException(HttpStatus.CONFLICT, "Bạn còn đơn ứng tuyển hoặc công việc đang xử lý. Hãy hoàn tất hoặc nhờ chủ thầu xử lý đơn trước khi chuyển vai trò.");
        if (unpaid > 0) throw new ApiException(HttpStatus.CONFLICT, "Còn công trình hoàn thành chưa chốt thanh toán. Hãy đối soát thanh toán trước khi chuyển vai trò.");
        user.setRole(target); user.setAvailable(false); user.setSecurityVersion(user.getSecurityVersion() + 1);
        devices.deleteByUserId(user.getId());
        return session(user);
    }
    @Transactional public PushPreferences notifications(PushPreferences request) {
        User user = locked(); user.setJobPushEnabled(request.jobPushEnabled()); user.setChatPushEnabled(request.chatPushEnabled());
        return request;
    }
}
