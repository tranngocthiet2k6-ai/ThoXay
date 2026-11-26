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
import java.util.ArrayList;
import java.util.List;
import vn.thoxay.dto.JobResponse;
import vn.thoxay.entity.Job;

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
        var blockers = blockers(user.getId());
        if (!blockers.isEmpty()) throw new ApiException(HttpStatus.CONFLICT, switch (blockers.get(0).reason()) {
            case "OPEN_JOB" -> "Bạn còn công trình đang tuyển hoặc thi công. Hãy dừng tuyển nếu không còn thợ, hoặc hoàn tất công việc trước khi chuyển vai trò.";
            case "OPEN_APPLICATION" -> "Bạn còn đơn ứng tuyển hoặc công việc đang xử lý. Hãy hoàn tất hoặc nhờ chủ thầu xử lý đơn trước khi chuyển vai trò.";
            default -> "Còn công trình hoàn thành chưa chốt thanh toán. Chủ thầu cần thanh toán tiền công trước khi chuyển vai trò.";
        });
        user.setRole(target); user.setAvailable(false); user.setSecurityVersion(user.getSecurityVersion() + 1);
        devices.deleteByUserId(user.getId());
        return session(user);
    }
    public record RoleBlocker(String reason, JobResponse job, boolean owner) { }
    @Transactional(readOnly=true) public List<RoleBlocker> roleBlockers() {
        User user = current.get();
        if (user.getRole() == Role.ROLE_ADMIN) throw new ApiException(HttpStatus.FORBIDDEN, "Admin không chuyển vai trò công khai");
        return blockers(user.getId());
    }
    private List<RoleBlocker> blockers(Long id) {
        List<RoleBlocker> result = new ArrayList<>();
        var openJobs = em.createQuery("select j from Job j where j.contractor.id=:id and j.status in (vn.thoxay.entity.JobStatus.OPEN,vn.thoxay.entity.JobStatus.IN_PROGRESS) "
            + "and (j.recruitmentClosed=false or exists (select a.id from JobApplication a where a.job=j and a.status=vn.thoxay.entity.ApplicationStatus.ACCEPTED)) order by j.id", Job.class)
            .setParameter("id", id).getResultList();
        for (Job job : openJobs) result.add(new RoleBlocker("OPEN_JOB", JobResponse.of(job,null,true), true));
        var openApplications = em.createQuery("select a from JobApplication a join fetch a.job where a.worker.id=:id and a.status in (vn.thoxay.entity.ApplicationStatus.PENDING,vn.thoxay.entity.ApplicationStatus.ACCEPTED) "
            + "and a.job.status in (vn.thoxay.entity.JobStatus.OPEN,vn.thoxay.entity.JobStatus.IN_PROGRESS) order by a.id", vn.thoxay.entity.JobApplication.class)
            .setParameter("id", id).getResultList();
        for (var application : openApplications) result.add(new RoleBlocker("OPEN_APPLICATION", JobResponse.of(application.getJob(),null,application.getStatus()==vn.thoxay.entity.ApplicationStatus.ACCEPTED), false));
        var unpaid = em.createQuery("select distinct j from JobApplication a join a.job j where (a.worker.id=:id or j.contractor.id=:id) and a.status=vn.thoxay.entity.ApplicationStatus.ACCEPTED "
            + "and j.status=vn.thoxay.entity.JobStatus.COMPLETED and not exists (select p.id from JobPayment p where p.application.id=a.id) order by j.id", Job.class)
            .setParameter("id", id).getResultList();
        for (Job job : unpaid) result.add(new RoleBlocker("UNPAID_WORK", JobResponse.of(job,null,true), job.getContractor().getId().equals(id)));
        return result;
    }
    @Transactional public PushPreferences notifications(PushPreferences request) {
        User user = locked(); user.setJobPushEnabled(request.jobPushEnabled()); user.setChatPushEnabled(request.chatPushEnabled());
        return request;
    }
}
