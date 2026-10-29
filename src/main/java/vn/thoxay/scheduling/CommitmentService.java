package vn.thoxay.scheduling;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import java.math.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.*;
import java.util.*;

@Service @RequiredArgsConstructor
public class CommitmentService {
    private final JobApplicationRepository applications;
    private final JobRepository jobs;
    private final CurrentUser current;
    private final Clock clock;
    public record Document(Long applicationId,int termsVersion,String state,String text,String hash,
        long originalDailyRate,Long proposedDailyRate,long selectedDailyRate,Instant workerConfirmedAt,Instant contractorConfirmedAt) { }

    @Transactional(readOnly=true) public java.util.List<Document> adminByJob(Long jobId) {
        current.require(Role.ROLE_ADMIN);
        if(!jobs.existsById(jobId)) throw missing("Công trình");
        return applications.findByJobIdOrderByAppliedAtDesc(jobId,org.springframework.data.domain.PageRequest.of(0,100))
            .stream().map(a -> read(a.getId(),false)).toList();
    }

    @Transactional(readOnly=true) public Document jobTerms(Long jobId,Long proposed) {
        var worker=current.require(Role.ROLE_WORKER);
        var job=jobs.findById(jobId).orElseThrow(() -> missing("Công trình"));
        if(!job.getContractor().isActive()) throw missing("Công trình");
        return new Document(null,job.getTermsVersion(),"DRAFT",text(job,proposed,null,null,null)+"\nNgười thợ: "+worker.getFullName(),null,
            original(job),proposed,original(job),null,null);
    }
    @Transactional(readOnly=true) public Document read(Long id,boolean acceptOffer) {
        var a=applications.findById(id).orElseThrow(() -> missing("Đơn ứng tuyển")); authorize(a);
        var rate=selected(a,acceptOffer);
        var state=a.getContractSnapshot()!=null?"FINAL":a.getStatus()==ApplicationStatus.ACCEPTED?"LEGACY":"DRAFT";
        var workerAt=Objects.equals(a.getConsentVersion(),a.getJob().getTermsVersion())?a.getAcceptedTermsAt():null;
        return new Document(a.getId(),a.getContractSnapshot()!=null&&a.getConsentVersion()!=null?a.getConsentVersion():a.getJob().getTermsVersion(),state,
            a.getContractSnapshot()!=null?a.getContractSnapshot():text(a.getJob(),a.getProposedDailyRate(),rate,workerAt,null)+"\nNgười thợ: "+a.getWorker().getFullName()+"\nMã đơn: "+a.getId(),
            a.getContractHash(),original(a.getJob()),a.getProposedDailyRate(),a.getAgreedDailyRate()!=null?a.getAgreedDailyRate():rate,
            workerAt,a.getContractorConfirmedAt());
    }
    @Transactional public Document confirm(Long id,int version,boolean accepted) {
        var worker=current.require(Role.ROLE_WORKER);
        var jobId=applications.findJobIdById(id).orElseThrow(() -> missing("Đơn ứng tuyển"));
        var job=jobs.findLockedById(jobId).orElseThrow();
        var a=applications.findById(id).orElseThrow();
        if(!a.getWorker().getId().equals(worker.getId())) throw missing("Đơn ứng tuyển");
        if(a.getStatus()!=ApplicationStatus.PENDING) throw conflict("Đơn đã được xử lý; cam kết đã chốt không sửa được");
        if(!accepted||version!=job.getTermsVersion()) throw conflict("Điều khoản đã thay đổi. Hãy mở và xác nhận bản mới");
        if(!Objects.equals(a.getConsentVersion(),version)||a.getAcceptedTermsAt()==null) {
            a.setConsentVersion(version); a.setAcceptedTermsAt(clock.instant());
        }
        return read(id,false);
    }
    public void requireWorkerConsent(JobApplication a) {
        if(a.getJob().getStartsOn()!=null && (a.getAcceptedTermsAt()==null||!Objects.equals(a.getConsentVersion(),a.getJob().getTermsVersion())))
            throw conflict("Thợ cần xác nhận lại điều khoản công trình trước khi duyệt");
    }
    /** Called while job and worker locks are held by the acceptance transaction. */
    public void freeze(JobApplication a,boolean acceptOffer) {
        current.requireOwner(a.getJob().getContractor().getId(),Role.ROLE_CONTRACTOR);
        requireWorkerConsent(a);
        if(acceptOffer&&a.getProposedDailyRate()==null) throw new ApiException(HttpStatus.BAD_REQUEST,"Đơn không có đề xuất lương");
        if(a.getContractSnapshot()!=null) throw conflict("Cam kết đã chốt");
        a.setAgreedDailyRate(selected(a,acceptOffer)); a.setContractorConfirmedAt(clock.instant());
        a.setContractSnapshot(text(a.getJob(),a.getProposedDailyRate(),a.getAgreedDailyRate(),a.getAcceptedTermsAt(),a.getContractorConfirmedAt())
            +"\nNgười thợ: "+a.getWorker().getFullName()+"\nMã đơn: "+a.getId());
        try { a.setContractHash(HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(a.getContractSnapshot().getBytes(StandardCharsets.UTF_8)))); }
        catch(java.security.NoSuchAlgorithmException e) { throw new IllegalStateException(e); }
    }
    public static long original(Job job) { return BigDecimal.valueOf(job.getSalaryPerDay()).setScale(0,RoundingMode.HALF_UP).longValueExact(); }
    private long selected(JobApplication a,boolean offer) { return offer&&a.getProposedDailyRate()!=null?a.getProposedDailyRate():original(a.getJob()); }
    private String text(Job j,Long proposed,Long agreed,Instant workerAt,Instant ownerAt) {
        return "PHIẾU CAM KẾT NHẬN VIỆC — THOXAY\nPhiên bản điều khoản: "+j.getTermsVersion()
            +"\nCông trình: "+j.getTitle()+"\nChủ thầu: "+j.getContractor().getFullName()+"\nĐịa điểm: "+j.getAddress()
            +"\nLịch: "+(j.getStartsOn()==null?"Công trình cũ chưa có lịch":j.getStartsOn()+" đến "+j.getEndsOn())
            +"\nLoại việc: "+j.getJobType()+"\nYêu cầu: "+Objects.toString(j.getDescription(),"")
            +"\nLương gốc/ngày: "+original(j)+" VND\nLương thợ đề xuất: "+(proposed==null?"Không có":proposed+" VND")
            +"\nLương chốt/ngày: "+(agreed==null?"Chủ thầu sẽ chọn giá gốc hoặc đề xuất":agreed+" VND")
            +"\nNgày công thực tế và ảnh công việc được chủ thầu nghiệm thu trước khi thanh toán."
            +"\nTiền công, tip và thưởng được ghi nhận khi chủ thầu xác nhận chi trả vào ví."
            +"\nHủy việc đang làm bị trừ 15 điểm uy tín và tính lại bậc thợ."
            +"\nKhông tự động rút tiền; ký quỹ dưới 200.000 VND là cảnh báo."
            +"\nXác nhận thợ: "+(workerAt==null?"Chưa ghi nhận":workerAt)
            +"\nXác nhận chủ thầu: "+(ownerAt==null?"Chưa ghi nhận":ownerAt);
    }
    private void authorize(JobApplication a) {
        var u=current.get();
        if(u.getRole()!=Role.ROLE_ADMIN&&!u.getId().equals(a.getWorker().getId())&&!u.getId().equals(a.getJob().getContractor().getId()))
            throw missing("Cam kết");
    }
    private ApiException missing(String name) { return new ApiException(HttpStatus.NOT_FOUND,name+" không tồn tại"); }
    private ApiException conflict(String text) { return new ApiException(HttpStatus.CONFLICT,text); }
}
