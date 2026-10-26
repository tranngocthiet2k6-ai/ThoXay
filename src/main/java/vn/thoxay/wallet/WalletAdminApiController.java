package vn.thoxay.wallet;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import static vn.thoxay.wallet.WalletDtos.*;
@RestController @RequestMapping("/api/admin/wallet") @RequiredArgsConstructor
public class WalletAdminApiController {
    private final WalletService wallets;
    @GetMapping("/requests") public Page<Request> pending(@RequestParam(required=false) @Positive Long beforeId){return wallets.pending(beforeId,30);}
    @PostMapping("/requests/{id}/review") public Request review(@PathVariable @Positive Long id,@Valid @RequestBody Review input){return wallets.review(id,input);}
}
