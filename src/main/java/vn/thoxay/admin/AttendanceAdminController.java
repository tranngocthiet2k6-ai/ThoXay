package vn.thoxay.admin;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.annotation.Validated;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.constraints.*;
import vn.thoxay.attendance.AttendanceService;
import java.time.LocalDate;
@Controller @RequiredArgsConstructor @Validated @PreAuthorize("hasRole('ADMIN')")
public class AttendanceAdminController {
 private final AttendanceService service;
 @GetMapping("/admin/jobs/{id}/attendance") public String list(@PathVariable @Positive Long id,@RequestParam(required=false) LocalDate day,@RequestParam(defaultValue="0") @Min(0) @Max(1000) int page,Model model){var data=service.byJob(id,day,page);model.addAttribute("data",data);model.addAttribute("selectedDay",day==null?data.today():day);model.addAttribute("jobId",id);model.addAttribute("page",page);return "admin-attendance";}
 @GetMapping("/admin/work-logs/{id}/photo") public ResponseEntity<byte[]> photo(@PathVariable @Positive Long id){return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG).cacheControl(CacheControl.noStore()).header("X-Content-Type-Options","nosniff").body(service.photo(id));}
}
