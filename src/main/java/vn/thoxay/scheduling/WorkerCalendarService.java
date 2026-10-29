package vn.thoxay.scheduling;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.JobApplicationRepository;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.service.WorkerRatingService;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service @RequiredArgsConstructor
public class WorkerCalendarService {
    private final CurrentUser current;
    private final CalendarBlockRepository blocks;
    private final JobApplicationRepository applications;
    private final WorkerRatingService locks;
    private final Clock clock;
    public record Event(String kind,Long referenceId,String title,LocalDate startsOn,LocalDate endsOn) { }

    @Transactional(readOnly=true)
    public List<Event> calendar(LocalDate from,LocalDate to) {
        var worker=current.require(Role.ROLE_WORKER); range(from,to);
        var events=new ArrayList<Event>();
        applications.overlapping(worker.getId(),from,to).forEach(a -> events.add(new Event("JOB",a.getId(),a.getJob().getTitle(),a.getJob().getStartsOn(),a.getJob().getEndsOn())));
        blocks.findByWorkerIdAndDayBetweenOrderByDay(worker.getId(),from,to).forEach(b -> events.add(new Event("BLOCKED",b.getId(),b.getNote(),b.getDay(),b.getDay())));
        events.sort(Comparator.comparing(Event::startsOn).thenComparing(Event::kind));
        return events;
    }

    /** Caller must hold the worker lock. Every acceptance path crosses this check. */
    public void requireAvailable(User worker,Job job,Long excludeApplication) {
        if(job.getStartsOn()==null) return;
        if(!blocks.findByWorkerIdAndDayBetweenOrderByDay(worker.getId(),job.getStartsOn(),job.getEndsOn()).isEmpty()
            || applications.overlapping(worker.getId(),job.getStartsOn(),job.getEndsOn()).stream()
                .anyMatch(a -> !Objects.equals(a.getId(),excludeApplication)))
            throw conflict("Thợ đã có lịch trong khoảng ngày của công trình");
    }

    @Transactional
    public List<Event> block(LocalDate from,LocalDate to,String note) {
        var worker=current.require(Role.ROLE_WORKER); range(from,to);
        if(from.isBefore(LocalDate.now(clock))) throw new ApiException(HttpStatus.BAD_REQUEST,"Chỉ đánh dấu bận từ hôm nay");
        locks.lockWorkers(List.of(worker.getId()));
        if(!applications.overlapping(worker.getId(),from,to).isEmpty()) throw conflict("Ngày đã có công trình được nhận");
        var existing=blocks.findByWorkerIdAndDayBetweenOrderByDay(worker.getId(),from,to);
        var byDay=new HashMap<LocalDate,CalendarBlock>(); existing.forEach(b -> byDay.put(b.getDay(),b));
        for(var day=from;!day.isAfter(to);day=day.plusDays(1)) {
            var b=byDay.get(day);
            if(b==null) { b=new CalendarBlock(); b.setWorker(worker); b.setDay(day); }
            b.setNote(note==null?"Bận việc cá nhân":note.trim()); blocks.save(b);
        }
        return calendar(from,to);
    }
    @Transactional public void remove(Long id) {
        var worker=current.require(Role.ROLE_WORKER); locks.lockWorkers(List.of(worker.getId()));
        blocks.delete(blocks.findByIdAndWorkerId(id,worker.getId()).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,"Không tìm thấy lịch bận")));
    }
    static void range(LocalDate from,LocalDate to) {
        if(from==null||to==null||to.isBefore(from)||ChronoUnit.DAYS.between(from,to)>365)
            throw new ApiException(HttpStatus.BAD_REQUEST,"Khoảng ngày không hợp lệ hoặc vượt quá 366 ngày");
    }
    private ApiException conflict(String text) { return new ApiException(HttpStatus.CONFLICT,text); }
}
