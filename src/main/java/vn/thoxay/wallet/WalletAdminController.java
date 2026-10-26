package vn.thoxay.wallet;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import vn.thoxay.exception.ApiException;
import static vn.thoxay.wallet.WalletDtos.*;

@Controller @RequiredArgsConstructor
public class WalletAdminController {
    private final WalletService wallets;
    @GetMapping("/admin/wallet") public String page(@RequestParam(required=false) @Positive Long beforeId,Model model){model.addAttribute("queue",wallets.pending(beforeId,30));return "admin-wallet";}
    @PostMapping("/admin/wallet/requests/{id}/review") public String review(@PathVariable @Positive Long id,@Valid @ModelAttribute Review input,RedirectAttributes flash){wallets.review(id,input);flash.addFlashAttribute("success","Đã xử lý yêu cầu ví");return "redirect:/admin/wallet";}
    @ExceptionHandler(ApiException.class) public String error(ApiException e,RedirectAttributes flash){
        flash.addFlashAttribute("error",e.getMessage());return "redirect:/admin/wallet";
    }
}
