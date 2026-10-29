package vn.thoxay;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import vn.thoxay.incident.*;
import java.util.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
@SpringBootTest @AutoConfigureMockMvc @Transactional
class IncidentTest {
 @Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired UserRepository users;@Autowired JobRepository jobs;@Autowired JobApplicationRepository apps;@Autowired JwtUtil jwt;@Autowired IncidentRepository incidents;@Autowired IncidentAuditRepository audits;@Autowired NotificationRepository notifications;@Autowired jakarta.persistence.EntityManager em;@Autowired org.springframework.jdbc.core.JdbcTemplate jdbc;
 User worker,owner,other,admin;Job job;
 @BeforeEach void setup(){worker=person("0981111111",Role.ROLE_WORKER);owner=person("0981111112",Role.ROLE_CONTRACTOR);other=person("0981111113",Role.ROLE_WORKER);admin=person("0981111114",Role.ROLE_ADMIN);job=new Job();job.setContractor(owner);job.setTitle("Công trường sự cố QA");job.setJobType("Thợ chính");job.setAddress("Địa chỉ QA");job.setLatitude(10);job.setLongitude(106);job.setRequiredWorkers(2);job.setSalaryPerDay(350000);jobs.saveAndFlush(job);var app=new JobApplication();app.setJob(job);app.setWorker(worker);app.setStatus(ApplicationStatus.ACCEPTED);apps.saveAndFlush(app);}
 @Test void onlyParticipantsCanCreateAndOnlyReporterOrAdminCanRead()throws Exception{
  mvc.perform(post("/api/jobs/"+job.getId()+"/incidents").header("Authorization",token(other)).contentType("application/json").content(body("SOS","private-case-01","Cần hỗ trợ"))).andExpect(status().isNotFound());
  worker.setAvailable(false);users.saveAndFlush(worker);long id=report(worker,"SOS","private-case-01");
  mvc.perform(get("/api/incidents/"+id).header("Authorization",token(owner))).andExpect(status().isNotFound());
  mvc.perform(get("/api/incidents/"+id).header("Authorization",token(other))).andExpect(status().isNotFound());
  mvc.perform(get("/api/incidents/"+id).header("Authorization",token(worker))).andExpect(status().isOk());
  mvc.perform(get("/api/incidents/me").header("Authorization",token(owner))).andExpect(jsonPath("$.items.length()").value(0));
  mvc.perform(get("/api/incidents/"+id).header("Authorization",token(admin))).andExpect(status().isOk());
 }
 @Test void retriesDoNotDuplicateReportsAuditOrAdminNotification()throws Exception{
  long id=report(worker,"SOS","repeat-case-01");assertThat(report(worker,"SOS","repeat-case-01")).isEqualTo(id);assertThat(incidents.count()).isEqualTo(1);assertThat(audits.count()).isEqualTo(1);assertThat(notifications.countByRecipientIdAndReadAtIsNull(admin.getId())).isEqualTo(1);
  mvc.perform(post("/api/jobs/"+job.getId()+"/incidents").header("Authorization",token(worker)).contentType("application/json").content(body("SOS","repeat-case-01","Nội dung thay đổi"))).andExpect(status().isConflict());
 }
 @Test void sosIsFirstInAdminQueueAndPushOutbox()throws Exception{
  var normal=new AppNotification();normal.setRecipient(admin);normal.setEventKey("qa-priority-normal");normal.setType("NORMAL_QA");normal.setTitle("QA");normal.setBody("QA");normal.setPushStatus("PENDING");notifications.saveAndFlush(normal);
  long sos=report(worker,"SOS","sos-priority-01");report(owner,"SAFETY","other-priority-01");
  mvc.perform(get("/api/admin/incidents").header("Authorization",token(admin))).andExpect(jsonPath("$.items[0].id").value(sos));
  var n=notifications.findByRecipientIdAndIdLessThanOrderByIdDesc(admin.getId(),Long.MAX_VALUE,org.springframework.data.domain.PageRequest.of(0,20)).stream().filter(x->x.getType().equals("INCIDENT_SOS")).findFirst().orElseThrow();n.setPushStatus("PENDING");notifications.saveAndFlush(n);
  assertThat(notifications.due(java.time.Instant.now().plusSeconds(1),org.springframework.data.domain.PageRequest.of(0,10)).get(0)).isEqualTo(n.getId());
 }
 @Test void adminUpdatesAreVersionedRequireResultAndNotifyReporter()throws Exception{
  long id=report(worker,"SOS","update-case-01");update(id,"IN_REVIEW","Đã tiếp nhận",0,200);update(id,"RESOLVED","Đã xử lý",0,409);update(id,"RESOLVED","",1,400);update(id,"RESOLVED","Đã xử lý",1,200);update(id,"RESOLVED","Đã xử lý",1,200);
  assertThat(audits.findByIncidentIdOrderByIdDesc(id,org.springframework.data.domain.PageRequest.of(0,20))).hasSize(3);assertThat(notifications.countByRecipientIdAndReadAtIsNull(worker.getId())).isEqualTo(2);
  mvc.perform(get("/admin/incidents/counts").with(user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(jsonPath("$.open").value(0)).andExpect(jsonPath("$.sos").value(0));
 }
 @Test void adminWebRendersPrivateReportAndAcceptsCsrfUpdate()throws Exception{
  long id=report(worker,"PAYMENT_DISPUTE","web-dispute-01");
  mvc.perform(get("/admin/incidents").with(user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk()).andExpect(content().string(org.hamcrest.Matchers.containsString("Công trường sự cố QA")));
  mvc.perform(get("/admin/incidents/"+id).with(user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk()).andExpect(content().string(org.hamcrest.Matchers.containsString(worker.getPhoneNumber())));
  mvc.perform(post("/admin/incidents/"+id).with(user(admin.getPhoneNumber()).roles("ADMIN")).with(csrf()).param("status","IN_REVIEW").param("note","Đang đối chiếu giao dịch").param("version","0")).andExpect(status().is3xxRedirection());
 }
 @Test @Transactional(propagation=org.springframework.transaction.annotation.Propagation.NOT_SUPPORTED) void removingJobPreservesIncidentSnapshotAndHistory()throws Exception{
  long id=report(worker,"SAFETY","survive-case-01");
  mvc.perform(post("/admin/jobs/"+job.getId()+"/delete").with(user(admin.getPhoneNumber()).roles("ADMIN")).with(csrf())).andExpect(status().is3xxRedirection());
  mvc.perform(get("/api/incidents/"+id).header("Authorization",token(worker))).andExpect(status().isOk()).andExpect(jsonPath("$.incident.jobAvailable").value(false)).andExpect(jsonPath("$.incident.jobTitle").value("Công trường sự cố QA")).andExpect(jsonPath("$.history.length()").value(1));
 }
 @AfterEach void cleanupStandalone(TestInfo info){if(info.getTestMethod().orElseThrow().getName().equals("removingJobPreservesIncidentSnapshotAndHistory")&&job!=null){
  jdbc.update("DELETE FROM incident_audit WHERE incident_id IN (SELECT id FROM incidents WHERE original_job_id=?)",job.getId());jdbc.update("DELETE FROM incidents WHERE original_job_id=?",job.getId());jdbc.update("DELETE FROM job_applications WHERE job_id=?",job.getId());jdbc.update("DELETE FROM jobs WHERE id=?",job.getId());
  for(var u:Arrays.asList(worker,owner,other,admin))if(u!=null)jdbc.update("DELETE FROM users WHERE id=?",u.getId());
 }}
 long report(User reporter,String type,String key)throws Exception{var r=mvc.perform(post("/api/jobs/"+job.getId()+"/incidents").header("Authorization",token(reporter)).contentType("application/json").content(body(type,key,"Cần Admin hỗ trợ QA"))).andExpect(status().isOk()).andReturn();return json.readTree(r.getResponse().getContentAsString()).get("incident").get("id").asLong();}
 String body(String type,String key,String description)throws Exception{return json.writeValueAsString(Map.of("type",type,"description",description,"clientRequestId",key));}
 void update(long id,String status,String note,long version,int expected)throws Exception{mvc.perform(put("/api/admin/incidents/"+id).header("Authorization",token(admin)).contentType("application/json").content(json.writeValueAsString(Map.of("status",status,"note",note,"version",version)))).andExpect(status().is(expected));}
 User person(String phone,Role role){var u=new User();u.setPhoneNumber(phone);u.setFullName("QA");u.setPassword("hash");u.setRole(role);return users.saveAndFlush(u);}
 String token(User u){return "Bearer "+jwt.generateToken(u.getPhoneNumber());}
}
