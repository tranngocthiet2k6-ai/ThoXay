package vn.thoxay.attendance;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.multipart.MultipartFile;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.exception.ApiException;
import vn.thoxay.media.ImageSanitizer;
import vn.thoxay.service.NotificationService;
import vn.thoxay.wallet.JobPaymentRepository;
import java.time.*;
import java.util.*;
import java.security.*;
import java.nio.charset.StandardCharsets;

@Service @RequiredArgsConstructor
public class AttendanceService {
 private final AttendanceRepository records;
 private final AttendanceCorrectionRepository corrections;
 private final WorkLogRepository logs;
 private final ShiftCodeRepository codes;
 private final JobApplicationRepository applications;
 private final JobRepository jobs;
 private final CurrentUser current;
 private final Clock clock;
 private final ImageSanitizer sanitizer;
 private final JobPaymentRepository payments;
 private final NotificationService notices;
 public record Page(LocalDate today,List<AttendanceView> items,boolean hasMore){}
 public record Code(Long jobId,String token,Instant expiresAt){@Override public String toString(){return "ShiftCode[jobId="+jobId+",token=redacted,expiresAt="+expiresAt+"]";}}
 public record CorrectionHistory(Long id,Instant originalCheckedOutAt,String originalMethod,String status,
   String reason,Instant requestedAt,Long requestedBy,Instant reviewedAt,Long reviewedBy,String feedback,
   Instant correctedCheckedOutAt) {
  static CorrectionHistory of(AttendanceCorrection c){return new CorrectionHistory(c.getId(),c.getOriginalCheckedOutAt(),
   c.getOriginalMethod(),c.getStatus(),c.getReason(),c.getRequestedAt(),c.getRequestedBy(),c.getReviewedAt(),
   c.getReviewedBy(),c.getFeedback(),c.getCorrectedCheckedOutAt());}
 }
 @Transactional(readOnly=true) public List<CorrectionHistory> corrections(Long id){
  var row=records.findById(id).orElseThrow(this::missing);authorize(row.getApplication());
  return corrections.findByAttendanceIdOrderByIdDesc(id).stream().map(CorrectionHistory::of).toList();
 }
 @Transactional public String correctCheckout(Long id,AttendanceController.Correction body){
  var worker=current.require(Role.ROLE_WORKER);var row=lockedRecord(id);var a=row.getApplication();
  if(!a.getWorker().getId().equals(worker.getId()))throw missing();
  mutable(a);version(row,body.version());
  if(row.getCheckedOutAt()==null)throw conflict("Ca vẫn đang làm; hãy tải lại chấm công");
  if(pendingCorrection(row))throw conflict("Yêu cầu điều chỉnh đang chờ chủ thầu duyệt");
  if(body.reason().isBlank())throw conflict("Cần ghi lý do điều chỉnh");
  var log=logs.findByAttendanceId(id);
  boolean undo=!"ADJUSTED".equals(row.getCheckoutMethod())&&!clock.instant().isAfter(row.getCheckedOutAt().plusSeconds(120))
   && row.getWorkDay().equals(LocalDate.now(clock)) && canReopen(a.getJob())
   && (log.isEmpty()||!log.get().getStatus().equals("APPROVED"));
  var c=new AttendanceCorrection();c.setAttendance(row);c.setOriginalCheckedOutAt(row.getCheckedOutAt());
  c.setOriginalMethod(row.getCheckoutMethod());c.setOriginalLatitude(row.getCheckoutLatitude());
  c.setOriginalLongitude(row.getCheckoutLongitude());c.setOriginalAccuracy(row.getCheckoutAccuracy());
  c.setReason(body.reason().strip());c.setRequestedAt(clock.instant());c.setRequestedBy(worker.getId());
  c.setStatus(undo?"AUTO_UNDONE":"PENDING");
  if(undo){c.setReviewedAt(clock.instant());c.setReviewedBy(worker.getId());reopen(row);invalidateLog(row);}
  corrections.saveAndFlush(c);row.setLatestCorrectionId(c.getId());records.saveAndFlush(row);
  notices.create(a.getJob().getContractor(),a.getJob(),"attendance-correction:"+c.getId(),"ATTENDANCE_CORRECTION",
   undo?"Thợ đã hoàn tác kết thúc ca":"Yêu cầu điều chỉnh chấm công",
   a.getWorker().getFullName()+": "+c.getReason());
  return c.getStatus();
 }
 @Transactional public void reviewCorrection(Long id,Long correctionId,AttendanceController.CorrectionReview body){
  var row=lockedRecord(id);var a=row.getApplication();
  current.requireOwner(a.getJob().getContractor().getId(),Role.ROLE_CONTRACTOR);var owner=current.get();
  mutable(a);version(row,body.version());
  if(!Objects.equals(row.getLatestCorrectionId(),correctionId))throw conflict("Yêu cầu đã thay đổi; hãy tải lại");
  var c=corrections.findById(correctionId).orElseThrow(this::missing);
  if(!c.getStatus().equals("PENDING"))throw conflict("Yêu cầu đã được xử lý");
  if(!body.approved()&&body.feedback().isBlank())throw conflict("Cần ghi lý do từ chối");
  if(body.approved()){
   var end=body.correctedCheckedOutAt();
   if(end==null){
    if(!row.getWorkDay().equals(LocalDate.now(clock))||!canReopen(a.getJob()))
     throw conflict("Chỉ mở lại ca trong ngày khi công trình còn hoạt động; hãy chọn giờ ra đúng");
    reopen(row);
   } else {
    if(end.isBefore(row.getCheckedInAt())||end.isAfter(clock.instant())
      ||!end.atZone(clock.getZone()).toLocalDate().equals(row.getWorkDay()))
     throw conflict("Giờ ra phải thuộc ngày công, sau giờ vào và không ở tương lai");
    row.setCheckedOutAt(end);row.setCheckoutMethod("ADJUSTED");
    row.setCheckoutLatitude(null);row.setCheckoutLongitude(null);row.setCheckoutAccuracy(null);
   }
   invalidateLog(row);c.setCorrectedCheckedOutAt(end);
  }
  c.setStatus(body.approved()?"APPROVED":"REJECTED");c.setFeedback(body.feedback().strip());
  c.setReviewedAt(clock.instant());c.setReviewedBy(owner.getId());
  // Touch the attendance row too: stale screens must not act on an older decision.
  row.setCorrectionRevision(row.getCorrectionRevision()+1);records.flush();
  notices.create(a.getWorker(),a.getJob(),"attendance-correction-review:"+c.getId(),"ATTENDANCE_CORRECTION",
   body.approved()?"Điều chỉnh chấm công đã được duyệt":"Yêu cầu điều chỉnh bị từ chối",
   body.approved()?"Kiểm tra lại giờ ca làm; ảnh công việc cần được nghiệm thu lại.":c.getFeedback());
 }
 private AttendanceRecord lockedRecord(Long id){
  locked(records.applicationId(id).orElseThrow(this::missing));
  return records.findById(id).orElseThrow(this::missing);
 }
 private void version(AttendanceRecord row,Long expected){if(!Objects.equals(row.getVersion(),expected))throw conflict("Chấm công đã thay đổi; hãy tải lại trước khi thao tác");}
 private boolean pendingCorrection(AttendanceRecord row){return row.getLatestCorrectionId()!=null&&corrections.findById(row.getLatestCorrectionId()).map(c->c.getStatus().equals("PENDING")).orElse(false);}
 private boolean canReopen(Job job){return job.getContractor().isActive()&&(job.getStatus()==JobStatus.OPEN||job.getStatus()==JobStatus.IN_PROGRESS);}
 private void reopen(AttendanceRecord row){row.setCheckedOutAt(null);row.setCheckoutMethod(null);row.setCheckoutLatitude(null);row.setCheckoutLongitude(null);row.setCheckoutAccuracy(null);}
 private void invalidateLog(AttendanceRecord row){logs.findByAttendanceId(row.getId()).ifPresent(log->{log.setCorrectionRevision(log.getCorrectionRevision()+1);log.setStatus("CHANGES_REQUESTED");log.setFeedback("Chấm công đã điều chỉnh; cần kiểm tra và nghiệm thu lại ảnh công việc.");log.setReviewedAt(null);logs.saveAndFlush(log);});}
 @Transactional(readOnly=true) public Page history(Long id,LocalDate before){var a=applications.findById(id).orElseThrow(this::missing);authorize(a);var today=LocalDate.now(clock);var rows=records.history(id,before==null?today.plusDays(1):before,clock.instant().minusSeconds(120),today,PageRequest.of(0,61));return new Page(today,rows.stream().limit(60).toList(),rows.size()>60);}
 @Transactional(readOnly=true) public Page byJob(Long id,LocalDate day,int page){var job=jobs.findById(id).orElseThrow(this::missing);ownerOrAdmin(job);var rows=records.byJob(id,day==null?LocalDate.now(clock):day,clock.instant().minusSeconds(120),LocalDate.now(clock),PageRequest.of(page,100));return new Page(LocalDate.now(clock),rows,rows.size()==100);}
 @Transactional public Code issue(Long id){var job=jobs.findLockedById(id).orElseThrow(this::missing);current.requireOwner(job.getContractor().getId(),Role.ROLE_CONTRACTOR);working(job,false);date(job);var raw=new byte[32];new SecureRandom().nextBytes(raw);var token=Base64.getUrlEncoder().withoutPadding().encodeToString(raw);var code=codes.findById(id).orElseGet(ShiftCode::new);code.setJob(job);code.setTokenHash(hash(token));code.setExpiresAt(clock.instant().plusSeconds(300));codes.saveAndFlush(code);return new Code(id,token,code.getExpiresAt());}
 @Transactional public Page mark(Long id,AttendanceController.Proof proof,boolean checkout){var worker=current.require(Role.ROLE_WORKER);var a=locked(id);if(!a.getWorker().getId().equals(worker.getId()))throw missing();if(a.getStatus()!=ApplicationStatus.ACCEPTED)throw conflict("Chỉ thợ được nhận mới chấm công");working(a.getJob(),checkout);var today=LocalDate.now(clock);date(a.getJob());var found=records.findByApplicationIdAndWorkDay(id,today);
  if(found.isPresent()&&(!checkout||found.get().getCheckedOutAt()!=null))return history(id,null);
  if(checkout&&found.isEmpty())throw conflict("Cần check-in trước khi check-out");
  String method=proof(a.getJob(),proof);
  var row=found.orElseGet(AttendanceRecord::new);if(!checkout){row.setApplication(a);row.setWorkDay(today);row.setCheckedInAt(clock.instant());row.setCheckinMethod(method);if(method.equals("GPS")){row.setCheckinLatitude(proof.latitude());row.setCheckinLongitude(proof.longitude());row.setCheckinAccuracy(proof.accuracyMeters());}}
  else{row.setCheckedOutAt(clock.instant());row.setCheckoutMethod(method);if(method.equals("GPS")){row.setCheckoutLatitude(proof.latitude());row.setCheckoutLongitude(proof.longitude());row.setCheckoutAccuracy(proof.accuracyMeters());}}
  records.saveAndFlush(row);return history(id,null);
 }
 @Transactional public Page upload(Long id,LocalDate day,MultipartFile file,MultipartFile detailFile,String caption){var worker=current.require(Role.ROLE_WORKER);var bytes=sanitizer.project(file);var detail=detailFile==null?null:sanitizer.project(detailFile);var a=locked(id);if(!a.getWorker().getId().equals(worker.getId())||a.getStatus()!=ApplicationStatus.ACCEPTED)throw missing();mutable(a);var row=records.findByApplicationIdAndWorkDay(id,day).orElseThrow(()->conflict("Ngày này chưa có chấm công"));if(row.getCheckedOutAt()==null)throw conflict("Cần check-out trước khi gửi ảnh cuối ngày");if(pendingCorrection(row))throw conflict("Cần xử lý yêu cầu điều chỉnh chấm công trước khi gửi ảnh");var old=logs.findByAttendanceId(row.getId());if(old.isPresent()&&old.get().getStatus().equals("APPROVED"))throw conflict("Ảnh đã nghiệm thu không thể thay đổi");var log=old.orElseGet(WorkLog::new);log.setAttendance(row);log.setPhoto(bytes);log.setDetailPhoto(detail);log.setCaption(caption.strip());log.setStatus("PENDING");log.setFeedback("");log.setReviewedAt(null);logs.saveAndFlush(log);notices.create(a.getJob().getContractor(),a.getJob(),"work-log:"+log.getId()+":"+clock.instant().toEpochMilli(),"WORK_LOG_READY","Ảnh công việc chờ nghiệm thu","Thợ đã gửi ảnh cuối ngày. Mở Chấm công & nghiệm thu để đối chiếu.");return history(id,null);}
 @Transactional public void review(Long id,boolean approved,String feedback,Long version){var appId=logs.applicationId(id).orElseThrow(this::missing);var a=locked(appId);current.requireOwner(a.getJob().getContractor().getId(),Role.ROLE_CONTRACTOR);mutable(a);var log=logs.findById(id).orElseThrow(this::missing);if(log.getAttendance().getCheckedOutAt()==null||pendingCorrection(log.getAttendance()))throw conflict("Cần kết thúc ca và xử lý điều chỉnh trước khi nghiệm thu");var state=approved?"APPROVED":"CHANGES_REQUESTED";if(log.getStatus().equals(state)&&log.getFeedback().equals(feedback.strip()))return;if(!Objects.equals(log.getVersion(),version))throw conflict("Ảnh đã được cập nhật; hãy tải lại và xem ảnh mới trước khi nghiệm thu");if(log.getStatus().equals("APPROVED"))throw conflict("Ngày đã nghiệm thu không thể sửa");if(!approved&&feedback.isBlank())throw conflict("Cần ghi rõ nội dung yêu cầu bổ sung");log.setStatus(state);log.setFeedback(feedback.strip());log.setReviewedAt(clock.instant());notices.create(a.getWorker(),a.getJob(),"work-log-review:"+id+":"+clock.instant().toEpochMilli(),"WORK_LOG_REVIEWED",approved?"Ngày công đã nghiệm thu":"Cần bổ sung ảnh công việc",approved?"Chủ thầu đã xác nhận kết quả công việc trong ngày.":feedback.strip());}
 @Transactional(readOnly=true) public byte[] photo(Long id){return photo(id,false);}
 @Transactional(readOnly=true) public byte[] photo(Long id,boolean detail){var appId=logs.applicationId(id).orElseThrow(this::missing);var a=applications.findById(appId).orElseThrow(this::missing);authorize(a);var log=logs.findById(id).orElseThrow(this::missing);var bytes=detail?log.getDetailPhoto():log.getPhoto();if(bytes==null)throw missing();return bytes;}
 /** Caller holds the job lock; the attendance/review operations acquire that same lock. */
 public void requirePayable(JobApplication a,int days){if(!a.getJob().isAttendanceRequired()&&!records.existsByApplicationId(a.getId()))return;long total=records.total(a.getId()),approved=records.approved(a.getId());if(total==0||total!=approved||days!=approved)throw conflict("Ngày thanh toán phải khớp toàn bộ ngày đã check-out và ảnh được nghiệm thu ("+approved+"/"+total+" ngày)");}
 private String proof(Job j,AttendanceController.Proof p){if(p.qrToken()!=null&&!p.qrToken().isBlank()){var c=codes.findById(j.getId()).orElseThrow(()->conflict("Chủ thầu chưa tạo mã ca làm"));if(!c.getExpiresAt().isAfter(clock.instant())||!MessageDigest.isEqual(c.getTokenHash().getBytes(StandardCharsets.US_ASCII),hash(p.qrToken()).getBytes(StandardCharsets.US_ASCII)))throw conflict("Mã ca làm sai hoặc đã hết hạn; xin mã mới từ chủ thầu");return "QR";}
  if(p.latitude()==null||p.longitude()==null||p.accuracyMeters()==null||!Double.isFinite(p.latitude())||!Double.isFinite(p.longitude())||!Double.isFinite(p.accuracyMeters())||p.accuracyMeters()<=0||p.accuracyMeters()>100)throw conflict("Cần GPS chính xác trong 100m; hãy ra nơi thoáng hoặc dùng mã QR ca làm");
  double lat=p.latitude(),lng=p.longitude();double h=Math.pow(Math.sin(Math.toRadians(j.getLatitude()-lat)/2),2)+Math.cos(Math.toRadians(lat))*Math.cos(Math.toRadians(j.getLatitude()))*Math.pow(Math.sin(Math.toRadians(j.getLongitude()-lng)/2),2);double meters=6371000*2*Math.asin(Math.sqrt(Math.max(0,Math.min(1,h))));if(meters>200)throw conflict("Bạn cần ở trong bán kính 200m quanh công trình để chấm công GPS");return "GPS";
 }
 private JobApplication locked(Long id){var jobId=applications.findJobIdById(id).orElseThrow(this::missing);jobs.findLockedById(jobId).orElseThrow(this::missing);return applications.findById(id).orElseThrow(this::missing);}
 private void authorize(JobApplication a){var u=current.get();if(u.getRole()!=Role.ROLE_ADMIN&&!u.getId().equals(a.getWorker().getId())&&!u.getId().equals(a.getJob().getContractor().getId()))throw missing();}
 private void ownerOrAdmin(Job j){var u=current.get();if(u.getRole()!=Role.ROLE_ADMIN)current.requireOwner(j.getContractor().getId(),Role.ROLE_CONTRACTOR);}
 private void mutable(JobApplication a){if(a.getStatus()!=ApplicationStatus.ACCEPTED||a.getJob().getStatus()==JobStatus.CANCELLED||payments.findByApplicationId(a.getId()).isPresent())throw conflict("Ngày công đã khóa hoặc công trình đã hủy");}
 private void working(Job j,boolean checkout){if(!j.getContractor().isActive()||j.getStatus()==JobStatus.CANCELLED||(!checkout&&j.getStatus()==JobStatus.COMPLETED))throw conflict("Công trình không nhận chấm công mới");}
 private void date(Job j){var today=LocalDate.now(clock);if(j.getStartsOn()!=null&&(today.isBefore(j.getStartsOn())||today.isAfter(j.getEndsOn())))throw conflict("Hôm nay nằm ngoài lịch làm việc của công trình");}
 private String hash(String token){try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8)));}catch(NoSuchAlgorithmException e){throw new IllegalStateException(e);}}
 private ApiException missing(){return new ApiException(HttpStatus.NOT_FOUND,"Không tìm thấy dữ liệu chấm công");}
 private ApiException conflict(String text){return new ApiException(HttpStatus.CONFLICT,text);}
}
