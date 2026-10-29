package vn.thoxay.crew;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import vn.thoxay.dto.*;
import vn.thoxay.entity.*;
import vn.thoxay.exception.ApiException;
import vn.thoxay.repository.*;
import vn.thoxay.security.CurrentUser;
import vn.thoxay.service.*;
import java.time.*;
import java.util.*;

@Service @RequiredArgsConstructor
public class CrewService {
 private final CrewRepository crews;
 private final CrewMemberRepository members;
 private final CrewBatchRepository batches;
 private final UserRepository users;
 private final JobRepository jobs;
 private final JobApplicationRepository applications;
 private final CurrentUser current;
 private final WorkerRatingService locks;
 private final ApplicationService decisions;
 private final NotificationService notices;
 private final Clock clock;
 public record Member(Long id,String name,String status){}
 public record Team(Long id,String name,Long leaderId,List<Member> members){}
 public record Batch(Long id,Long jobId,String crewName,String status,List<Member> members){}
 @Transactional(readOnly=true) public List<Team> mine(){var user=current.require(Role.ROLE_WORKER);return members.findByWorkerIdOrderByIdDesc(user.getId()).stream().filter(m->!m.getStatus().equals("DECLINED")).map(m->team(m.getCrew())).toList();}
 @Transactional public Team create(String name){var leader=current.require(Role.ROLE_WORKER);users.findLockedById(leader.getId()).orElseThrow();if(crews.countByLeaderId(leader.getId())>=10)throw conflict("Tối đa 10 tổ đội mỗi tổ trưởng");var crew=new Crew();crew.setLeader(leader);crew.setName(name.trim());crews.saveAndFlush(crew);var m=new CrewMember();m.setCrew(crew);m.setWorker(leader);m.setStatus("CONFIRMED");m.setConfirmedAt(clock.instant());members.saveAndFlush(m);return team(crew);}
 @Transactional public Team invite(Long id,String phone){var c=owned(id);var worker=users.findByPhoneNumber(phone).filter(u->u.isActive()&&u.getRole()==Role.ROLE_WORKER).orElseThrow(()->missing("Không tìm thấy tài khoản thợ đang hoạt động"));
  var roster=members.findByCrewIdOrderByWorkerIdAsc(id);var existing=members.findByCrewIdAndWorkerId(id,worker.getId());
  if(existing.isPresent()&&!existing.get().getStatus().equals("DECLINED"))return team(c);
  if(roster.stream().filter(m->!m.getStatus().equals("DECLINED")).count()>=20)throw conflict("Tối đa 20 thành viên trong tổ");
  var m=existing.orElseGet(CrewMember::new);m.setCrew(c);m.setWorker(worker);m.setStatus("INVITED");m.setConfirmedAt(null);members.saveAndFlush(m);
  notices.create(worker,null,"crew-invite:"+m.getId()+":"+clock.instant().toEpochMilli(),"CREW_INVITATION","Lời mời tham gia tổ đội","Bạn được mời vào tổ "+c.getName()+". Mở Hồ sơ > Tổ đội để phản hồi.");return team(c);
 }
 @Transactional public Team membership(Long id,boolean accepted){var worker=current.require(Role.ROLE_WORKER);var c=crews.locked(id).orElseThrow(()->missing("Tổ đội không tồn tại"));var m=members.findByCrewIdAndWorkerId(id,worker.getId()).orElseThrow(()->missing("Bạn không có lời mời này"));
  if(c.getLeader().getId().equals(worker.getId()))throw conflict("Tổ trưởng không thể rời tổ của mình");
  if(m.getStatus().equals("DECLINED"))throw conflict("Cần lời mời mới từ tổ trưởng");
  m.setStatus(accepted?"CONFIRMED":"DECLINED");m.setConfirmedAt(accepted?clock.instant():null);return team(c);
 }
 @Transactional public Batch apply(Long id,ApplicationRequest request){var leader=current.require(Role.ROLE_WORKER);var job=jobs.findLockedById(request.jobId()).orElseThrow(()->missing("Công trình không tồn tại"));var c=owned(id);
  if(job.getStartsOn()==null)throw conflict("Ứng tuyển tổ đội cần công trình có lịch cụ thể");
  if(job.getEndsOn().isBefore(LocalDate.now(clock))||!job.getContractor().isActive()||!List.of(JobStatus.OPEN,JobStatus.IN_PROGRESS).contains(job.getStatus()))throw conflict("Công trình đã ngừng tuyển");
  if(!Boolean.TRUE.equals(request.acceptedTerms())||!Objects.equals(request.termsVersion(),job.getTermsVersion()))throw conflict("Tổ trưởng cần đọc và xác nhận điều khoản hiện tại");
  if(batches.existsByCrewIdAndJobId(id,job.getId()))throw conflict("Tổ đã ứng tuyển công trình này");
  var roster=members.findByCrewIdOrderByWorkerIdAsc(id).stream().filter(m->m.getStatus().equals("CONFIRMED")).toList();
  if(roster.size()<2)throw conflict("Cần ít nhất 2 thành viên đã xác nhận tham gia tổ");
  var workers=locks.lockWorkers(roster.stream().map(m->m.getWorker().getId()).toList());
  if(applications.countByJobIdAndStatus(job.getId(),ApplicationStatus.ACCEPTED)+workers.size()>job.getRequiredWorkers())throw conflict("Công trình không đủ chỗ cho toàn bộ tổ");
  for(var w:workers){if(!w.isActive()||!w.isAvailable())throw conflict("Mọi thành viên phải đang hoạt động và Online");if(applications.existsByJobIdAndWorkerId(job.getId(),w.getId()))throw conflict("Một thành viên đã có đơn cho công trình này");}
  var batch=new CrewBatch();batch.setCrew(c);batch.setJob(job);batches.saveAndFlush(batch);
  for(var w:workers){var a=new JobApplication();a.setJob(job);a.setWorker(w);a.setCrewBatch(batch);a.setProposedDailyRate(request.proposedDailyRate());a.setWageNote(request.wageNote());
   if(w.getId().equals(leader.getId())){a.setConsentVersion(job.getTermsVersion());a.setAcceptedTermsAt(clock.instant());}
   applications.saveAndFlush(a);notices.create(w,job,"crew-job:"+batch.getId()+":"+w.getId(),"CREW_JOB_CONSENT","Xác nhận công trình tổ đội","Tổ trưởng đã đề xuất công trình. Mở Đã ứng tuyển để đọc cam kết hoặc rút tổ trước khi duyệt.");}
  notices.create(job.getContractor(),job,"crew-application:"+batch.getId(),"CREW_APPLICATION","Tổ đội ứng tuyển",c.getName()+" có "+workers.size()+" thành viên. Chờ đủ xác nhận trước khi duyệt.");return batch(batch);
 }
 @Transactional public Batch decide(Long id,ApplicationStatusRequest request){var jobId=batches.findJobId(id).orElseThrow(()->missing("Đơn tổ đội không tồn tại"));var job=jobs.findLockedById(jobId).orElseThrow();current.requireOwner(job.getContractor().getId(),Role.ROLE_CONTRACTOR);
  var b=batches.findById(id).orElseThrow();if(!List.of("ACCEPTED","REJECTED").contains(request.status()))throw conflict("Chọn nhận hoặc từ chối tổ");
  if(!b.getStatus().equals("PENDING")&&!b.getStatus().equals(request.status()))throw conflict("Đơn tổ đã xử lý");
  var roster=applications.findByCrewBatchIdOrderByWorkerIdAsc(id);locks.lockWorkers(roster.stream().map(a->a.getWorker().getId()).toList());
  if(b.getStatus().equals("PENDING")&&request.status().equals("ACCEPTED")){
   if(roster.stream().anyMatch(a->a.getStatus()!=ApplicationStatus.PENDING))throw conflict("Một thành viên đã rút; không thể nhận thiếu người trong tổ");
   if(applications.countByJobIdAndStatus(job.getId(),ApplicationStatus.ACCEPTED)+roster.size()>job.getRequiredWorkers())throw conflict("Không đủ chỗ nhận toàn bộ tổ");
  }
  for(var a:roster)decisions.updateCrewMemberStatus(a.getId(),request);
  b.setStatus(request.status());return batch(b);
 }
 @Transactional public Batch withdraw(Long id){var worker=current.require(Role.ROLE_WORKER);var jobId=batches.findJobId(id).orElseThrow(()->missing("Đơn tổ không tồn tại"));var job=jobs.findLockedById(jobId).orElseThrow();var b=batches.findById(id).orElseThrow();var roster=applications.findByCrewBatchIdOrderByWorkerIdAsc(id);
  if(roster.stream().noneMatch(a->a.getWorker().getId().equals(worker.getId())))throw missing("Đơn tổ không tồn tại");
  if(b.getStatus().equals("REJECTED"))return batch(b);
  if(!b.getStatus().equals("PENDING"))throw conflict("Tổ đã được duyệt; hủy việc theo từng người và quy định phạt");
  for(var a:roster){a.setStatus(ApplicationStatus.REJECTED);notices.create(a.getWorker(),job,"crew-withdraw:"+id+":"+a.getWorker().getId(),"CREW_WITHDRAWN","Tổ đã rút ứng tuyển","Một thành viên không tham gia. Tổ cần thống nhất lại trước khi nhận việc.");}b.setStatus("REJECTED");return batch(b);
 }
 @Transactional(readOnly=true) public List<Batch> byJob(Long id){var j=jobs.findById(id).orElseThrow(()->missing("Công trình không tồn tại"));var u=current.get();if(u.getRole()!=Role.ROLE_ADMIN)current.requireOwner(j.getContractor().getId(),Role.ROLE_CONTRACTOR);return batches.findByJobIdOrderByIdDesc(id).stream().map(this::batch).toList();}
 private Crew owned(Long id){var u=current.require(Role.ROLE_WORKER);var c=crews.locked(id).orElseThrow(()->missing("Tổ không tồn tại"));if(!c.getLeader().getId().equals(u.getId()))throw missing("Bạn không phải tổ trưởng");return c;}
 private Team team(Crew c){return new Team(c.getId(),c.getName(),c.getLeader().getId(),members.findByCrewIdOrderByWorkerIdAsc(c.getId()).stream().map(m->new Member(m.getWorker().getId(),m.getWorker().getFullName(),m.getStatus())).toList());}
 private Batch batch(CrewBatch b){return new Batch(b.getId(),b.getJob().getId(),b.getCrew().getName(),b.getStatus(),applications.findByCrewBatchIdOrderByWorkerIdAsc(b.getId()).stream().map(a->new Member(a.getWorker().getId(),a.getWorker().getFullName(),Objects.equals(a.getConsentVersion(),b.getJob().getTermsVersion())&&a.getAcceptedTermsAt()!=null?"CONFIRMED":"AWAITING_CONSENT")).toList());}
 private ApiException missing(String s){return new ApiException(HttpStatus.NOT_FOUND,s);}
 private ApiException conflict(String s){return new ApiException(HttpStatus.CONFLICT,s);}
}
