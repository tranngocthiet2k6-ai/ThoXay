package vn.thoxay.wallet;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.data.domain.PageRequest;
import vn.thoxay.entity.Role;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.exception.ApiException;
import java.time.Clock;
import java.util.*;
@Service @RequiredArgsConstructor
public class BankSettingsService {
 private final BankSettingsRepository settings;
 private final BankSettingsAuditRepository audits;
 private final CurrentUser current;
 private final Clock clock;
 public record Setup(@NotNull Boolean enabled,@NotNull @Pattern(regexp="|[0-9]{6}") String bankBin,@NotNull @Size(max=100) String bankName,@NotNull @Pattern(regexp="|[A-Za-z0-9]{1,19}") String accountNo,@NotNull @Size(max=100) String accountName,@NotNull @Min(-1) Long version,Boolean confirmed){@Override public String toString(){return "BankSetup[enabled="+enabled+",account=redacted,version="+version+"]";}}
 public record Audit(Long id,long revision,boolean enabled,String bankName,String accountNo,String accountName,java.time.Instant changedAt){}
 @Transactional(readOnly=true) public Setup get(){current.require(Role.ROLE_ADMIN);return dto(settings.findById(1L).orElse(null));}
 @Transactional(readOnly=true) public List<Audit> history(){current.require(Role.ROLE_ADMIN);return audits.findAllByOrderByIdDesc(PageRequest.of(0,20)).stream().map(a->new Audit(a.getId(),a.getRevision(),a.isEnabled(),a.getBankName(),a.getAccountNo(),a.getAccountName(),a.getChangedAt())).toList();}
 @Transactional public Setup save(Setup input){var actor=current.require(Role.ROLE_ADMIN);var bank=settings.locked().orElseGet(BankSettings::new);long version=bank.getVersion()==null?-1:bank.getVersion();if(version!=input.version())throw new ApiException(HttpStatus.CONFLICT,"Cấu hình đã được cập nhật. Tải lại trang trước khi lưu");
  if(Boolean.TRUE.equals(input.enabled())&&(!Boolean.TRUE.equals(input.confirmed())||input.bankBin().isBlank()||input.bankName().isBlank()||input.accountNo().isBlank()||input.accountName().isBlank()))throw new ApiException(HttpStatus.BAD_REQUEST,"Điền đủ ngân hàng/BIN/số tài khoản/tên chủ tài khoản và xác nhận đã đối chiếu trước khi bật QR");
  bank.setEnabled(Boolean.TRUE.equals(input.enabled()));bank.setBankBin(clean(input.bankBin()));bank.setBankName(clean(input.bankName()));bank.setAccountNo(clean(input.accountNo()));bank.setAccountName(clean(input.accountName()));settings.saveAndFlush(bank);
  var audit=new BankSettingsAudit();audit.setActor(actor);audit.setEnabled(bank.isEnabled());audit.setBankBin(bank.getBankBin());audit.setBankName(bank.getBankName());audit.setAccountNo(bank.getAccountNo());audit.setAccountName(bank.getAccountName());audit.setRevision(bank.getVersion());audit.setChangedAt(clock.instant());audits.save(audit);return dto(bank);
 }
 BankSettings active(){return settings.findById(1L).filter(BankSettings::isEnabled).orElseThrow(()->new ApiException(HttpStatus.CONFLICT,"VietQR chưa được bật. Admin cần cấu hình ngân hàng nhận tiền trước"));}
 private Setup dto(BankSettings b){return b==null?new Setup(false,"","","","",-1L,false):new Setup(b.isEnabled(),Objects.toString(b.getBankBin(),""),Objects.toString(b.getBankName(),""),Objects.toString(b.getAccountNo(),""),Objects.toString(b.getAccountName(),""),b.getVersion(),false);}
 private String clean(String s){return s.isBlank()?null:s.strip();}
}
