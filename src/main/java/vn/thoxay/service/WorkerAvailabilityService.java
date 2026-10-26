package vn.thoxay.service;

import jakarta.persistence.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.Role;
import vn.thoxay.security.CurrentUser;

@Service @RequiredArgsConstructor
public class WorkerAvailabilityService {
    private final CurrentUser current;
    private final EntityManager em;
    public record State(boolean available) { }
    @Transactional(readOnly = true)
    public State get() { return new State(current.require(Role.ROLE_WORKER).isAvailable()); }
    @Transactional
    public State update(boolean value) {
        var worker=current.require(Role.ROLE_WORKER);
        em.refresh(worker, LockModeType.PESSIMISTIC_WRITE);
        worker.setAvailable(value);
        return new State(value);
    }
}
