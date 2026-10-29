package vn.thoxay.wallet;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
@RestController @RequiredArgsConstructor @Validated
public class DepositController {
 private final DepositService service;private final BankSettingsService banks;
 @PostMapping("/api/wallet/deposits") public DepositService.Deposit create(@Valid @RequestBody DepositService.Create input){return service.create(input);}
 @GetMapping("/api/wallet/deposits/{id}") public DepositService.Deposit get(@PathVariable @Positive Long id){return service.get(id);}
 @GetMapping("/api/admin/wallet/bank-settings") public BankSettingsService.Setup settings(){return banks.get();}
 @PutMapping("/api/admin/wallet/bank-settings") public BankSettingsService.Setup save(@Valid @RequestBody BankSettingsService.Setup input){return banks.save(input);}
}
