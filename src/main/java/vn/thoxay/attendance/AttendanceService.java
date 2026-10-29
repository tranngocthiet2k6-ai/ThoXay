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
 @Transactional(readOnly=true) public Page history(Long id,LocalDate before){var a=applications.findById(id).orElseThrow(this::missing);authorize(a);var today=LocalDate.now(clock);var rows=records.history(id,before==null?today.plusDays(1):before,PageRequest.of(0,61));return new Page(today,rows.stream().limit(60).toList(),rows.size()>60);}
 @Transactional(readOnly=true) public Page byJob(Long id,LocalDate day,int page){var job=jobs.findById(id).orElseThrow(this::missing);ownerOrAdmin(job);var rows=records.byJob(id,day==null?LocalDate.now(clock):day,PageRequest.of(page,100));return new Page(LocalDate.now(clock),rows,rows.size()==100);}
 @Transactional public Code issue(Long id){var job=jobs.findLockedById(id).orElseThrow(this::missing);current.requireOwner(job.getContractor().getId(),Role.ROLE_CONTRACTOR);working(job,false);date(job);var raw=new byte[32];new SecureRandom().nextBytes(raw);var token=Base64.getUrlEncoder().withoutPadding().encodeToString(raw);var code=codes.findById(id).orElseGet(ShiftCode::new);code.setJob(job);code.setTokenHash(hash(token));code.setExpiresAt(clock.instant().plusSeconds(300));codes.saveAndFlush(code);return new Code(id,token,code.getExpiresAt());}
 @Transactional public Page mark(Long id,AttendanceController.Proof proof,boolean checkout){var worker=current.require(Role.ROLE_WORKER);var a=locked(id);if(!a.getWorker().getId().equals(worker.getId()))throw missing();if(a.getStatus()!=ApplicationStatus.ACCEPTED)throw conflict("Chỉ thợ được nhận mới chấm công");working(a.getJob(),checkout);var today=LocalDate.now(clock);date(a.getJob());var found=records.findByApplicationIdAndWorkDay(id,today);
  if(found.isPresent()&&(!checkout||found.get().getCheckedOutAt()!=null))return history(id,null);
  if(checkout&&found.isEmpty())throw conflict("Cần check-in trước khi check-out");
  String method=proof(a.getJob(),proof);
  var row=found.orElseGet(AttendanceRecord::new);if(!checkout){row.setApplication(a);row.setWorkDay(today);row.setCheckedInAt(clock.instant());row.setCheckinMethod(method);if(method.equals("GPS")){row.setCheckinLatitude(proof.latitude());row.setCheckinLongitude(proof.longitude());row.setCheckinAccuracy(proof.accuracyMeters());}}
  else{row.setCheckedOutAt(clock.instant());row.setCheckoutMethod(method);if(method.equals("GPS")){row.setCheckoutLatitude(proof.latitude());row.setCheckoutLongitude(proof.longitude());row.setCheckoutAccuracy(proof.accuracyMeters());}}
  records.saveAndFlush(row);return history(id,null);
 }
 @Transactional public Page upload(Long id,LocalDate day,MultipartFile file,String caption){var worker=current.require(Role.ROLE_WORKER);var bytes=sanitizer.project(file);var a=locked(id);if(!a.getWorker().getId().equals(worker.getId())||a.getStatus()!=ApplicationStatus.ACCEPTED)throw missing();mutable(a);var row=records.findByApplicationIdAndWorkDay(id,day).orElseThrow(()->conflict("Ngày này chưa có chấm công"));if(row.getCheckedOutAt()==null)throw conflict("Cần check-out trước khi gửi ảnh cuối ngày");var old=logs.findByAttendanceId(row.getId());if(old.isPresent()&&old.get().getStatus().equals("APPROVED"))throw conflict("Ảnh đã nghiệm thu không thể thay đổi");var log=old.orElseGet(WorkLog::new);log.setAttendance(row);log.setPhoto(bytes);log.setCaption(caption.strip());log.setStatus("PENDING");log.setFeedback("");log.setReviewedAt(null);logs.saveAndFlush(log);notices.create(a.getJob().getContractor(),a.getJob(),"work-log:"+log.getId()+":"+clock.instant().toEpochMilli(),"WORK_LOG_READY","Ảnh công việc chờ nghiệm thu","Thợ đã gửi ảnh cuối ngày. Mở Chấm công & nghiệm thu để đối chiếu.");return history(id,null);}
 @Transactional public void review(Long id,boolean approved,String feedback,Long version){var appId=logs.applicationId(id).orElseThrow(this::missing);var a=locked(appId);current.requireOwner(a.getJob().getContractor().getId(),Role.ROLE_CONTRACTOR);mutable(a);var log=logs.findById(id).orElseThrow(this::missing);var state=approved?"APPROVED":"CHANGES_REQUESTED";if(log.getStatus().equals(state)&&log.getFeedback().equals(feedback.strip()))return;if(!Objects.equals(log.getVersion(),version))throw conflict("Ảnh đã được cập nhật; hãy tải lại và xem ảnh mới trước khi nghiệm thu");if(log.getStatus().equals("APPROVED"))throw conflict("Ngày đã nghiệm thu không thể sửa");if(!approved&&feedback.isBlank())throw conflict("Cần ghi rõ nội dung yêu cầu bổ sung");log.setStatus(state);log.setFeedback(feedback.strip());log.setReviewedAt(clock.instant());notices.create(a.getWorker(),a.getJob(),"work-log-review:"+id+":"+clock.instant().toEpochMilli(),"WORK_LOG_REVIEWED",approved?"Ngày công đã nghiệm thu":"Cần bổ sung ảnh công việc",approved?"Chủ thầu đã xác nhận kết quả công việc trong ngày.":feedback.strip());}
 @Transactional(readOnly=true) public byte[] photo(Long id){var appId=logs.applicationId(id).orElseThrow(this::missing);var a=applications.findById(appId).orElseThrow(this::missing);authorize(a);return logs.findById(id).orElseThrow(this::missing).getPhoto();}
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
