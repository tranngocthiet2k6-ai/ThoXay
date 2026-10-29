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
import java.time.*;
import java.util.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
@SpringBootTest @AutoConfigureMockMvc
class CrewHiringTest {
 @Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired UserRepository users;@Autowired JobRepository jobs;
 @Autowired JobApplicationRepository applications;@Autowired JwtUtil jwt;@Autowired Clock clock;
 @Autowired org.springframework.jdbc.core.JdbcTemplate jdbc;
 User leader,member,outsider,owner,admin;Job job;
 @AfterEach void cleanup(){if(job!=null){jdbc.update("DELETE FROM job_applications WHERE job_id=?",job.getId());jdbc.update("DELETE FROM crew_batches WHERE job_id=?",job.getId());jdbc.update("DELETE FROM notifications WHERE job_id=?",job.getId());jdbc.update("DELETE FROM jobs WHERE id=?",job.getId());}
  if(leader!=null)jdbc.update("DELETE FROM crews WHERE leader_id=?",leader.getId());
  for(var u:Arrays.asList(leader,member,outsider,owner,admin))if(u!=null)jdbc.update("DELETE FROM users WHERE id=?",u.getId());
 }
 @BeforeEach void setup(){leader=user("0985555511",Role.ROLE_WORKER);member=user("0985555512",Role.ROLE_WORKER);outsider=user("0985555513",Role.ROLE_WORKER);owner=user("0985555514",Role.ROLE_CONTRACTOR);
 job=new Job();job.setContractor(owner);job.setTitle("Tuyển tổ QA");job.setAddress("QA");job.setJobType("Thợ chính");job.setRequiredWorkers(2);job.setSalaryPerDay(350000);job.setStartsOn(LocalDate.now(clock).plusDays(3));job.setEndsOn(job.getStartsOn().plusDays(2));jobs.saveAndFlush(job);}
 @Test void invitationsNeedActualMemberConsentAndLeaderCannotFabricateIt()throws Exception{
  long crew=create();invite(crew);mvc.perform(get("/api/crews").header("Authorization",token(member))).andExpect(jsonPath("$[0].members[1].status").value("INVITED"));
  mvc.perform(post("/api/crews/"+crew+"/applications").header("Authorization",token(leader)).contentType("application/json").content(applyBody())).andExpect(status().isConflict());
  mvc.perform(post("/api/crews/"+crew+"/invitations").header("Authorization",token(outsider)).contentType("application/json").content("{\"phoneNumber\":\"0985555512\"}")).andExpect(status().isNotFound());
  confirmTeam(crew);apply(crew);
  assertThat(applications.findByJobIdOrderByAppliedAtDesc(job.getId())).hasSize(2);
  assertThat(jdbc.queryForObject("SELECT accepted_terms_at FROM job_applications WHERE job_id=? AND worker_id=?",java.sql.Timestamp.class,job.getId(),member.getId())).isNull();
 }
 @Test void approvalWaitsForEveryoneThenFreezesIndividualContracts()throws Exception{
  long crew=create();invite(crew);confirmTeam(crew);long batch=apply(crew);
  mvc.perform(decide(batch)).andExpect(status().isConflict());
  assertThat(applications.countByJobIdAndStatus(job.getId(),ApplicationStatus.ACCEPTED)).isZero();
  var a=applications.findByJobIdOrderByAppliedAtDesc(job.getId()).stream().filter(x->x.getWorker().getId().equals(member.getId())).findFirst().orElseThrow();
  consent(a.getId());
  mvc.perform(put("/api/applications/"+a.getId()+"/status").header("Authorization",token(owner)).contentType("application/json").content(decisionBody())).andExpect(status().isConflict());
  mvc.perform(decide(batch)).andExpect(status().isOk());mvc.perform(decide(batch)).andExpect(status().isOk());
  assertThat(applications.countByJobIdAndStatus(job.getId(),ApplicationStatus.ACCEPTED)).isEqualTo(2);
  assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.IN_PROGRESS);
  for(var row:applications.findByCrewBatchIdOrderByWorkerIdAsc(batch)){assertThat(row.getContractHash()).hasSize(64);assertThat(row.getAgreedDailyRate()).isEqualTo(350000);assertThat(row.getContractSnapshot()).contains("Người thợ: QA");}
 }
 @Test void oneMembersScheduleConflictRollsBackWholeBatch()throws Exception{
  long crew=create();invite(crew);confirmTeam(crew);long batch=apply(crew);
  var a=applications.findByJobIdOrderByAppliedAtDesc(job.getId()).stream().filter(x->x.getWorker().getId().equals(member.getId())).findFirst().orElseThrow();consent(a.getId());
  mvc.perform(post("/api/users/me/calendar").header("Authorization",token(member)).contentType("application/json").content(json.writeValueAsString(Map.of("from",job.getStartsOn(),"to",job.getStartsOn())))).andExpect(status().isOk());
  mvc.perform(decide(batch)).andExpect(status().isConflict());
  assertThat(applications.countByJobIdAndStatus(job.getId(),ApplicationStatus.ACCEPTED)).isZero();
  assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.OPEN);
  assertThat(jdbc.queryForObject("SELECT count(*) FROM job_applications WHERE crew_batch_id=? AND contract_snapshot IS NOT NULL",Long.class,batch)).isZero();
  assertThat(jdbc.queryForObject("SELECT status FROM crew_batches WHERE id=?",String.class,batch)).isEqualTo("PENDING");
 }
 @Test void adminCanInspectCrewConsentRoster()throws Exception{
  long crew=create();invite(crew);confirmTeam(crew);apply(crew);admin=user("0985555515",Role.ROLE_ADMIN);
  mvc.perform(get("/admin/jobs/"+job.getId()+"/commitments").with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN")))
   .andExpect(status().isOk()).andExpect(content().string(org.hamcrest.Matchers.containsString("Tổ QA")))
   .andExpect(content().string(org.hamcrest.Matchers.containsString("Đang chờ")));
 }
 @Test void memberCanWithdrawPendingBatchButOutsiderCannot()throws Exception{
  long crew=create();invite(crew);confirmTeam(crew);long batch=apply(crew);
  mvc.perform(delete("/api/crew-applications/"+batch+"/participation").header("Authorization",token(outsider))).andExpect(status().isNotFound());
  mvc.perform(delete("/api/crew-applications/"+batch+"/participation").header("Authorization",token(member))).andExpect(status().isOk());
  assertThat(applications.findByCrewBatchIdOrderByWorkerIdAsc(batch)).allMatch(a->a.getStatus()==ApplicationStatus.REJECTED);
  mvc.perform(decide(batch)).andExpect(status().isConflict());
 }
 long create()throws Exception{var r=mvc.perform(post("/api/crews").header("Authorization",token(leader)).contentType("application/json").content("{\"name\":\"Tổ QA\"}")).andExpect(status().isOk()).andReturn();return json.readTree(r.getResponse().getContentAsString()).get("id").asLong();}
 void invite(long id)throws Exception{mvc.perform(post("/api/crews/"+id+"/invitations").header("Authorization",token(leader)).contentType("application/json").content(json.writeValueAsString(Map.of("phoneNumber",member.getPhoneNumber())))).andExpect(status().isOk());}
 void confirmTeam(long id)throws Exception{mvc.perform(put("/api/crews/"+id+"/membership").header("Authorization",token(member)).contentType("application/json").content("{\"accepted\":true}")).andExpect(status().isOk());}
 long apply(long id)throws Exception{var r=mvc.perform(post("/api/crews/"+id+"/applications").header("Authorization",token(leader)).contentType("application/json").content(applyBody())).andExpect(status().isOk()).andReturn();return json.readTree(r.getResponse().getContentAsString()).get("id").asLong();}
 void consent(long id)throws Exception{mvc.perform(put("/api/applications/"+id+"/commitment").header("Authorization",token(member)).contentType("application/json").content("{\"accepted\":true,\"termsVersion\":1}")).andExpect(status().isOk());}
 String applyBody()throws Exception{return json.writeValueAsString(Map.of("jobId",job.getId(),"acceptedTerms",true,"termsVersion",1));}
 String decisionBody(){return "{\"status\":\"ACCEPTED\",\"acceptedTerms\":true,\"termsVersion\":1,\"acceptCounterOffer\":false}";}
 org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder decide(long id){return put("/api/crew-applications/"+id+"/status").header("Authorization",token(owner)).contentType("application/json").content(decisionBody());}
 User user(String phone,Role role){var u=new User();u.setPhoneNumber(phone);u.setPassword("hash");u.setFullName("QA "+phone);u.setRole(role);return users.saveAndFlush(u);}
 String token(User u){return "Bearer "+jwt.generateToken(u.getPhoneNumber());}
}
