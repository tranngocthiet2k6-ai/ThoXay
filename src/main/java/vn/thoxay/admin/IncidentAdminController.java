package vn.thoxay.admin;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.validation.annotation.Validated;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import vn.thoxay.incident.*;
import vn.thoxay.exception.ApiException;
@Controller @RequiredArgsConstructor @Validated @PreAuthorize("hasRole('ADMIN')")
public class IncidentAdminController {
 private final IncidentService service;
 @GetMapping("/admin/incidents") public String queue(@RequestParam(defaultValue="NEW") String status,@RequestParam(defaultValue="") String type,@RequestParam(defaultValue="") @Size(max=100) String q,@RequestParam(defaultValue="0") @Min(0) @Max(10000) int page,Model model){model.addAttribute("queue",service.queue(status,type,q,page));model.addAttribute("counts",service.counts());model.addAttribute("filterStatus",status);model.addAttribute("filterType",type);model.addAttribute("query",q);model.addAttribute("page",page);return "admin-incidents";}
 @GetMapping("/admin/incidents/{id}") public String detail(@PathVariable @Positive Long id,Model model){model.addAttribute("detail",service.get(id));model.addAttribute("counts",service.counts());return "admin-incident-detail";}
 @GetMapping("/admin/incidents/counts") @ResponseBody public IncidentService.Counts counts(){return service.counts();}
 @PostMapping("/admin/incidents/{id}") public String update(@PathVariable @Positive Long id,@Valid @ModelAttribute IncidentController.Update input,RedirectAttributes flash){service.update(id,input);flash.addFlashAttribute("success","Đã lưu cập nhật và gửi thông báo tới người báo cáo");return "redirect:/admin/incidents/"+id;}
 @ExceptionHandler(ApiException.class) public String error(ApiException e,RedirectAttributes flash){flash.addFlashAttribute("error",e.getMessage());return "redirect:/admin/incidents";}
}
