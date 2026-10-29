package vn.thoxay.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import vn.thoxay.exception.ApiException;

@Controller @RequiredArgsConstructor
public class AdminController {
    private final AdminService admin;
    private final vn.thoxay.incident.IncidentService incidents;
    @GetMapping("/")
    public String index() { return "redirect:/admin/dashboard"; }
    @GetMapping("/admin/login")
    public String login() { return "admin-login"; }
    @GetMapping("/admin/dashboard") @PreAuthorize("hasRole('ADMIN')")
    public String dashboard(Model model) { model.addAttribute("dashboard", admin.dashboard()); model.addAttribute("incidentCounts",incidents.counts()); return "admin-dashboard"; }
    @PostMapping("/admin/users/{id}/verify") @PreAuthorize("hasRole('ADMIN')")
    public String verify(@PathVariable Long id,
                         @RequestParam(required = false) String cccdFrontImage,
                         @RequestParam(required = false) String cccdBackImage,
                         RedirectAttributes flash) {
        admin.verify(id, cccdFrontImage, cccdBackImage);
        flash.addFlashAttribute("success", "Đã xác thực danh tính bằng ảnh mặt trước và mặt sau CCCD");
        return "redirect:/admin/dashboard";
    }
    @PostMapping("/admin/users/{id}/toggle-active") @PreAuthorize("hasRole('ADMIN')")
    public String toggle(@PathVariable Long id, RedirectAttributes flash) {
        admin.toggleActive(id); flash.addFlashAttribute("success", "Đã cập nhật trạng thái tài khoản"); return "redirect:/admin/dashboard";
    }
    @PostMapping("/admin/jobs/{id}/delete") @PreAuthorize("hasRole('ADMIN')")
    public String delete(@PathVariable Long id, RedirectAttributes flash) {
        admin.deleteJob(id); flash.addFlashAttribute("success", "Đã xóa công trình và các đơn ứng tuyển liên quan"); return "redirect:/admin/dashboard";
    }
    @ExceptionHandler(ApiException.class)
    public String businessError(ApiException e, RedirectAttributes flash) {
        flash.addFlashAttribute("error", e.getMessage()); return "redirect:/admin/dashboard";
    }
}
