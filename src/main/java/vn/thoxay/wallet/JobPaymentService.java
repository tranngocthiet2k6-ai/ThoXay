package vn.thoxay.wallet;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.service.NotificationService;
import vn.thoxay.exception.ApiException;
import java.math.*;
import java.util.*;
import static vn.thoxay.wallet.WalletDtos.*;

@Service @RequiredArgsConstructor
public class JobPaymentService {
    private final JobPaymentRepository payments;
    private final JobApplicationRepository applications;
    private final JobRepository jobs;
    private final CurrentUser current;
    private final WalletService wallets;
    private final NotificationService notifications;
    @Transactional public Payment pay(Pay input) {
        User owner=current.require(Role.ROLE_CONTRACTOR);
        Long jobId=applications.findJobIdById(input.applicationId()).orElseThrow(()->new ApiException(HttpStatus.NOT_FOUND,"Đơn ứng tuyển không tồn tại"));
        Job job=jobs.findLockedById(jobId).orElseThrow();
        current.requireOwner(job.getContractor().getId(),Role.ROLE_CONTRACTOR);
        JobApplication a=applications.findById(input.applicationId()).orElseThrow();
        if(job.getStatus()!=JobStatus.COMPLETED || a.getStatus()!=ApplicationStatus.ACCEPTED || a.getWorkerRating()==null)
            throw new ApiException(HttpStatus.CONFLICT,"Chỉ thanh toán cho thợ được nhận của công trình đã hoàn thành và đánh giá");
        var old=payments.findByApplicationId(a.getId());
        if(old.isPresent()) {
            var p=old.get();
            if(p.getWorkDays()!=input.workDays()||p.getTip()!=input.tip()||p.getBonus()!=input.bonus()) throw new ApiException(HttpStatus.CONFLICT,"Khoản thanh toán đã chốt, không thể sửa");
            return Payment.of(p);
        }
        var balances=wallets.lockAccounts(List.of(owner.getId(),a.getWorker().getId()));
        var p=new JobPayment();p.setApplication(a);p.setJob(job);p.setContractor(owner);p.setWorker(a.getWorker());p.setJobTitle(job.getTitle());
        p.setWorkDays(input.workDays());p.setDailyRate(BigDecimal.valueOf(job.getSalaryPerDay()).setScale(0,RoundingMode.HALF_UP).longValueExact());
        p.setBase(Math.multiplyExact(p.getDailyRate(),p.getWorkDays()));p.setTip(input.tip());p.setBonus(input.bonus());p.setTotal(p.getBase()+p.getTip()+p.getBonus());payments.saveAndFlush(p);
        var sender=balances.get(owner.getId()); var recipient=balances.get(a.getWorker().getId()); String ref="payment:"+p.getId();
        wallets.record(sender,"JOB_PAYMENT",p.getTotal(),-p.getTotal(),0,0,ref+":payer","Thanh toán: "+job.getTitle(),null,p);
        wallets.record(recipient,"WORK_EARNING",p.getBase(),p.getBase(),0,0,ref+":base","Tiền công: "+job.getTitle(),null,p);
        if(p.getTip()>0) wallets.record(recipient,"TIP",p.getTip(),p.getTip(),0,0,ref+":tip","Tiền tip: "+job.getTitle(),null,p);
        if(p.getBonus()>0) wallets.record(recipient,"BONUS",p.getBonus(),p.getBonus(),0,0,ref+":bonus","Tiền thưởng: "+job.getTitle(),null,p);
        notifications.create(a.getWorker(),job,ref,"EARNINGS_RECEIVED","Bạn vừa nhận thu nhập","Chủ thầu đã thanh toán tiền công. Mở Thu nhập để xem chi tiết.");
        return Payment.of(p);
    }
    @Transactional(readOnly=true) public List<Payment> byJob(Long id) {
        Job j=jobs.findById(id).orElseThrow(()->new ApiException(HttpStatus.NOT_FOUND,"Công trình không tồn tại"));
        current.requireOwner(j.getContractor().getId(),Role.ROLE_CONTRACTOR);
        return payments.findByJobIdOrderByIdDesc(id).stream().map(Payment::of).toList();
    }
}
