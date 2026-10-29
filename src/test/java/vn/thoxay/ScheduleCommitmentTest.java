package vn.thoxay;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import java.time.*;
import java.util.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class ScheduleCommitmentTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired JwtUtil jwt;
    @Autowired Clock clock;
    @Autowired vn.thoxay.wallet.WalletAccountRepository accounts;
    User owner,worker,outsider;
    Job job;
    @BeforeEach void setup() {
        owner=user("0988888811",Role.ROLE_CONTRACTOR); worker=user("0988888812",Role.ROLE_WORKER);
        outsider=user("0988888813",Role.ROLE_WORKER);
        job=new Job(); job.setContractor(owner); job.setTitle("Công trình có lịch"); job.setAddress("Công trường QA");
        job.setJobType("Thợ chính"); job.setSalaryPerDay(300000); job.setRequiredWorkers(3);
        job.setStartsOn(LocalDate.now(clock).plusDays(3)); job.setEndsOn(job.getStartsOn().plusDays(2));
        jobs.saveAndFlush(job);
    }
    @Test void datesAndExplicitVersionedConsentAreValidated() throws Exception {
        mvc.perform(post("/api/applications/apply").header("Authorization",token(worker)).contentType("application/json")
            .content(json.writeValueAsString(Map.of("jobId",job.getId())))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/applications/apply").header("Authorization",token(worker)).contentType("application/json")
            .content(json.writeValueAsString(Map.of("jobId",job.getId(),"acceptedTerms",true,"termsVersion",2))))
            .andExpect(status().isConflict());
        var invalid=jobInput(); invalid.put("endsOn",job.getStartsOn().minusDays(1));
        mvc.perform(post("/api/jobs").header("Authorization",token(owner)).contentType("application/json")
            .content(json.writeValueAsString(invalid))).andExpect(status().isBadRequest());
        mvc.perform(get("/api/jobs/"+job.getId()).header("Authorization",token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.contractorPhone").isEmpty());
    }
    @Test void expiredScheduleCannotReceiveOrAcceptApplications() throws Exception {
        long id=apply(null);
        job.setStartsOn(LocalDate.now(clock).minusDays(2)); job.setEndsOn(LocalDate.now(clock).minusDays(1)); jobs.saveAndFlush(job);
        mvc.perform(accept(id,false,1)).andExpect(status().isConflict());
        mvc.perform(post("/api/applications/apply").header("Authorization",token(outsider)).contentType("application/json")
            .content(json.writeValueAsString(Map.of("jobId",job.getId(),"acceptedTerms",true,"termsVersion",1))))
            .andExpect(status().isConflict());
    }
    @Test void counterOfferIsFrozenAndDocumentCanOnlyBeReadByParticipants() throws Exception {
        long id=apply(450000L);
        mvc.perform(accept(id,true,1)).andExpect(status().isOk()).andExpect(jsonPath("$.agreedDailyRate").value(450000));
        var response=mvc.perform(get("/api/applications/"+id+"/commitment").header("Authorization",token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.state").value("FINAL"))
            .andExpect(jsonPath("$.selectedDailyRate").value(450000)).andReturn();
        var document=json.readTree(response.getResponse().getContentAsString());
        assertThat(document.get("hash").asText()).hasSize(64);
        assertThat(document.get("text").asText()).contains("15 điểm","450000 VND");
        mvc.perform(get("/api/applications/"+id+"/commitment").header("Authorization",token(outsider)))
            .andExpect(status().isNotFound());
        mvc.perform(accept(id,false,1)).andExpect(status().isConflict());
        assertThat(applications.findById(id).orElseThrow().getAgreedDailyRate()).isEqualTo(450000);
        mvc.perform(put("/api/jobs/"+job.getId()).header("Authorization",token(owner)).contentType("application/json")
            .content(json.writeValueAsString(jobInput()))).andExpect(status().isConflict());
    }
    @Test void keepingOriginalPriceDoesNotSilentlyAcceptCounterOffer() throws Exception {
        long id=apply(450000L);
        mvc.perform(accept(id,false,1)).andExpect(status().isOk()).andExpect(jsonPath("$.agreedDailyRate").value(300000));
        mvc.perform(accept(id,false,1)).andExpect(status().isOk());
    }
    @Test void settlementUsesAgreedRateAndIsIdempotent() throws Exception {
        long id=apply(450000L);
        mvc.perform(accept(id,true,1)).andExpect(status().isOk());
        var application=applications.findById(id).orElseThrow(); application.setWorkerRating(5);
        job.setStatus(JobStatus.COMPLETED); jobs.saveAndFlush(job); applications.saveAndFlush(application);
        var balance=new vn.thoxay.wallet.WalletAccount(); balance.setUser(owner); balance.setMainBalance(2000000); accounts.saveAndFlush(balance);
        var body=json.writeValueAsString(Map.of("applicationId",id,"workDays",2,"tip",10000,"bonus",20000));
        for(int i=0;i<2;i++) mvc.perform(post("/api/wallet/job-payments").header("Authorization",token(owner))
            .contentType("application/json").content(body)).andExpect(status().isOk())
            .andExpect(jsonPath("$.dailyRate").value(450000)).andExpect(jsonPath("$.total").value(930000));
        assertThat(accounts.findById(worker.getId()).orElseThrow().getMainBalance()).isEqualTo(930000);
        assertThat(accounts.findById(owner.getId()).orElseThrow().getMainBalance()).isEqualTo(1070000);
    }
    @Test void changedJobTermsMustBeViewedAndConfirmedAgain() throws Exception {
        long id=apply(null);
        mvc.perform(put("/api/jobs/"+job.getId()).header("Authorization",token(owner)).contentType("application/json")
            .content(json.writeValueAsString(jobInput()))).andExpect(status().isOk()).andExpect(jsonPath("$.termsVersion").value(2));
        mvc.perform(accept(id,false,2)).andExpect(status().isConflict());
        mvc.perform(get("/api/applications/"+id+"/commitment").header("Authorization",token(worker)))
            .andExpect(jsonPath("$.termsVersion").value(2));
        mvc.perform(put("/api/applications/"+id+"/commitment").header("Authorization",token(worker))
            .contentType("application/json").content("{\"accepted\":true,\"termsVersion\":2}"))
            .andExpect(status().isOk());
        mvc.perform(accept(id,false,2)).andExpect(status().isOk());
    }
    @Test void calendarBlocksArePrivateAndBlockAcceptanceInBothDirections() throws Exception {
        long id=apply(null);
        var response=mvc.perform(post("/api/users/me/calendar").header("Authorization",token(worker)).contentType("application/json")
            .content(json.writeValueAsString(Map.of("from",job.getStartsOn(),"to",job.getStartsOn(),"note","Bận việc riêng"))))
            .andExpect(status().isOk()).andReturn();
        long block=json.readTree(response.getResponse().getContentAsString()).get(0).get("referenceId").asLong();
        mvc.perform(accept(id,false,1)).andExpect(status().isConflict());
        mvc.perform(get("/api/users/me/calendar").param("from",job.getStartsOn().toString()).param("to",job.getEndsOn().toString())
            .header("Authorization",token(outsider))).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(delete("/api/users/me/calendar/"+block).header("Authorization",token(outsider))).andExpect(status().isNotFound());
        mvc.perform(delete("/api/users/me/calendar/"+block).header("Authorization",token(worker))).andExpect(status().isOk());
        mvc.perform(accept(id,false,1)).andExpect(status().isOk());
        mvc.perform(post("/api/users/me/calendar").header("Authorization",token(worker)).contentType("application/json")
            .content(json.writeValueAsString(Map.of("from",job.getStartsOn(),"to",job.getStartsOn()))))
            .andExpect(status().isConflict());
    }
    long apply(Long proposal) throws Exception {
        var input=new HashMap<String,Object>(); input.put("jobId",job.getId()); input.put("acceptedTerms",true); input.put("termsVersion",1);
        if(proposal!=null) input.put("proposedDailyRate",proposal);
        var result=mvc.perform(post("/api/applications/apply").header("Authorization",token(worker)).contentType("application/json")
            .content(json.writeValueAsString(input))).andExpect(status().isCreated()).andReturn();
        return json.readTree(result.getResponse().getContentAsString()).get("id").asLong();
    }
    org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder accept(long id,boolean offer,int version) throws Exception {
        return put("/api/applications/"+id+"/status").header("Authorization",token(owner)).contentType("application/json")
            .content(json.writeValueAsString(Map.of("status","ACCEPTED","acceptCounterOffer",offer,"acceptedTerms",true,"termsVersion",version)));
    }
    Map<String,Object> jobInput() {
        return new HashMap<>(Map.of("title",job.getTitle(),"description","Lịch mới","jobType",job.getJobType(),"salaryPerDay",300000,
            "address",job.getAddress(),"latitude",10.0,"longitude",106.0,"requiredWorkers",3,"startsOn",job.getStartsOn(),"endsOn",job.getEndsOn()));
    }
    User user(String phone,Role role) { var u=new User();u.setPhoneNumber(phone);u.setFullName("QA "+role);u.setPassword("hash");u.setRole(role);return users.saveAndFlush(u); }
    String token(User u) { return "Bearer "+jwt.generateToken(u.getPhoneNumber()); }
}
