package vn.thoxay;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import vn.thoxay.wallet.*;
import java.util.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
class SettlementLifecycleTest {
 @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired JwtUtil jwt;
 @Autowired UserRepository users; @Autowired JobRepository jobs; @Autowired JobApplicationRepository applications;
 @Autowired WalletAccountRepository wallets; @Autowired JobPaymentRepository payments;
 @Autowired org.springframework.transaction.PlatformTransactionManager transactions;
 User owner,first,second; Job job; JobApplication a,b;
 @BeforeEach void setup(){
  owner=user("0985666601",Role.ROLE_CONTRACTOR);first=user("0985666602",Role.ROLE_WORKER);second=user("0985666603",Role.ROLE_WORKER);
  first.setReputationScore(80);second.setReputationScore(80);users.saveAllAndFlush(List.of(first,second));
  job=new Job();job.setContractor(owner);job.setTitle("Chờ thanh toán");job.setJobType("Thợ chính");job.setSalaryPerDay(250000);job.setRequiredWorkers(2);job.setAddress("QA");job.setLatitude(10);job.setLongitude(106);job.setStatus(JobStatus.IN_PROGRESS);jobs.saveAndFlush(job);
  a=application(first);b=application(second);
  new org.springframework.transaction.support.TransactionTemplate(transactions).executeWithoutResult(tx->{var wallet=new WalletAccount();wallet.setUser(users.findById(owner.getId()).orElseThrow());wallet.setMainBalance(1000000);wallets.saveAndFlush(wallet);});
 }
 @AfterEach void cleanup(){applications.deleteAllInBatch();jobs.deleteAllInBatch();users.deleteAllInBatch();}
 @Test void ratingsRemainInProgressUntilEveryAcceptedWorkerHasActuallyBeenPaid()throws Exception{
  review(200,4).andExpect(jsonPath("$.status").value("IN_PROGRESS")).andExpect(jsonPath("$.ratingsFinalizedAt").isNotEmpty());
  mvc.perform(get("/api/users/me/settings/role-blockers").header("Authorization",token(owner)))
   .andExpect(status().isOk()).andExpect(jsonPath("$[0].reason").value("UNPAID_WORK"));
  assertThat(savedFirst().getCompletedJobs()).isZero();assertThat(savedFirst().getReputationScore()).isEqualTo(80);
  mvc.perform(get("/api/applications/worker/"+first.getId()).header("Authorization",token(first)))
   .andExpect(jsonPath("$[0].job.status").value("IN_PROGRESS")).andExpect(jsonPath("$[0].jobRating").value(4)).andExpect(jsonPath("$[0].paidAt").isEmpty());
  pay(a,200);assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.IN_PROGRESS);
  mvc.perform(get("/api/applications/worker/"+first.getId()).header("Authorization",token(first))).andExpect(jsonPath("$[0].paidAt").isNotEmpty());
  pay(b,200);assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.COMPLETED);
  assertThat(savedFirst().getCompletedJobs()).isEqualTo(1);assertThat(savedFirst().getRating()).isEqualTo(4);assertThat(savedFirst().getReputationScore()).isEqualTo(82);
  mvc.perform(get("/api/users/me/settings/role-blockers").header("Authorization",token(owner))).andExpect(jsonPath("$.length()").value(0));
  pay(a,200);pay(b,200);review(200,4);review(409,5);
  assertThat(payments.findByJobIdOrderByIdDesc(job.getId())).hasSize(2);
  assertThat(wallets.findById(owner.getId()).orElseThrow().getMainBalance()).isEqualTo(500000);
  assertThat(savedFirst().getReputationScore()).isEqualTo(82);
 }
 @Test void failedPaymentKeepsWorkActiveAndDoesNotCreateIncome()throws Exception{
  pay(a,409);review(200,4);review(200,4);review(409,5);
  var wallet=wallets.findById(owner.getId()).orElseThrow();wallet.setMainBalance(0);wallets.saveAndFlush(wallet);
  pay(a,409);assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.IN_PROGRESS);
  assertThat(payments.findByJobIdOrderByIdDesc(job.getId())).isEmpty();assertThat(savedFirst().getCompletedJobs()).isZero();
  mvc.perform(get("/api/applications/worker/"+first.getId()).header("Authorization",token(first))).andExpect(jsonPath("$[0].paidAt").isEmpty());
 }
 org.springframework.test.web.servlet.ResultActions review(int status,int stars)throws Exception{
  return mvc.perform(put("/api/jobs/"+job.getId()+"/complete").header("Authorization",token(owner)).contentType("application/json")
   .content(json.writeValueAsString(Map.of("ratings",List.of(Map.of("workerId",first.getId(),"stars",stars),Map.of("workerId",second.getId(),"stars",3)))))).andExpect(status().is(status));
 }
 void pay(JobApplication app,int status)throws Exception{mvc.perform(post("/api/wallet/job-payments").header("Authorization",token(owner)).contentType("application/json")
  .content(json.writeValueAsString(Map.of("applicationId",app.getId(),"workDays",1,"tip",0,"bonus",0)))).andExpect(status().is(status));}
 JobApplication application(User worker){var app=new JobApplication();app.setJob(job);app.setWorker(worker);app.setStatus(ApplicationStatus.ACCEPTED);return applications.saveAndFlush(app);}
 User user(String phone,Role role){var user=new User();user.setPhoneNumber(phone);user.setPassword("hash");user.setFullName("QA");user.setRole(role);return users.saveAndFlush(user);}
 User savedFirst(){return users.findById(first.getId()).orElseThrow();}
 String token(User user){return "Bearer "+jwt.generateToken(user.getPhoneNumber());}
}
