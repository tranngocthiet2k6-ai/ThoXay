package vn.thoxay;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import vn.thoxay.attendance.*;
import vn.thoxay.wallet.*;
import java.time.*;
import java.util.*;
import java.awt.image.BufferedImage;
import java.io.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
@SpringBootTest @AutoConfigureMockMvc @Transactional @Import(AttendanceTest.TimeConfig.class)
class AttendanceTest {
 @TestConfiguration static class TimeConfig {@Bean @Primary TestClock qaClock(){return new TestClock();}}
 static class TestClock extends Clock {Instant now=Instant.parse("2030-03-01T01:00:00Z");public ZoneId getZone(){return ZoneId.of("Asia/Ho_Chi_Minh");}public Clock withZone(ZoneId zone){return Clock.fixed(now,zone);}public Instant instant(){return now;}}
 @Autowired TestClock clock;@Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired UserRepository users;@Autowired JobRepository jobs;@Autowired JobApplicationRepository applications;@Autowired JwtUtil jwt;@Autowired AttendanceRepository records;@Autowired ShiftCodeRepository codes;@Autowired WalletAccountRepository wallets;@Autowired WorkLogRepository logs;
 User worker,owner,outsider;Job job;JobApplication app;
 @BeforeEach void setup(){clock.now=Instant.parse("2030-03-01T01:00:00Z");worker=user("0983333311",Role.ROLE_WORKER);owner=user("0983333312",Role.ROLE_CONTRACTOR);outsider=user("0983333313",Role.ROLE_WORKER);job=new Job();job.setContractor(owner);job.setTitle("Chấm công QA");job.setAddress("QA");job.setJobType("Thợ chính");job.setSalaryPerDay(350000);job.setRequiredWorkers(2);job.setLatitude(10);job.setLongitude(106);job.setStatus(JobStatus.IN_PROGRESS);job.setStartsOn(LocalDate.now(clock));job.setEndsOn(LocalDate.now(clock).plusDays(1));job.setAttendanceRequired(true);jobs.saveAndFlush(job);app=new JobApplication();app.setJob(job);app.setWorker(worker);app.setStatus(ApplicationStatus.ACCEPTED);app.setAgreedDailyRate(350000L);applications.saveAndFlush(app);}
 @Test void newlyPostedJobsRequireAttendanceForSettlement()throws Exception{
  mvc.perform(post("/api/jobs").header("Authorization",token(owner)).contentType("application/json").content(json.writeValueAsString(Map.of("title","Việc mới","jobType","Thợ chính","salaryPerDay",350000,"address","QA","latitude",10,"longitude",106,"requiredWorkers",1,"startsOn",LocalDate.now(clock),"endsOn",LocalDate.now(clock)))))
   .andExpect(status().isCreated()).andExpect(jsonPath("$.attendanceRequired").value(true));
 }
 @Test void gpsChecksDistanceAccuracyOwnershipAndIdempotence()throws Exception{
  mark("check-out",gps(),409);mark("check-in",Map.of("latitude",11,"longitude",106,"accuracyMeters",10),409);mark("check-in",Map.of("latitude",10,"longitude",106,"accuracyMeters",150),409);
  mark("check-in",gps(),200);mark("check-in",gps(),200);assertThat(records.total(app.getId())).isEqualTo(1);
  clock.now=clock.now.plusSeconds(3600);mark("check-out",gps(),200);mark("check-out",gps(),200);
  var row=records.findByApplicationIdAndWorkDay(app.getId(),LocalDate.now(clock)).orElseThrow();assertThat(row.getCheckinMethod()).isEqualTo("GPS");assertThat(row.getCheckedOutAt()).isAfter(row.getCheckedInAt());
  mvc.perform(get("/api/applications/"+app.getId()+"/attendance").header("Authorization",token(outsider))).andExpect(status().isNotFound());
  mvc.perform(post("/api/applications/"+app.getId()+"/attendance/check-in").header("Authorization",token(outsider)).contentType("application/json").content(json.writeValueAsString(gps()))).andExpect(status().isNotFound());
 }
 @Test void shiftCodesAreHashedRotatableAndExpireAfterFiveMinutes()throws Exception{
  String first=code();assertThat(first).hasSize(43);assertThat(codes.findById(job.getId()).orElseThrow().getTokenHash()).hasSize(64).isNotEqualTo(first);
  mark("check-in",Map.of("qrToken",first),200);String second=code();assertThat(second).isNotEqualTo(first);mark("check-out",Map.of("qrToken",first),409);
  clock.now=clock.now.plusSeconds(301);mark("check-out",Map.of("qrToken",second),409);String third=code();mark("check-out",Map.of("qrToken",third),200);
  mvc.perform(post("/api/jobs/"+job.getId()+"/attendance/shift-code").header("Authorization",token(outsider))).andExpect(status().isForbidden());
 }
 @Test void datesUseVietnamDayAndRejectOutsideSchedule()throws Exception{
  clock.now=Instant.parse("2030-02-28T18:00:00Z");mark("check-in",gps(),200);
  assertThat(records.findByApplicationIdAndWorkDay(app.getId(),LocalDate.of(2030,3,1))).isPresent();
  clock.now=Instant.parse("2030-03-03T01:00:00Z");mark("check-in",gps(),409);
 }
 @Test void workPhotoRequiresCheckoutAndIsPrivateToJobParticipants()throws Exception{
  mark("check-in",gps(),200);
  mvc.perform(uploadRequest()).andExpect(status().isConflict());mark("check-out",gps(),200);long log=upload();
  mvc.perform(get("/api/work-logs/"+log+"/photo").header("Authorization",token(outsider))).andExpect(status().isNotFound());
  mvc.perform(get("/api/work-logs/"+log+"/photo").header("Authorization",token(owner))).andExpect(status().isOk()).andExpect(header().string("Cache-Control","no-store"));
  mvc.perform(put("/api/work-logs/"+log+"/review").header("Authorization",token(worker)).contentType("application/json").content("{\"approved\":true,\"feedback\":\"\",\"version\":0}")).andExpect(status().isForbidden());
  review(log,false,"Chụp rõ phần tô tường");long revised=upload();assertThat(revised).isEqualTo(log);review(log,true,"");mvc.perform(uploadRequest()).andExpect(status().isConflict());
 }
 @Test void changedPhotoRequiresReviewerToReloadVersion()throws Exception{
  mark("check-in",gps(),200);mark("check-out",gps(),200);long log=upload();long version=logs.findById(log).orElseThrow().getVersion();
  mvc.perform(uploadRequest("Ảnh cập nhật mới")).andExpect(status().isOk());
  mvc.perform(put("/api/work-logs/"+log+"/review").header("Authorization",token(owner)).contentType("application/json").content(json.writeValueAsString(Map.of("approved",true,"feedback","","version",version)))).andExpect(status().isConflict());
  assertThat(logs.findById(log).orElseThrow().getStatus()).isEqualTo("PENDING");review(log,true,"");
 }
 @Test void adminCanInspectAttendanceWithPrivateImageSession()throws Exception{
  mark("check-in",gps(),200);mark("check-out",gps(),200);long log=upload();var admin=user("0983333314",Role.ROLE_ADMIN);
  mvc.perform(get("/admin/jobs/"+job.getId()+"/attendance").param("day",LocalDate.now(clock).toString()).with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk()).andExpect(content().string(org.hamcrest.Matchers.containsString("08:00")));
  mvc.perform(get("/admin/work-logs/"+log+"/photo").with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk());
 }
 @Test void paymentWaitsForReviewedDaysAndCannotDoublePay()throws Exception{
  app.setWorkerRating(5);applications.saveAndFlush(app);job.setStatus(JobStatus.COMPLETED);jobs.saveAndFlush(job);pay(1,409);
  job.setStatus(JobStatus.IN_PROGRESS);jobs.saveAndFlush(job);mark("check-in",gps(),200);mark("check-out",gps(),200);long log=upload();job.setStatus(JobStatus.COMPLETED);jobs.saveAndFlush(job);pay(1,409);review(log,true,"");
  var wallet=new WalletAccount();wallet.setUser(owner);wallet.setMainBalance(1000000);wallets.saveAndFlush(wallet);pay(2,409);pay(1,200);pay(1,200);
  assertThat(wallets.findById(worker.getId()).orElseThrow().getMainBalance()).isEqualTo(350000);
  mvc.perform(uploadRequest()).andExpect(status().isConflict());
 }
 void pay(int days,int status)throws Exception{mvc.perform(post("/api/wallet/job-payments").header("Authorization",token(owner)).contentType("application/json").content(json.writeValueAsString(Map.of("applicationId",app.getId(),"workDays",days,"tip",0,"bonus",0)))).andExpect(status().is(status));}
 void mark(String action,Map<String,Object> body,int status)throws Exception{mvc.perform(post("/api/applications/"+app.getId()+"/attendance/"+action).header("Authorization",token(worker)).contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().is(status));}
 String code()throws Exception{var r=mvc.perform(post("/api/jobs/"+job.getId()+"/attendance/shift-code").header("Authorization",token(owner))).andExpect(status().isOk()).andReturn();return json.readTree(r.getResponse().getContentAsString()).get("token").asText();}
 long upload()throws Exception{var r=mvc.perform(uploadRequest()).andExpect(status().isOk()).andReturn();return json.readTree(r.getResponse().getContentAsString()).get("items").get(0).get("logId").asLong();}
 org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder uploadRequest()throws Exception{return uploadRequest("Tiến độ trong ngày QA");}
 org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder uploadRequest(String caption)throws Exception{var out=new ByteArrayOutputStream();javax.imageio.ImageIO.write(new BufferedImage(320,240,BufferedImage.TYPE_INT_RGB),"png",out);return multipart("/api/applications/"+app.getId()+"/work-logs").file(new MockMultipartFile("photo","qa.png","image/png",out.toByteArray())).param("day",LocalDate.now(clock).toString()).param("caption",caption).header("Authorization",token(worker));}
 void review(long id,boolean approved,String feedback)throws Exception{mvc.perform(put("/api/work-logs/"+id+"/review").header("Authorization",token(owner)).contentType("application/json").content(json.writeValueAsString(Map.of("approved",approved,"feedback",feedback,"version",logs.findById(id).orElseThrow().getVersion())))).andExpect(status().isOk());}
 Map<String,Object> gps(){return Map.of("latitude",10,"longitude",106,"accuracyMeters",10);}
 User user(String phone,Role role){var u=new User();u.setPhoneNumber(phone);u.setFullName("QA");u.setPassword("hash");u.setRole(role);return users.saveAndFlush(u);}
 String token(User u){return "Bearer "+jwt.generateToken(u.getPhoneNumber());}
}
