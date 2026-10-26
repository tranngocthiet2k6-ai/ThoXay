package vn.thoxay;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
class WorkerAvailabilityApiTest {
    @Autowired MockMvc mvc; @Autowired UserRepository users; @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications; @Autowired JwtUtil jwt;
    User worker, owner; Job job;
    @BeforeEach void setup() { clean(); worker=user("0966666601",Role.ROLE_WORKER); owner=user("0966666602",Role.ROLE_CONTRACTOR);
        job=new Job(); job.setContractor(owner); job.setTitle("Việc quanh đây"); job.setJobType("Phụ hồ"); job.setAddress("HCM");
        job.setLatitude(10d); job.setLongitude(106d); job.setSalaryPerDay(300000d); job.setRequiredWorkers(1); jobs.saveAndFlush(job); }
    @AfterEach void clean() { applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch(); }
    @Test void offlinePreventsNewApplicationsButPreservesExistingWork() throws Exception {
        JobApplication a=new JobApplication(); a.setJob(job); a.setWorker(worker); applications.saveAndFlush(a);
        set(false).andExpect(status().isOk()).andExpect(jsonPath("$.available").value(false));
        mvc.perform(get("/api/jobs/nearby?lat=10&lng=106").header("Authorization",token(worker))).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(put("/api/applications/"+a.getId()+"/status").header("Authorization",token(owner)).contentType("application/json").content("{\"status\":\"ACCEPTED\"}")).andExpect(status().isConflict());
        set(true).andExpect(status().isOk());
        mvc.perform(put("/api/applications/"+a.getId()+"/status").header("Authorization",token(owner)).contentType("application/json").content("{\"status\":\"ACCEPTED\"}")).andExpect(status().isOk());
        set(false).andExpect(status().isOk());
        mvc.perform(get("/api/applications/worker/"+worker.getId()).header("Authorization",token(worker))).andExpect(jsonPath("$[0].status").value("ACCEPTED"));
        mvc.perform(get("/api/jobs/"+job.getId()+"/messages?peerId="+owner.getId()).header("Authorization",token(worker))).andExpect(status().isOk());
    }
    @Test void ownRoleValidationAndOfflineApplyAreEnforcedOnServer() throws Exception {
        set(false).andExpect(status().isOk());
        mvc.perform(post("/api/applications/apply").header("Authorization",token(worker)).contentType("application/json").content("{\"jobId\":"+job.getId()+"}")).andExpect(status().isConflict());
        assertThat(applications.count()).isZero();
        mvc.perform(get("/api/users/me/availability").header("Authorization",token(worker))).andExpect(jsonPath("$.available").value(false));
        mvc.perform(put("/api/users/me/availability").header("Authorization",token(owner)).contentType("application/json").content("{\"available\":true}")).andExpect(status().isForbidden());
        mvc.perform(put("/api/users/me/availability").header("Authorization",token(worker)).contentType("application/json").content("{}")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/users/me/availability")).andExpect(status().isUnauthorized());
    }
    private org.springframework.test.web.servlet.ResultActions set(boolean value) throws Exception { return mvc.perform(put("/api/users/me/availability").header("Authorization",token(worker)).contentType("application/json").content("{\"available\":"+value+"}")); }
    private String token(User u) {return "Bearer "+jwt.generateToken(u.getPhoneNumber());}
    private User user(String phone,Role role){ User u=new User();u.setPhoneNumber(phone);u.setPassword("hash");u.setFullName("Test");u.setRole(role);return users.saveAndFlush(u); }
}
