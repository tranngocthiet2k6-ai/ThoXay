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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class ContractorTeamTest {
    @Autowired MockMvc mvc; @Autowired ObjectMapper json; @Autowired UserRepository users;
    @Autowired JobRepository jobs; @Autowired JobApplicationRepository applications; @Autowired JwtUtil jwt;
    @Autowired vn.thoxay.favorites.ContractorGroupMemberRepository members;
    @Autowired vn.thoxay.favorites.SavedWorkerRepository saved;
    User owner, other, worker; String auth;
    @BeforeEach void setup() {
        owner = user("0900900001", Role.ROLE_CONTRACTOR); other = user("0900900002", Role.ROLE_CONTRACTOR);
        worker = user("0900900003", Role.ROLE_WORKER); auth = token(owner);
    }
    @Test void groupsAreOwnerScopedAndMembershipNeedsSavedWorker() throws Exception {
        long group = group();
        mvc.perform(put("/api/users/me/team/groups/{id}/members/{worker}",group,worker.getId()).header("Authorization",auth)).andExpect(status().isConflict());
        save();
        for (int i=0;i<2;i++) mvc.perform(put("/api/users/me/team/groups/{id}/members/{worker}",group,worker.getId()).header("Authorization",auth)).andExpect(status().isOk());
        assertThat(members.countByGroupId(group)).isEqualTo(1);
        mvc.perform(get("/api/users/me/team/groups").header("Authorization",auth)).andExpect(jsonPath("$[0].members[0].id").value(worker.getId()));
        mvc.perform(delete("/api/users/me/team/groups/{id}",group).header("Authorization",token(other))).andExpect(status().isNotFound());
        mvc.perform(get("/api/users/me/team/groups").header("Authorization",token(worker))).andExpect(status().isForbidden());
        mvc.perform(post("/api/users/me/team/groups").header("Authorization",auth).contentType("application/json").content("{\"name\":\"  Đội xây tô  \"}")).andExpect(status().isConflict());
        mvc.perform(delete("/api/users/me/saved/workers/{id}",worker.getId()).header("Authorization",auth)).andExpect(status().isOk());
        saved.flush();
        assertThat(members.countByGroupId(group)).isZero();
    }
    @Test void contactsOnlyExposePhoneAfterAcceptanceAndForJobOwner() throws Exception {
        var job = job(); var application = new JobApplication(); application.setJob(job); application.setWorker(worker); applications.saveAndFlush(application);
        mvc.perform(get("/api/users/me/team/contacts").header("Authorization",auth)).andExpect(content().json("[]"));
        application.setStatus(ApplicationStatus.ACCEPTED); applications.saveAndFlush(application);
        mvc.perform(get("/api/users/me/team/contacts").header("Authorization",auth)).andExpect(jsonPath("$[0].phoneNumber").value(worker.getPhoneNumber()));
        mvc.perform(get("/api/users/me/team/contacts").header("Authorization",token(other))).andExpect(content().json("[]"));
    }
    @Test void invitationsNotifyWithoutCreatingApplicationsOrBypassingConsent() throws Exception {
        var job = job(); save();
        String body = "{\"jobId\":"+job.getId()+",\"workerIds\":["+worker.getId()+"]}";
        for(int i=0;i<2;i++) mvc.perform(post("/api/users/me/team/invitations").header("Authorization",auth).contentType("application/json").content(body)).andExpect(status().isOk());
        assertThat(applications.existsByJobIdAndWorkerId(job.getId(),worker.getId())).isFalse();
        mvc.perform(get("/api/notifications").header("Authorization",token(worker))).andExpect(jsonPath("$.items.length()").value(1)).andExpect(jsonPath("$.items[0].jobId").value(job.getId()));
        mvc.perform(post("/api/users/me/team/invitations").header("Authorization",token(other)).contentType("application/json").content(body)).andExpect(status().isForbidden());
        job.setStatus(JobStatus.COMPLETED); jobs.saveAndFlush(job);
        mvc.perform(post("/api/users/me/team/invitations").header("Authorization",auth).contentType("application/json").content(body)).andExpect(status().isConflict());
    }
    long group() throws Exception {
        var result=mvc.perform(post("/api/users/me/team/groups").header("Authorization",auth).contentType("application/json").content("{\"name\":\"Đội xây tô\"}")).andExpect(status().isOk()).andReturn();
        return json.readTree(result.getResponse().getContentAsString()).get("id").asLong();
    }
    void save() throws Exception { mvc.perform(put("/api/users/me/saved/workers/{id}",worker.getId()).header("Authorization",auth)).andExpect(status().isOk()); }
    Job job() { var j=new Job();j.setContractor(owner);j.setTitle("Nhà phố");j.setAddress("Huế");j.setJobType("Thợ chính");j.setSalaryPerDay(450000);j.setRequiredWorkers(2);return jobs.saveAndFlush(j); }
    User user(String phone,Role role) { var u=new User();u.setPhoneNumber(phone);u.setPassword("hash");u.setFullName("QA");u.setRole(role);return users.saveAndFlush(u); }
    String token(User u) { return "Bearer "+jwt.generateToken(u.getPhoneNumber()); }
}
