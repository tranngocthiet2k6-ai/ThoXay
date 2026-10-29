package vn.thoxay.wallet;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import vn.thoxay.exception.ApiException;
@Controller @RequiredArgsConstructor @PreAuthorize("hasRole('ADMIN')")
public class BankSettingsAdminController {
 private final BankSettingsService service;
 @GetMapping("/admin/wallet/bank-settings") public String page(Model model){model.addAttribute("settings",service.get());model.addAttribute("history",service.history());return "admin-bank-settings";}
 @PostMapping("/admin/wallet/bank-settings") public String save(@Valid @ModelAttribute BankSettingsService.Setup input,RedirectAttributes flash){service.save(input);flash.addFlashAttribute("success","Đã lưu ngân hàng nhận tiền; yêu cầu cũ giữ thông tin tại thời điểm tạo");return "redirect:/admin/wallet/bank-settings";}
 @ExceptionHandler(ApiException.class) public String error(ApiException e,RedirectAttributes flash){flash.addFlashAttribute("error",e.getMessage());return "redirect:/admin/wallet/bank-settings";}
}
