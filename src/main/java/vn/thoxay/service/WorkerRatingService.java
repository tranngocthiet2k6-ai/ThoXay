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

    public List<User> lockWorkers(Collection<Long> ids) {
        return ids.stream().distinct().sorted()
            .map(id -> users.findLockedById(id).orElseThrow()).toList();
    }

    public void recompute(List<User> workers) {
        for (User worker : workers) {
            Double average = applications.averageRatingByWorkerId(worker.getId());
            worker.setRating(average == null ? 5.0 : average);
        }
    }
}
