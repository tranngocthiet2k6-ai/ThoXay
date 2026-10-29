package vn.thoxay.incident;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.service.NotificationService;
import vn.thoxay.exception.ApiException;
import java.time.*;
import java.util.*;
@Service @RequiredArgsConstructor
public class IncidentService {
 private final IncidentRepository incidents;
 private final IncidentAuditRepository audits;
 private final CurrentUser current;
 private final JobRepository jobs;
 private final JobApplicationRepository applications;
 private final UserRepository users;
 private final NotificationService notices;
 private final Clock clock;
 public record Item(Long id,Long jobId,boolean jobAvailable,String jobTitle,String jobAddress,double jobLatitude,double jobLongitude,String reporterName,String reporterPhone,String type,String status,String description,Double reportedLatitude,Double reportedLongitude,String adminNote,Instant createdAt,Long version){@Override public String toString(){return "Incident[id="+id+",type="+type+",status="+status+"]";}}
 public record Audit(Long id,String status,String note,Instant createdAt){}
 public record Detail(Item incident,List<Audit> history){}
 public record Page(List<Item> items,boolean hasMore){}
 public record Counts(long open,long sos){}
 @Transactional public Detail create(Long jobId,IncidentController.Report input){var user=current.get();if(user.getRole()!=Role.ROLE_WORKER&&user.getRole()!=Role.ROLE_CONTRACTOR)throw new ApiException(HttpStatus.FORBIDDEN,"Chỉ người tham gia công trình được gửi sự cố");var job=jobs.findLockedById(jobId).orElseThrow(this::missing);
  boolean owner=user.getId().equals(job.getContractor().getId());boolean participant=applications.existsByJobIdAndWorkerIdAndStatusIn(jobId,user.getId(),List.of(ApplicationStatus.ACCEPTED,ApplicationStatus.CANCELLED));if(!owner&&!participant)throw missing();
  if((input.latitude()==null)!=(input.longitude()==null))throw new ApiException(HttpStatus.BAD_REQUEST,"Vị trí cần đủ vĩ độ và kinh độ");
  var existing=incidents.findByReporterIdAndClientRequestId(user.getId(),input.clientRequestId());if(existing.isPresent()){var old=existing.get();if(!old.getOriginalJobId().equals(jobId)||!old.getType().equals(input.type())||!old.getDescription().equals(input.description().strip())||!Objects.equals(old.getReportedLatitude(),input.latitude())||!Objects.equals(old.getReportedLongitude(),input.longitude()))throw conflict("Mã gửi đã dùng cho nội dung sự cố khác");return detail(old);}
  if(input.description().isBlank())throw new ApiException(HttpStatus.BAD_REQUEST,"Nhập nội dung cần Admin hỗ trợ");
  var r=new Incident();r.setJob(job);r.setOriginalJobId(jobId);r.setJobTitle(job.getTitle());r.setJobAddress(job.getAddress());r.setJobLatitude(job.getLatitude());r.setJobLongitude(job.getLongitude());r.setReporter(user);r.setReporterName(user.getFullName());r.setReporterPhone(user.getPhoneNumber());r.setType(input.type());r.setDescription(input.description().strip());r.setClientRequestId(input.clientRequestId());r.setReportedLatitude(input.latitude());r.setReportedLongitude(input.longitude());r.setCreatedAt(clock.instant());incidents.saveAndFlush(r);
  audit(r,user,"Đã gửi báo cáo tới Admin");
  for(var admin:users.findByRoleAndActiveTrue(Role.ROLE_ADMIN))notices.create(admin,job,"incident:"+r.getId()+":admin:"+admin.getId(),"INCIDENT_"+r.getType(),r.getType().equals("SOS")?"SOS công trường cần ưu tiên":"Sự cố công trình cần xử lý","Báo cáo #"+r.getId()+" tại "+safeTitle(job.getTitle())+". Mở SOS & Sự cố trên trang quản trị.");
  return detail(r);
 }
 @Transactional(readOnly=true) public Detail get(Long id){var r=incidents.findById(id).orElseThrow(this::missing);authorize(r);return detail(r);}
 @Transactional(readOnly=true) public Page mine(Long job,Long before){var u=current.get();var rows=incidents.mine(u.getId(),job,before==null?Long.MAX_VALUE:before,PageRequest.of(0,31));return new Page(rows.stream().limit(30).map(this::item).toList(),rows.size()>30);}
 @Transactional(readOnly=true) public Page queue(String status,String type,String q,int page){current.require(Role.ROLE_ADMIN);if(!List.of("NEW","IN_REVIEW","RESOLVED").contains(status)||!List.of("","SOS","SAFETY","PAYMENT_DISPUTE","OTHER").contains(type))throw new ApiException(HttpStatus.BAD_REQUEST,"Bộ lọc sự cố không hợp lệ");var rows=incidents.queue(status,type,q.toLowerCase(Locale.ROOT).strip(),PageRequest.of(page,30));return new Page(rows.stream().map(this::item).toList(),rows.size()==30);}
 @Transactional(readOnly=true) public Counts counts(){current.require(Role.ROLE_ADMIN);return new Counts(incidents.countByStatusNot("RESOLVED"),incidents.countByTypeAndStatusNot("SOS","RESOLVED"));}
 @Transactional public Detail update(Long id,IncidentController.Update input){var admin=current.require(Role.ROLE_ADMIN);var jobId=incidents.originalJob(id).orElseThrow(this::missing);jobs.findLockedById(jobId);var r=incidents.locked(id).orElseThrow(this::missing);String note=input.note().strip();if(r.getStatus().equals(input.status())&&r.getAdminNote().equals(note))return detail(r);
  if(!Objects.equals(r.getVersion(),input.version()))throw conflict("Báo cáo đã được cập nhật. Tải lại trước khi xử lý");if(r.getStatus().equals("RESOLVED"))throw conflict("Báo cáo đã kết thúc, lịch sử xử lý được giữ nguyên");if(input.status().equals("RESOLVED")&&note.isBlank())throw new ApiException(HttpStatus.BAD_REQUEST,"Cần ghi kết quả xử lý trước khi đóng báo cáo");r.setStatus(input.status());r.setAdminNote(note);r.setUpdatedAt(clock.instant());incidents.saveAndFlush(r);audit(r,admin,note);
  if(r.getReporter()!=null)notices.create(r.getReporter(),r.getJob(),"incident-update:"+id+":"+r.getVersion(),"INCIDENT_UPDATED","Báo cáo đã được Admin cập nhật","Báo cáo #"+id+" đã "+(input.status().equals("RESOLVED")?"có kết quả xử lý":"được tiếp nhận")+". Mở Sự cố đã gửi để xem chi tiết.");return detail(r);
 }
 private void authorize(Incident r){var u=current.get();if(u.getRole()!=Role.ROLE_ADMIN&&(r.getReporter()==null||!r.getReporter().getId().equals(u.getId())))throw missing();}
 private void audit(Incident r,User actor,String note){var a=new IncidentAudit();a.setIncident(r);a.setActor(actor);a.setStatus(r.getStatus());a.setNote(note);a.setCreatedAt(clock.instant());audits.saveAndFlush(a);}
 private Detail detail(Incident r){return new Detail(item(r),audits.findByIncidentIdOrderByIdDesc(r.getId(),PageRequest.of(0,30)).stream().map(a->new Audit(a.getId(),a.getStatus(),a.getNote(),a.getCreatedAt())).toList());}
 private Item item(Incident r){return new Item(r.getId(),r.getOriginalJobId(),r.getJob()!=null,r.getJobTitle(),r.getJobAddress(),r.getJobLatitude(),r.getJobLongitude(),r.getReporterName(),r.getReporterPhone(),r.getType(),r.getStatus(),r.getDescription(),r.getReportedLatitude(),r.getReportedLongitude(),r.getAdminNote(),r.getCreatedAt(),r.getVersion());}
 private String safeTitle(String title){return title.length()>200?title.substring(0,200):title;}
 private ApiException missing(){return new ApiException(HttpStatus.NOT_FOUND,"Không tìm thấy báo cáo sự cố");}
 private ApiException conflict(String text){return new ApiException(HttpStatus.CONFLICT,text);}
}
