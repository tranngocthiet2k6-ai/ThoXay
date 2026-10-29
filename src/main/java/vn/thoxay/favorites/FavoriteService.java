package vn.thoxay.favorites;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.dto.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import java.util.List;

@Service @RequiredArgsConstructor
public class FavoriteService {
    private final SavedJobRepository savedJobs;
    private final SavedWorkerRepository savedWorkers;
    private final JobRepository jobs;
    private final UserRepository users;
    private final CurrentUser current;
    private static final int LIMIT=300;
    @Transactional(readOnly=true)
    public List<JobResponse> jobs() {
        var owner=current.require(Role.ROLE_WORKER);
        return savedJobs.findByOwnerIdOrderByIdDesc(owner.getId(),PageRequest.of(0,LIMIT)).stream()
            .filter(s->s.getJob().getContractor().isActive()).map(s->JobResponse.of(s.getJob(),null,false)).toList();
    }
    @Transactional(readOnly=true)
    public List<WorkerProfileResponse> workers() {
        var owner=current.require(Role.ROLE_CONTRACTOR);
        return savedWorkers.findByOwnerIdOrderByIdDesc(owner.getId(),PageRequest.of(0,LIMIT)).stream()
            .filter(s->s.getWorker().isActive()).map(s->WorkerProfileResponse.of(s.getWorker())).toList();
    }
    @Transactional
    public void job(Long id,boolean saved) {
        var owner=current.require(Role.ROLE_WORKER);
        // Serialize same owner's upserts; no job lock is acquired after this user lock.
        users.findLockedById(owner.getId()).orElseThrow();
        var existing=savedJobs.findByOwnerIdAndJobId(owner.getId(),id);
        if(!saved) { existing.ifPresent(savedJobs::delete); return; }
        if(existing.isPresent()) return;
        var job=jobs.findById(id).filter(j->j.getContractor().isActive()).orElseThrow(FavoriteService::notFound);
        capacity(savedJobs.countByOwnerId(owner.getId()));
        var item=new SavedJob();item.setOwner(owner);item.setJob(job);savedJobs.saveAndFlush(item);
    }
    @Transactional
    public void worker(Long id,boolean saved) {
        var owner=current.require(Role.ROLE_CONTRACTOR);
        users.findLockedById(owner.getId()).orElseThrow();
        var existing=savedWorkers.findByOwnerIdAndWorkerId(owner.getId(),id);
        if(!saved) { existing.ifPresent(savedWorkers::delete); return; }
        if(existing.isPresent()) return;
        var worker=users.findById(id).filter(u->u.isActive()&&u.getRole()==Role.ROLE_WORKER).orElseThrow(FavoriteService::notFound);
        capacity(savedWorkers.countByOwnerId(owner.getId()));
        var item=new SavedWorker();item.setOwner(owner);item.setWorker(worker);savedWorkers.saveAndFlush(item);
    }
    private static void capacity(long count) { if(count>=LIMIT) throw new ApiException(HttpStatus.CONFLICT,"Danh sách đã đủ 300 mục; hãy bỏ lưu mục cũ trước"); }
    private static ApiException notFound() { return new ApiException(HttpStatus.NOT_FOUND,"Không tìm thấy mục cần lưu"); }
}
