package vn.thoxay.wallet;

import jakarta.persistence.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.service.NotificationService;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import static vn.thoxay.wallet.WalletDtos.*;

@Service @RequiredArgsConstructor
public class WalletService {
    private final WalletAccountRepository accounts;
    private final WalletRequestRepository requests;
    private final WalletEntryRepository entries;
    private final UserRepository users;
    private final CurrentUser current;
    private final EntityManager em;
    private final NotificationService notifications;
    @Value("${app.wallet.minimum-escrow:${APP_WALLET_MINIMUM_ESCROW:200000}}") private long minimumEscrow;
    private static final long MAX_BALANCE=1_000_000_000_000L;
    private static final ZoneId ZONE=ZoneId.of("Asia/Ho_Chi_Minh");

    private User actor() {
        User u=current.get();
        if(u.getRole()==Role.ROLE_ADMIN) throw new ApiException(HttpStatus.FORBIDDEN,"Ví dành cho tài khoản thợ và chủ thầu");
        return u;
    }
    /** Lock user rows before creating wallets; all multi-account transfers use ascending user IDs. */
    @Transactional(propagation=Propagation.MANDATORY)
    public Map<Long,WalletAccount> lockAccounts(Collection<Long> ids) {
        var result=new LinkedHashMap<Long,WalletAccount>();
        for(Long id:ids.stream().distinct().sorted().toList()) {
            User user=users.findLockedById(id).orElseThrow(()->new ApiException(HttpStatus.NOT_FOUND,"Tài khoản không tồn tại"));
            WalletAccount account=accounts.lock(id).orElseGet(()->{var w=new WalletAccount();w.setUser(user);return accounts.saveAndFlush(w);});
            em.refresh(account,LockModeType.PESSIMISTIC_WRITE); result.put(id,account);
        }
        return result;
    }
    @Transactional public Balance balance() {
        var u=actor();var w=lockAccounts(List.of(u.getId())).get(u.getId());
        long threshold=Math.max(0,minimumEscrow);
        return new Balance(w.getMainBalance(),w.getEscrowBalance(),w.getHeldBalance(),threshold,w.getEscrowBalance()<threshold,"VND");
    }
    @Transactional public Request create(CreateRequest input) {
        User user=actor(); var w=lockAccounts(List.of(user.getId())).get(user.getId());
        var kind=WalletRequest.Kind.valueOf(input.kind());
        String bank=clean(input.bankName()),account=clean(input.bankAccount()),name=clean(input.accountName()),transfer=clean(input.transferReference());
        if(kind==WalletRequest.Kind.TOP_UP && transfer==null) throw bad("Nhập mã/nội dung chuyển khoản để quản trị viên đối soát");
        if(kind==WalletRequest.Kind.WITHDRAW && (bank==null || name==null || account==null || !account.matches("[0-9]{6,34}")))
            throw bad("Cần tên ngân hàng, số tài khoản 6–34 chữ số và tên chủ tài khoản");
        var existing=requests.findByUserIdAndClientRequestId(user.getId(),input.clientRequestId());
        if(existing.isPresent()) {
            var r=existing.get();
            if(r.getKind()!=kind || r.getAmount()!=input.amount() || !Objects.equals(r.getBankName(),bank) || !Objects.equals(r.getBankAccount(),account)
                || !Objects.equals(r.getAccountName(),name) || !Objects.equals(r.getTransferReference(),transfer)) throw conflict("Mã yêu cầu đã dùng cho nội dung khác");
            return Request.of(r);
        }
        var r=new WalletRequest();r.setUser(user);r.setKind(kind);r.setAmount(input.amount());r.setClientRequestId(input.clientRequestId());
        r.setBankName(bank);r.setBankAccount(account);r.setAccountName(name);r.setTransferReference(transfer);requests.saveAndFlush(r);
        if(kind==WalletRequest.Kind.WITHDRAW)
            record(w,"WITHDRAW_HOLD",r.getAmount(),-r.getAmount(),0,r.getAmount(),"request:"+r.getId()+":hold","Giữ chỗ cho yêu cầu rút tiền",r,null);
        return Request.of(r);
    }
    @Transactional public Entry escrow(Transfer input) {
        User user=actor();var w=lockAccounts(List.of(user.getId())).get(user.getId());
        String ref="escrow:"+user.getId()+":"+input.clientRequestId(),kind=input.direction().equals("LOCK")?"ESCROW_LOCK":"ESCROW_RELEASE";
        var old=entries.findByReference(ref);
        if(old.isPresent()) {
            if(!old.get().getKind().equals(kind)||old.get().getAmount()!=input.amount()) throw conflict("Mã chuyển tiền đã được dùng");
            return Entry.of(old.get());
        }
        long delta=input.direction().equals("LOCK")?input.amount():-input.amount();
        return Entry.of(record(w,kind,input.amount(),-delta,delta,0,ref,delta>0?"Chuyển vào ký quỹ":"Chuyển ký quỹ về số dư chính",null,null));
    }
    @Transactional public Request review(Long id,Review input) {
        User admin=current.require(Role.ROLE_ADMIN);
        var r=requests.lock(id).orElseThrow(()->new ApiException(HttpStatus.NOT_FOUND,"Yêu cầu không tồn tại"));
        boolean approve=input.decision().equals("APPROVE");
        if(!approve && clean(input.note())==null) throw bad("Nhập lý do từ chối để người dùng biết kết quả đối soát");
        String ref=clean(input.externalReference()); if(ref!=null)ref=ref.toUpperCase(Locale.ROOT);
        if(approve && (!Boolean.TRUE.equals(input.confirmed()) || ref==null || !ref.matches("[A-Z0-9][A-Z0-9._/-]{2,99}")))
            throw bad("Xác nhận đã đối soát thực tế và nhập mã giao dịch ngân hàng hợp lệ");
        if(!approve)ref=null;
        var desired=approve?WalletRequest.Status.APPROVED:WalletRequest.Status.REJECTED;
        if(r.getStatus()!=WalletRequest.Status.PENDING) {
            if(r.getStatus()==desired && Objects.equals(r.getExternalReference(),ref)) return Request.of(r);
            throw conflict("Yêu cầu đã được xử lý, không thể thay đổi");
        }
        if(approve && requests.existsByExternalReference(ref)) throw conflict("Mã giao dịch ngân hàng đã được đối soát cho yêu cầu khác");
        var w=lockAccounts(List.of(r.getUser().getId())).get(r.getUser().getId());
        if(r.getKind()==WalletRequest.Kind.TOP_UP && approve)
            record(w,"TOP_UP",r.getAmount(),r.getAmount(),0,0,"request:"+id+":approved","Nạp tiền đã đối soát",r,null);
        if(r.getKind()==WalletRequest.Kind.WITHDRAW) {
            record(w,approve?"WITHDRAW_PAID":"WITHDRAW_RELEASE",r.getAmount(),approve?0:r.getAmount(),0,-r.getAmount(),
                "request:"+id+":review",approve?"Đã đối soát chuyển tiền rút":"Hoàn giữ chỗ do từ chối rút",r,null);
        }
        r.setStatus(desired);r.setExternalReference(ref);r.setNote(clean(input.note()));r.setProcessedBy(admin);r.setProcessedAt(Instant.now());requests.flush();
        notifications.create(r.getUser(),null,"wallet:"+id+":"+desired,"WALLET_REQUEST", "Yêu cầu ví đã được xử lý",
            approve?"Yêu cầu nạp/rút của bạn đã được đối soát thành công.":"Yêu cầu chưa được chấp nhận. Mở Ví để xem lý do.");
        return Request.of(r);
    }
    @Transactional(propagation=Propagation.MANDATORY)
    public WalletEntry record(WalletAccount w,String kind,long amount,long mainDelta,long escrowDelta,long heldDelta,String ref,String description,WalletRequest request,JobPayment payment) {
        long main=Math.addExact(w.getMainBalance(),mainDelta),escrow=Math.addExact(w.getEscrowBalance(),escrowDelta),held=Math.addExact(w.getHeldBalance(),heldDelta);
        if(main<0||escrow<0||held<0) throw conflict("Số dư khả dụng không đủ để thực hiện giao dịch");
        if(main+escrow+held>MAX_BALANCE) throw conflict("Tổng số dư vượt hạn mức của ứng dụng");
        w.setMainBalance(main);w.setEscrowBalance(escrow);w.setHeldBalance(held);
        var e=new WalletEntry();e.setUser(w.getUser());e.setKind(kind);e.setAmount(amount);e.setMainDelta(mainDelta);e.setEscrowDelta(escrowDelta);e.setHeldDelta(heldDelta);
        e.setMainAfter(main);e.setEscrowAfter(escrow);e.setHeldAfter(held);e.setReference(ref);e.setDescription(description);e.setRequest(request);e.setPayment(payment);
        return entries.saveAndFlush(e);
    }
    @Transactional(readOnly=true) public Page<Entry> history(Long before,int limit) {
        var rows=entries.findByUserIdAndIdLessThanOrderByIdDesc(actor().getId(),before==null?Long.MAX_VALUE:before,PageRequest.of(0,limit+1));
        return new Page<>(rows.stream().limit(limit).map(Entry::of).toList(),rows.size()>limit);
    }
    @Transactional(readOnly=true) public Page<Request> requests(Long before,int limit) {
        var rows=requests.findByUserIdAndIdLessThanOrderByIdDesc(actor().getId(),before==null?Long.MAX_VALUE:before,PageRequest.of(0,limit+1));
        return new Page<>(rows.stream().limit(limit).map(Request::of).toList(),rows.size()>limit);
    }
    @Transactional(readOnly=true) public Page<Request> pending(Long before,int limit) {
        current.require(Role.ROLE_ADMIN);
        var rows=requests.findByStatusAndIdLessThanOrderByIdDesc(WalletRequest.Status.PENDING,before==null?Long.MAX_VALUE:before,PageRequest.of(0,limit+1));
        return new Page<>(rows.stream().limit(limit).map(Request::of).toList(),rows.size()>limit);
    }
    @Transactional(readOnly=true) public Earnings earnings(String period,LocalDate date) {
        User worker=current.require(Role.ROLE_WORKER); LocalDate anchor=date==null?LocalDate.now(ZONE):date;
        if(anchor.getYear()<1900 || anchor.getYear()>2100) throw bad("Chọn ngày trong khoảng 1900–2100");
        LocalDate start=switch(period){case "DAY"->anchor;case "WEEK"->anchor.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));case "MONTH"->anchor.withDayOfMonth(1);default->throw bad("Kỳ thống kê không hợp lệ");};
        LocalDate end=switch(period){case "DAY"->start.plusDays(1);case "WEEK"->start.plusWeeks(1);default->start.plusMonths(1);};
        var totals=entries.earnings(worker.getId(),start.atStartOfDay(ZONE).toInstant(),end.atStartOfDay(ZONE).toInstant());
        long base=zero(totals.getBase()),tip=zero(totals.getTip()),bonus=zero(totals.getBonus());
        return new Earnings(period,start,end,ZONE.getId(),base,tip,bonus,base+tip+bonus,zero(totals.getJobs()));
    }
    private long zero(Long n){return n==null?0:n;}
    private String clean(String s){return s==null||s.isBlank()?null:s.strip();}
    private ApiException bad(String m){return new ApiException(HttpStatus.BAD_REQUEST,m);}
    private ApiException conflict(String m){return new ApiException(HttpStatus.CONFLICT,m);}
}
