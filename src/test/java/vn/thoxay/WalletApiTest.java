package vn.thoxay;

import com.fasterxml.jackson.databind.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.*;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.wallet.*;
import vn.thoxay.security.JwtUtil;
import java.time.*;
import java.sql.Timestamp;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

@SpringBootTest @AutoConfigureMockMvc
class WalletApiTest {
    @Autowired MockMvc mvc;@Autowired ObjectMapper json;@Autowired UserRepository users;@Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;@Autowired MessageRepository messages;@Autowired JwtUtil jwt;
    @Autowired WalletAccountRepository accounts;@Autowired WalletRequestRepository requests;@Autowired WalletEntryRepository entries;
    @Autowired JobPaymentRepository payments;@Autowired JdbcTemplate jdbc;
    User owner,worker,other,admin;Job job;JobApplication application;
    @BeforeEach void setup(){clean();owner=user("0967777701",Role.ROLE_CONTRACTOR);worker=user("0967777702",Role.ROLE_WORKER);other=user("0967777703",Role.ROLE_WORKER);admin=user("0967777704",Role.ROLE_ADMIN);
        job=new Job();job.setContractor(owner);job.setTitle("Công trình trả công");job.setJobType("Phụ hồ");job.setSalaryPerDay(300000d);job.setAddress("HCM");job.setLatitude(10d);job.setLongitude(106d);job.setRequiredWorkers(1);job.setStatus(JobStatus.COMPLETED);jobs.saveAndFlush(job);
        application=new JobApplication();application.setJob(job);application.setWorker(worker);application.setStatus(ApplicationStatus.ACCEPTED);application.setWorkerRating(5);applications.saveAndFlush(application);}
    @AfterEach void clean(){messages.deleteAllInBatch();applications.deleteAllInBatch();jobs.deleteAllInBatch();users.deleteAllInBatch();}
    @Test void topupWaitsForAdminAndConcurrentApprovalCreditsExactlyOnce()throws Exception{
        long id=create(owner,1000000,"deposit-one").path("id").asLong();
        assertThat(create(owner,1000000,"deposit-one").path("id").asLong()).isEqualTo(id);
        assertThat(balance(owner).path("mainBalance").asLong()).isZero();
        postJson("/api/admin/wallet/requests/"+id+"/review",owner,review("APPROVE","BANK-001",true)).andExpect(status().isForbidden());
        postJson("/api/admin/wallet/requests/"+id+"/review",admin,review("APPROVE","BANK-001",false)).andExpect(status().isBadRequest());
        race(()->approve(id,"BANK-001"),()->approve(id,"BANK-001"),List.of(200,200));
        assertThat(balance(owner).path("mainBalance").asLong()).isEqualTo(1000000);assertThat(entries.count()).isEqualTo(1);
        long duplicate=create(worker,1000000,"deposit-two").path("id").asLong();
        assertThat(approve(duplicate,"bank-001")).isEqualTo(409);assertThat(balance(worker).path("mainBalance").asLong()).isZero();
        postJson("/api/admin/wallet/requests/"+id+"/review",admin,review("REJECT",null,false)).andExpect(status().isConflict());
    }
    @Test void pendingWithdrawalsReserveMoneyAndCannotOverdrawConcurrently()throws Exception{
        fund(worker,1000000,"withdraw-seed");
        race(()->withdraw(worker,800000,"withdraw-a").andReturn().getResponse().getStatus(),()->withdraw(worker,800000,"withdraw-b").andReturn().getResponse().getStatus(),List.of(200,409));
        var b=balance(worker);assertThat(b.path("mainBalance").asLong()).isEqualTo(200000);assertThat(b.path("heldBalance").asLong()).isEqualTo(800000);
        var r=requests.findAll().stream().filter(x->x.getKind()==WalletRequest.Kind.WITHDRAW).findFirst().orElseThrow();
        assertThat(approve(r.getId(),"PAID-OUT-01")).isEqualTo(200);assertThat(approve(r.getId(),"PAID-OUT-01")).isEqualTo(200);
        assertThat(balance(worker).path("heldBalance").asLong()).isZero();assertThat(balance(worker).path("mainBalance").asLong()).isEqualTo(200000);
        assertThat(entries.count()).isEqualTo(3);
    }
    @Test void rejectionReleasesHoldExactlyOnceAndIdempotencyCannotChangeAmounts()throws Exception{
        fund(worker,1000000,"release-seed");var result=withdraw(worker,500000,"withdraw-retry").andExpect(status().isOk()).andReturn();long id=read(result).path("id").asLong();
        withdraw(worker,500000,"withdraw-retry").andExpect(jsonPath("$.id").value(id));withdraw(worker,600000,"withdraw-retry").andExpect(status().isConflict());
        for(int i=0;i<2;i++)postJson("/api/admin/wallet/requests/"+id+"/review",admin,review("REJECT",null,false)).andExpect(status().isOk());
        assertThat(balance(worker).path("mainBalance").asLong()).isEqualTo(1000000);assertThat(balance(worker).path("heldBalance").asLong()).isZero();assertThat(entries.count()).isEqualTo(3);
    }
    @Test void escrowTransfersAreAtomicIdempotentAndNotIncome()throws Exception{
        fund(worker,1000000,"escrow-seed");
        var body=Map.of("direction","LOCK","amount",200000,"clientRequestId","escrow-lock-one");
        for(int i=0;i<2;i++)postJson("/api/wallet/escrow",worker,body).andExpect(status().isOk());
        var b=balance(worker);assertThat(b.path("mainBalance").asLong()).isEqualTo(800000);assertThat(b.path("escrowBalance").asLong()).isEqualTo(200000);assertThat(b.path("lowEscrow").asBoolean()).isFalse();
        postJson("/api/wallet/escrow",worker,Map.of("direction","RELEASE","amount",50000,"clientRequestId","escrow-release-one")).andExpect(status().isOk());
        assertThat(balance(worker).path("lowEscrow").asBoolean()).isTrue();
        postJson("/api/wallet/escrow",worker,Map.of("direction","RELEASE","amount",300000,"clientRequestId","escrow-too-much")).andExpect(status().isConflict());
        mvc.perform(get("/api/wallet/earnings").header("Authorization",token(worker))).andExpect(jsonPath("$.total").value(0));
    }
    @Test void completedWorkTransfersRealFundsAndRetriesNeverPayTwice()throws Exception{
        postJson("/api/wallet/job-payments",owner,payBody()).andExpect(status().isConflict());assertThat(payments.count()).isZero();
        fund(owner,1000000,"job-seed");
        postJson("/api/wallet/job-payments",other,payBody()).andExpect(status().isForbidden());
        race(()->postJson("/api/wallet/job-payments",owner,payBody()).andReturn().getResponse().getStatus(),()->postJson("/api/wallet/job-payments",owner,payBody()).andReturn().getResponse().getStatus(),List.of(200,200));
        assertThat(balance(owner).path("mainBalance").asLong()).isEqualTo(330000);assertThat(balance(worker).path("mainBalance").asLong()).isEqualTo(670000);assertThat(payments.count()).isEqualTo(1);
        var changed=new HashMap<>(payBody());changed.put("workDays",3);postJson("/api/wallet/job-payments",owner,changed).andExpect(status().isConflict());
        mvc.perform(get("/api/wallet/earnings?period=DAY").header("Authorization",token(worker))).andExpect(jsonPath("$.base").value(600000)).andExpect(jsonPath("$.tip").value(50000)).andExpect(jsonPath("$.bonus").value(20000)).andExpect(jsonPath("$.total").value(670000)).andExpect(jsonPath("$.settledJobs").value(1));
        mvc.perform(get("/api/wallet/jobs/"+job.getId()+"/payments").header("Authorization",token(other))).andExpect(status().isForbidden());
    }
    @Test void statisticsUseVietnamDayBoundariesAndExclusiveEnd()throws Exception{
        fund(owner,1000000,"time-seed");postJson("/api/wallet/job-payments",owner,payBody()).andExpect(status().isOk());
        LocalDate start=LocalDate.of(2026,1,5);Instant midnight=start.atStartOfDay(ZoneId.of("Asia/Ho_Chi_Minh")).toInstant();
        jdbc.update("update wallet_entries set created_at=? where user_id=?",Timestamp.from(midnight),worker.getId());
        jdbc.update("update wallet_entries set created_at=? where user_id=? and kind='BONUS'",Timestamp.from(midnight.plusSeconds(86400)),worker.getId());
        mvc.perform(get("/api/wallet/earnings?period=DAY&date=2026-01-05").header("Authorization",token(worker)))
            .andExpect(jsonPath("$.total").value(650000)).andExpect(jsonPath("$.days.length()").value(1))
            .andExpect(jsonPath("$.days[0].date").value("2026-01-05")).andExpect(jsonPath("$.days[0].base").value(600000))
            .andExpect(jsonPath("$.days[0].tip").value(50000)).andExpect(jsonPath("$.days[0].bonus").value(0));
        mvc.perform(get("/api/wallet/earnings?period=WEEK&date=2026-01-07").header("Authorization",token(worker)))
            .andExpect(jsonPath("$.from").value("2026-01-05")).andExpect(jsonPath("$.total").value(670000))
            .andExpect(jsonPath("$.days.length()").value(7)).andExpect(jsonPath("$.days[0].total").value(650000))
            .andExpect(jsonPath("$.days[1].total").value(20000)).andExpect(jsonPath("$.days[2].total").value(0));
        mvc.perform(get("/api/wallet/earnings?period=MONTH&date=2026-01-15").header("Authorization",token(worker))).andExpect(jsonPath("$.total").value(670000));
        mvc.perform(get("/api/wallet/earnings?period=DAY&date=2026-01-04").header("Authorization",token(worker))).andExpect(jsonPath("$.total").value(0));
    }
    @Test void emptyTimelineIncludesLeapMonthAndCrossYearWeekWithoutInventingIncome() throws Exception {
        mvc.perform(get("/api/wallet/earnings?period=MONTH&date=2024-02-15").header("Authorization",token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.days.length()").value(29))
            .andExpect(jsonPath("$.days[28].date").value("2024-02-29")).andExpect(jsonPath("$.total").value(0));
        mvc.perform(get("/api/wallet/earnings?period=WEEK&date=2026-01-01").header("Authorization",token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.days[0].date").value("2025-12-29"))
            .andExpect(jsonPath("$.days[6].date").value("2026-01-04")).andExpect(jsonPath("$.days.length()").value(7));
        mvc.perform(get("/api/wallet/earnings?period=DAY").header("Authorization",token(owner))).andExpect(status().isForbidden());
    }
    @Test void validationOwnershipAndPaginationPreventForgedCreditOrSensitiveLeak()throws Exception{
        mvc.perform(get("/api/wallet")).andExpect(status().isUnauthorized());
        for(Object amount:List.of(0,-1000,100000001,1500.5))postJson("/api/wallet/requests",worker,Map.of("kind","TOP_UP","amount",amount,"clientRequestId","invalid-money","transferReference","ref")).andExpect(status().isBadRequest());
        fund(owner,1000000,"privacy-seed");
        mvc.perform(get("/api/wallet/transactions?limit=1").header("Authorization",token(other))).andExpect(jsonPath("$.items.length()").value(0));
        mvc.perform(get("/api/wallet/requests").header("Authorization",token(other))).andExpect(jsonPath("$.items.length()").value(0));
        mvc.perform(get("/api/admin/wallet/requests").header("Authorization",token(worker))).andExpect(status().isForbidden());
        mvc.perform(get("/api/wallet/transactions?limit=101").header("Authorization",token(owner))).andExpect(status().isBadRequest());
        mvc.perform(get("/api/wallet/earnings?period=YEAR").header("Authorization",token(worker))).andExpect(status().isBadRequest());
    }
    @Test void unfinishedOrCancelledWorkCannotBePaidEvenWhenPayerHasFunds()throws Exception{
        fund(owner,1000000,"ineligible-seed");
        job.setStatus(JobStatus.IN_PROGRESS);jobs.saveAndFlush(job);
        postJson("/api/wallet/job-payments",owner,payBody()).andExpect(status().isConflict());
        job.setStatus(JobStatus.COMPLETED);jobs.saveAndFlush(job);application.setWorkerRating(null);application.setStatus(ApplicationStatus.CANCELLED);applications.saveAndFlush(application);
        postJson("/api/wallet/job-payments",owner,payBody()).andExpect(status().isConflict());
        assertThat(payments.count()).isZero();assertThat(balance(owner).path("mainBalance").asLong()).isEqualTo(1000000);
    }
    @Test void deletedJobPreservesLedgerAndPaidIncome()throws Exception{
        fund(owner,1000000,"delete-seed");postJson("/api/wallet/job-payments",owner,payBody()).andExpect(status().isOk());
        mvc.perform(post("/admin/jobs/"+job.getId()+"/delete").with(csrf()).with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().is3xxRedirection());
        assertThat(balance(worker).path("mainBalance").asLong()).isEqualTo(670000);assertThat(payments.findAll().get(0).getApplication()).isNull();assertThat(payments.findAll().get(0).getJobTitle()).isEqualTo("Công trình trả công");
        mvc.perform(get("/api/wallet/earnings").header("Authorization",token(worker))).andExpect(jsonPath("$.total").value(670000));
    }
    @Test void adminPageEscapesBankEvidenceAndRequiresCsrf()throws Exception{
        long id=read(postJson("/api/wallet/requests",worker,Map.of("kind","TOP_UP","amount",1000,"clientRequestId","html-escape-test","transferReference","<script>bad()</script>")).andExpect(status().isOk()).andReturn()).path("id").asLong();
        mvc.perform(get("/admin/wallet").with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk()).andExpect(content().string(org.hamcrest.Matchers.containsString("&lt;script&gt;")));
        mvc.perform(post("/admin/wallet/requests/"+id+"/review").with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN")).param("decision","REJECT")).andExpect(status().isForbidden());
        mvc.perform(post("/admin/wallet/requests/"+id+"/review").with(csrf()).with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN"))
            .param("decision","APPROVE").param("externalReference","FORM-REF-001").param("confirmed","true").param("note","Test form approval"))
            .andExpect(status().is3xxRedirection()).andExpect(flash().attributeExists("success"));
        assertThat(balance(worker).path("mainBalance").asLong()).isEqualTo(1000);
    }
    private Map<String,Object> payBody(){return Map.of("applicationId",application.getId(),"workDays",2,"tip",50000,"bonus",20000);}
    private Map<String,Object> review(String decision,String reference,boolean confirmed){var body=new HashMap<String,Object>();body.put("decision",decision);body.put("externalReference",reference);body.put("confirmed",confirmed);body.put("note","Test-only reconciliation");return body;}
    private JsonNode balance(User actor)throws Exception{return read(mvc.perform(get("/api/wallet").header("Authorization",token(actor))).andExpect(status().isOk()).andReturn());}
    private JsonNode create(User actor,long amount,String key)throws Exception{return read(postJson("/api/wallet/requests",actor,Map.of("kind","TOP_UP","amount",amount,"clientRequestId",key,"transferReference","synthetic-test-only")).andExpect(status().isOk()).andReturn());}
    private void fund(User actor,long amount,String key)throws Exception{long id=create(actor,amount,key).path("id").asLong();assertThat(approve(id,"REF-"+id)).isEqualTo(200);}
    private int approve(long id,String reference)throws Exception{return postJson("/api/admin/wallet/requests/"+id+"/review",admin,review("APPROVE",reference,true)).andReturn().getResponse().getStatus();}
    private ResultActions withdraw(User actor,long amount,String key)throws Exception{return postJson("/api/wallet/requests",actor,Map.of("kind","WITHDRAW","amount",amount,"clientRequestId",key,"bankName","Test bank","bankAccount","1234567890","accountName","Synthetic Tester"));}
    private ResultActions postJson(String path,User actor,Object body)throws Exception{return mvc.perform(post(path).header("Authorization",token(actor)).contentType("application/json").content(json.writeValueAsString(body)));}
    private JsonNode read(MvcResult result)throws Exception{return json.readTree(result.getResponse().getContentAsString());}
    private String token(User u){return "Bearer "+jwt.generateToken(u.getPhoneNumber());}
    private User user(String phone,Role role){User u=new User();u.setPhoneNumber(phone);u.setPassword("hash");u.setFullName("Wallet Tester");u.setRole(role);return users.saveAndFlush(u);}
    private void race(Callable<Integer>a,Callable<Integer>b,List<Integer>expected)throws Exception{var pool=Executors.newFixedThreadPool(2);var start=new CountDownLatch(1);try{var f=pool.submit(()->{start.await();return a.call();});var g=pool.submit(()->{start.await();return b.call();});start.countDown();assertThat(List.of(f.get(20,TimeUnit.SECONDS),g.get(20,TimeUnit.SECONDS))).containsExactlyInAnyOrderElementsOf(expected);}finally{pool.shutdownNow();}}
}
