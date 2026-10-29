package vn.thoxay.wallet;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import vn.thoxay.entity.Role;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.exception.ApiException;
import java.util.Locale;
@Service @RequiredArgsConstructor
public class DepositService {
 private final WalletRequestRepository requests;
 private final BankSettingsService banks;
 private final CurrentUser current;
 private final UserRepository users;
 public record Create(@NotNull @Min(1000) @Max(100000000) Long amount,@NotBlank @Pattern(regexp="[A-Za-z0-9_-]{8,80}") String clientRequestId){}
 public record Deposit(Long requestId,long amount,String status,String reference,String bankBin,String bankName,String accountNo,String accountName,String payload){@Override public String toString(){return "Deposit[requestId="+requestId+",amount="+amount+",status="+status+"]";}}
 @Transactional public Deposit create(Create input){var u=current.get();if(u.getRole()==Role.ROLE_ADMIN)throw new ApiException(HttpStatus.FORBIDDEN,"Admin không có ví nạp tiền");users.findLockedById(u.getId()).orElseThrow();var existing=requests.findByUserIdAndClientRequestId(u.getId(),input.clientRequestId());if(existing.isPresent()){var r=existing.get();if(r.getDepositReference()==null||r.getAmount()!=input.amount())throw new ApiException(HttpStatus.CONFLICT,"Mã yêu cầu đã dùng cho giao dịch khác");return dto(r);}
  var bank=banks.active();var r=new WalletRequest();r.setUser(u);r.setKind(WalletRequest.Kind.TOP_UP);r.setAmount(input.amount());r.setClientRequestId(input.clientRequestId());r.setBankName(bank.getBankName());r.setBankAccount(bank.getAccountNo());r.setAccountName(bank.getAccountName());r.setReceivingBankBin(bank.getBankBin());requests.saveAndFlush(r);
  String reference="TX"+Long.toString(r.getId(),36).toUpperCase(Locale.ROOT);r.setTransferReference(reference);r.setDepositReference(reference);r.setQrPayload(VietQrPayload.build(bank.getBankBin(),bank.getAccountNo(),r.getAmount(),reference));requests.flush();return dto(r);
 }
 @Transactional(readOnly=true) public Deposit get(Long id){var u=current.get();var r=requests.findById(id).filter(a->a.getDepositReference()!=null).orElseThrow(this::missing);if(!u.getId().equals(r.getUser().getId())&&u.getRole()!=Role.ROLE_ADMIN)throw missing();return dto(r);}
 private Deposit dto(WalletRequest r){return new Deposit(r.getId(),r.getAmount(),r.getStatus().name(),r.getDepositReference(),r.getReceivingBankBin(),r.getBankName(),r.getBankAccount(),r.getAccountName(),r.getQrPayload());}
 private ApiException missing(){return new ApiException(HttpStatus.NOT_FOUND,"Không tìm thấy yêu cầu nạp VietQR");}
}
