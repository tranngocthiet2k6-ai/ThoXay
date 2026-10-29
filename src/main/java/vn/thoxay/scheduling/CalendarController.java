package vn.thoxay.scheduling;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

@RestController @RequestMapping("/api/users/me/calendar") @RequiredArgsConstructor
public class CalendarController {
    private final WorkerCalendarService calendar;
    public record Block(@NotNull LocalDate from,@NotNull LocalDate to,@Size(max=200) String note) { }
    @GetMapping public List<WorkerCalendarService.Event> list(@RequestParam LocalDate from,@RequestParam LocalDate to) {
        return calendar.calendar(from,to);
    }
    @PostMapping public List<WorkerCalendarService.Event> block(@Valid @RequestBody Block input) {
        return calendar.block(input.from(),input.to(),input.note());
    }
    @DeleteMapping("/{id}") public void remove(@PathVariable @Positive Long id) { calendar.remove(id); }
}
