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
import java.util.List;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
class ApplicationApiTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired JwtUtil jwt;
    User owner, worker, secondWorker, outsider;
    Job job;

    @BeforeEach void setup() {
        clean();
        owner = user("0933333331", Role.ROLE_CONTRACTOR);
        worker = user("0933333332", Role.ROLE_WORKER);
        secondWorker = user("0933333333", Role.ROLE_WORKER);
        outsider = user("0933333334", Role.ROLE_CONTRACTOR);
        job = new Job(); job.setContractor(owner); job.setTitle("Công trình thử"); job.setAddress("TP.HCM");
        job.setJobType("Phụ hồ"); job.setSalaryPerDay(300000); job.setLatitude(10); job.setLongitude(106);
        job.setRequiredWorkers(1); job = jobs.saveAndFlush(job);
    }
    @AfterEach void clean() { applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch(); }

    @Test void applyDuplicatePrivacyAndAcceptWorkflow() throws Exception {
        long id = apply(worker);
        mvc.perform(post("/api/applications/apply").header("Authorization", token(worker))
            .contentType("application/json").content("{\"jobId\":" + job.getId() + "}"))
            .andExpect(status().isConflict());
        mvc.perform(get("/api/applications/job/" + job.getId()).header("Authorization", token(outsider)))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/applications/worker/" + worker.getId()).header("Authorization", token(secondWorker)))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/applications/job/" + job.getId()).header("Authorization", token(owner)))
            .andExpect(status().isOk()).andExpect(jsonPath("$[0].workerPhone").value(worker.getPhoneNumber()))
            .andExpect(jsonPath("$[0].password").doesNotExist());
        mvc.perform(put("/api/applications/" + id + "/status").header("Authorization", token(outsider))
            .contentType("application/json").content("{\"status\":\"ACCEPTED\"}")).andExpect(status().isForbidden());
        assertThat(decide(id, "ACCEPTED")).isEqualTo(200);
        assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.IN_PROGRESS);
        mvc.perform(get("/api/applications/worker/" + worker.getId()).header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$[0].status").value("ACCEPTED"));
        assertThat(decide(id, "REJECTED")).isEqualTo(409);
    }

    @Test void rejectsApplicationWithoutFillingJob() throws Exception {
        long id = apply(worker);
        assertThat(decide(id, "REJECTED")).isEqualTo(200);
        assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.OPEN);
        mvc.perform(put("/api/applications/" + id + "/status").header("Authorization", token(owner))
            .contentType("application/json").content("{\"status\":\"PENDING\"}")).andExpect(status().isBadRequest());
    }

    @Test void concurrentApprovalsCannotExceedCapacity() throws Exception {
        long first = apply(worker), second = apply(secondWorker);
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            Future<Integer> a = pool.submit(() -> { start.await(); return decide(first, "ACCEPTED"); });
            Future<Integer> b = pool.submit(() -> { start.await(); return decide(second, "ACCEPTED"); });
            start.countDown();
            assertThat(List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS)))
                .containsExactlyInAnyOrder(200, 409);
            assertThat(applications.countByJobIdAndStatus(job.getId(), ApplicationStatus.ACCEPTED)).isEqualTo(1);
            assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.IN_PROGRESS);
        } finally { pool.shutdownNow(); }
    }

    private long apply(User user) throws Exception {
        var result = mvc.perform(post("/api/applications/apply").header("Authorization", token(user))
            .contentType("application/json").content("{\"jobId\":" + job.getId() + "}"))
            .andExpect(status().isCreated()).andReturn();
        return json.readTree(result.getResponse().getContentAsString()).get("id").asLong();
    }
    private int decide(long id, String status) throws Exception {
        return mvc.perform(put("/api/applications/" + id + "/status").header("Authorization", token(owner))
            .contentType("application/json").content("{\"status\":\"" + status + "\"}"))
            .andReturn().getResponse().getStatus();
    }
    private String token(User user) { return "Bearer " + jwt.generateToken(user.getPhoneNumber()); }
    private User user(String phone, Role role) {
        User user = new User(); user.setPhoneNumber(phone); user.setPassword("hash");
        user.setFullName("Tài khoản thử"); user.setRole(role); return users.saveAndFlush(user);
    }
}
