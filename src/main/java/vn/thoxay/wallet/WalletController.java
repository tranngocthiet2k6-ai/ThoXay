package vn.thoxay.wallet;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.format.annotation.DateTimeFormat;
import java.time.LocalDate;
import java.util.List;
import static vn.thoxay.wallet.WalletDtos.*;

@RestController @RequestMapping("/api/wallet") @RequiredArgsConstructor
public class WalletController {
    private final WalletService wallets;
    private final JobPaymentService payments;
    @GetMapping public Balance balance(){return wallets.balance();}
    @GetMapping("/transactions") public Page<Entry> history(@RequestParam(required=false) @Positive Long beforeId,@RequestParam(defaultValue="30") @Min(1) @Max(100) int limit){return wallets.history(beforeId,limit);}
    @GetMapping("/requests") public Page<Request> requests(@RequestParam(required=false) @Positive Long beforeId,@RequestParam(defaultValue="30") @Min(1) @Max(100) int limit){return wallets.requests(beforeId,limit);}
    @PostMapping("/requests") public Request create(@Valid @RequestBody CreateRequest body){return wallets.create(body);}
    @PostMapping("/escrow") public Entry escrow(@Valid @RequestBody Transfer body){return wallets.escrow(body);}
    @GetMapping("/earnings") public Earnings earnings(@RequestParam(defaultValue="MONTH") @Pattern(regexp="DAY|WEEK|MONTH") String period,@RequestParam(required=false) @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate date){return wallets.earnings(period,date);}
    @PostMapping("/job-payments") public Payment pay(@Valid @RequestBody Pay body){return payments.pay(body);}
    @GetMapping("/jobs/{id}/payments") public List<Payment> payments(@PathVariable @Positive Long id){return payments.byJob(id);}
}
