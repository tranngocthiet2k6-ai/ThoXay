package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import vn.thoxay.entity.*;
import vn.thoxay.repository.ReputationEventRepository;
import vn.thoxay.security.CurrentUser;
import java.time.Instant;
import java.util.List;

@Service @RequiredArgsConstructor
public class ReputationService {
    private final ReputationEventRepository events;
    private final CurrentUser current;
    public static final int COMPLETION_BONUS = 2;
    public static final int CANCELLATION_PENALTY = 15;
    public record Entry(Long id, String type, int delta, int scoreAfter, Long jobId, String jobTitle, Instant createdAt) { }
    public record History(List<Entry> items, boolean hasMore) { }

    // Caller holds job then worker locks; event and score commit together.
    @Transactional(propagation = Propagation.MANDATORY)
    public void apply(User worker, JobApplication application, String type, int requestedDelta) {
        if (events.existsByApplicationIdAndType(application.getId(), type)) return;
        int before = worker.getReputationScore(), after = Math.max(0, Math.min(100, before + requestedDelta));
        worker.setReputationScore(after); worker.recalculateTier();
        var event = new ReputationEvent(); event.setUser(worker); event.setJob(application.getJob()); event.setApplication(application);
        event.setJobTitle(application.getJob().getTitle()); event.setType(type); event.setDelta(after - before); event.setScoreAfter(after);
        events.save(event);
    }
    @Transactional(readOnly = true)
    public History history(Long beforeId, int limit) {
        Long id = current.get().getId();
        var rows = events.findByUserIdAndIdLessThanOrderByIdDesc(id, beforeId == null ? Long.MAX_VALUE : beforeId, PageRequest.of(0, limit + 1));
        return new History(rows.stream().limit(limit).map(e -> new Entry(e.getId(), e.getType(), e.getDelta(), e.getScoreAfter(),
            e.getJob() == null ? null : e.getJob().getId(), e.getJobTitle(), e.getCreatedAt())).toList(), rows.size() > limit);
    }
}
