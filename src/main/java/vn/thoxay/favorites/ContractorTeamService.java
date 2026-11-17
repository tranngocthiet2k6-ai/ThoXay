package vn.thoxay.favorites;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.service.NotificationService;
import java.time.*;
import java.util.*;

@Service @RequiredArgsConstructor
public class ContractorTeamService {
    private final ContractorGroupRepository groups;
    private final ContractorGroupMemberRepository members;
    private final SavedWorkerRepository saved;
    private final UserRepository users;
    private final JobRepository jobs;
    private final JobApplicationRepository applications;
    private final CurrentUser current;
    private final NotificationService notices;
    private final Clock clock;
    public record Group(Long id, String name, List<WorkerProfileResponse> members) {}
    public record Contact(Long workerId, Long applicationId, JobResponse job, String phoneNumber) {}

    @Transactional(readOnly = true)
    public List<Group> groups() {
        return groups.findByOwnerIdOrderByIdDesc(current.require(Role.ROLE_CONTRACTOR).getId()).stream().map(this::view).toList();
    }

    @Transactional
    public Group create(String rawName) {
        var owner = current.require(Role.ROLE_CONTRACTOR);
        users.findLockedById(owner.getId()).orElseThrow();
        String name = rawName.strip();
        if (name.isEmpty() || name.length() > 80) throw conflict("Tên nhóm từ 1 đến 80 ký tự");
        if (groups.countByOwnerId(owner.getId()) >= 30) throw conflict("Tối đa 30 nhóm thợ");
        if (groups.existsByOwnerIdAndNameIgnoreCase(owner.getId(), name)) throw conflict("Tên nhóm đã tồn tại");
        var group = new ContractorGroup(); group.setOwner(owner); group.setName(name);
        groups.saveAndFlush(group); return view(group);
    }

    @Transactional
    public void delete(Long id) { groups.delete(owned(id)); }

    @Transactional
    public Group member(Long id, Long workerId, boolean add) {
        var group = owned(id);
        var old = members.findByGroupIdAndSavedWorkerWorkerId(id, workerId);
        if (!add) { old.ifPresent(members::delete); members.flush(); return view(group); }
        var person = saved.findByOwnerIdAndWorkerId(group.getOwner().getId(), workerId)
            .filter(s -> s.getWorker().isActive() && s.getWorker().getRole() == Role.ROLE_WORKER)
            .orElseThrow(() -> conflict("Hãy lưu tài khoản thợ đang hoạt động trước khi thêm vào nhóm"));
        if (old.isPresent()) return view(group);
        if (members.countByGroupId(id) >= 100) throw conflict("Tối đa 100 thợ trong nhóm");
        var row = new ContractorGroupMember(); row.setGroup(group); row.setSavedWorker(person);
        members.saveAndFlush(row); return view(group);
    }

    @Transactional(readOnly = true)
    public List<Contact> contacts() {
        var owner = current.require(Role.ROLE_CONTRACTOR);
        return applications.findByJobContractorIdAndStatusOrderByAppliedAtDesc(owner.getId(), ApplicationStatus.ACCEPTED).stream()
            .filter(a -> a.getWorker().isActive())
            .map(a -> new Contact(a.getWorker().getId(), a.getId(), JobResponse.of(a.getJob(), null, false), a.getWorker().getPhoneNumber())).toList();
    }

    /** An invitation creates a notification only. Each worker must apply and accept the terms. */
    @Transactional
    public void invite(Long jobId, List<Long> workerIds) {
        var owner = current.require(Role.ROLE_CONTRACTOR);
        var job = jobs.findLockedById(jobId).orElseThrow(this::missing);
        current.requireOwner(job.getContractor().getId(), Role.ROLE_CONTRACTOR);
        if (!List.of(JobStatus.OPEN, JobStatus.IN_PROGRESS).contains(job.getStatus())
            || (job.getEndsOn() != null && job.getEndsOn().isBefore(LocalDate.now(clock)))
            || applications.countByJobIdAndStatus(jobId, ApplicationStatus.ACCEPTED) >= job.getRequiredWorkers()) {
            throw conflict("Công trình không còn nhận ứng tuyển");
        }
        var recipients = workerIds.stream().distinct().map(id -> saved.findByOwnerIdAndWorkerId(owner.getId(), id)
            .map(SavedWorker::getWorker).filter(u -> u.isActive() && u.getRole() == Role.ROLE_WORKER)
            .orElseThrow(() -> conflict("Chỉ mời thợ đang hoạt động trong danh sách đã lưu"))).toList();
        for (var worker : recipients) {
            if (!applications.existsByJobIdAndWorkerId(jobId, worker.getId())) {
                notices.create(worker, job, "team-job-invite:" + jobId + ":" + worker.getId(), "JOB_INVITATION",
                    "Lời mời công trình", owner.getFullName() + " mời bạn xem công trình: " + job.getTitle() + ". Mở công trình để đọc cam kết và ứng tuyển.");
            }
        }
    }

    private ContractorGroup owned(Long id) {
        return groups.owned(id, current.require(Role.ROLE_CONTRACTOR).getId()).orElseThrow(this::missing);
    }
    private Group view(ContractorGroup group) {
        return new Group(group.getId(), group.getName(), members.findByGroupIdOrderByIdAsc(group.getId()).stream()
            .map(m -> m.getSavedWorker().getWorker()).filter(u -> u.isActive() && u.getRole() == Role.ROLE_WORKER)
            .map(WorkerProfileResponse::of).toList());
    }
    private ApiException missing() { return new ApiException(HttpStatus.NOT_FOUND, "Nhóm thợ hoặc công trình không tồn tại"); }
    private ApiException conflict(String message) { return new ApiException(HttpStatus.CONFLICT, message); }
}
