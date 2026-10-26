package vn.thoxay.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.thoxay.entity.User;
import vn.thoxay.repository.*;
import java.util.Collection;
import java.util.List;

@Service @RequiredArgsConstructor
public class WorkerRatingService {
    private final UserRepository users;
    private final JobApplicationRepository applications;
    private final jakarta.persistence.EntityManager entityManager;

    public List<User> lockWorkers(Collection<Long> ids) {
        return ids.stream().distinct().sorted()
            .map(id -> {
                User worker = users.findLockedById(id).orElseThrow();
                // The application may already have loaded this user before another transaction committed.
                entityManager.refresh(worker, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
                return worker;
            }).toList();
    }

    public void recompute(List<User> workers) {
        for (User worker : workers) {
            Double average = applications.averageRatingByWorkerId(worker.getId());
            worker.setRating(average == null ? 5.0 : average);
            worker.setCompletedJobs(Math.toIntExact(applications.completedRatings(worker.getId())));
            worker.recalculateTier();
        }
    }
}
