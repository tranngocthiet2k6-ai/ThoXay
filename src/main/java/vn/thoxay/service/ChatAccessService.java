package vn.thoxay.service;

import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;

@Service @RequiredArgsConstructor
public class ChatAccessService {
    private final UserRepository users;
    private final JobRepository jobs;
    private final JobApplicationRepository applications;
    private final JwtUtil jwt;

    public record Conversation(Long jobId, Long contractorId, Long workerId) { }
    public record Subscription(Long userId, Long peerId, Conversation conversation) { }

    // Also used after commit: read fresh account/application state in its own transaction.
    @Transactional(readOnly = true, propagation = Propagation.REQUIRES_NEW)
    public Subscription authenticate(String token, Long jobId, Long peerId) {
        String phone;
        try { phone = jwt.extractPhone(token); }
        catch (JwtException | IllegalArgumentException e) { throw new ApiException(HttpStatus.UNAUTHORIZED, "Phiên đăng nhập đã hết hạn"); }
        User actor = users.findByPhoneNumber(phone)
            .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Không tìm thấy tài khoản"));
        Job job = jobs.findById(jobId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Công trình không tồn tại"));
        return new Subscription(actor.getId(), peerId, authorize(actor, job, peerId));
    }

    public Conversation authorize(User actor, Job job, Long peerId) {
        if (!actor.isActive()) throw new AccountLockedException();
        if (peerId == null || peerId.equals(actor.getId())) throw forbidden();
        Long workerId;
        if (actor.getRole() == Role.ROLE_CONTRACTOR && actor.getId().equals(job.getContractor().getId())) {
            workerId = peerId;
        } else if (actor.getRole() == Role.ROLE_WORKER && peerId.equals(job.getContractor().getId())) {
            workerId = actor.getId();
        } else throw forbidden();
        if (!job.getContractor().isActive()
            || !applications.existsByJobIdAndWorkerIdAndStatus(job.getId(), workerId, ApplicationStatus.ACCEPTED)) throw forbidden();
        User worker = users.findById(workerId).orElseThrow(this::forbidden);
        if (worker.getRole() != Role.ROLE_WORKER || !worker.isActive()) throw forbidden();
        return new Conversation(job.getId(), job.getContractor().getId(), workerId);
    }
    private ApiException forbidden() {
        return new ApiException(HttpStatus.FORBIDDEN, "Chỉ chủ công trình và thợ có đơn đã được duyệt mới được nhắn tin");
    }
}
