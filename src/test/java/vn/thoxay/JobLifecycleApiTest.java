package vn.thoxay;

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
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
class JobLifecycleApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired JwtUtil jwt;
    User owner, worker, outsider, admin;

    @BeforeEach void setup() {
        clean();
        owner = user("0955555551", Role.ROLE_CONTRACTOR);
        worker = user("0955555552", Role.ROLE_WORKER);
        outsider = user("0955555553", Role.ROLE_CONTRACTOR);
        admin = user("0955555554", Role.ROLE_ADMIN);
    }
    @AfterEach void clean() { applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch(); }

    @Test void ownCccdUpdateRequiresHttpsAndInvalidatesVerification() throws Exception {
        worker.setVerified(true); users.saveAndFlush(worker);
        mvc.perform(put("/api/users/me/cccd").header("Authorization", token(worker))
            .contentType("application/json").content("{\"cccdImage\":\"https://example.com/new-id.jpg\"}"))
            .andExpect(status().isOk()).andExpect(jsonPath("verified").value(false))
            .andExpect(jsonPath("cccdImage").value("https://example.com/new-id.jpg"));
        mvc.perform(get("/api/users/me").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("password").doesNotExist());
        assertThat(users.findById(owner.getId()).orElseThrow().getCccdImage()).isNull();
        mvc.perform(put("/api/users/me/cccd").header("Authorization", token(worker))
            .contentType("application/json").content("{\"cccdImage\":\"http://example.com/id.jpg\"}"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/admin/users/" + worker.getId() + "/verify").with(csrf())
            .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN"))
            .param("cccdImage", "https://example.com/old-id.jpg"))
            .andExpect(flash().attributeExists("error"));
        assertThat(users.findById(worker.getId()).orElseThrow().isVerified()).isFalse();
    }

    @Test void completesAndAveragesActualScoresWithIdempotentRetry() throws Exception {
        Job first = acceptedJob(owner, "Công trình một");
        User waitingWorker = user("0955555555", Role.ROLE_WORKER);
        JobApplication waiting = new JobApplication(); waiting.setJob(first); waiting.setWorker(waitingWorker);
        applications.saveAndFlush(waiting);
        mvc.perform(put("/api/jobs/" + first.getId() + "/complete").header("Authorization", token(owner))
            .contentType("application/json").content(scores(5)))
            .andExpect(status().isOk()).andExpect(jsonPath("status").value("COMPLETED"));
        assertThat(applications.findById(waiting.getId()).orElseThrow().getStatus()).isEqualTo(ApplicationStatus.REJECTED);
        assertThat(complete(first, 5, owner)).isEqualTo(200);
        Job second = acceptedJob(owner, "Công trình hai");
        assertThat(complete(second, 3, owner)).isEqualTo(200);
        assertThat(users.findById(worker.getId()).orElseThrow().getRating()).isEqualTo(4.0);
        assertThat(complete(first, 1, owner)).isEqualTo(409);
        mvc.perform(get("/api/applications/worker/" + worker.getId()).header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$[0].jobRating").value(3));
    }

    @Test void rejectsInvalidRatingsWrongOwnerAndNonParticipantWithoutPartialCompletion() throws Exception {
        Job job = acceptedJob(owner, "Chưa hoàn thành");
        assertThat(complete(job, 5, outsider)).isEqualTo(403);
        assertThat(complete(job, 0, owner)).isEqualTo(400);
        assertThat(complete(job, 6, owner)).isEqualTo(400);
        mvc.perform(put("/api/jobs/" + job.getId() + "/complete").header("Authorization", token(owner))
            .contentType("application/json").content("{\"ratings\":[{\"workerId\":" + outsider.getId() + ",\"stars\":5}]}"))
            .andExpect(status().isBadRequest());
        mvc.perform(put("/api/jobs/" + job.getId() + "/complete").header("Authorization", token(owner))
            .contentType("application/json").content("{\"ratings\":[{\"workerId\":" + worker.getId() + ",\"stars\":5},{\"workerId\":" + worker.getId() + ",\"stars\":4}]}"))
            .andExpect(status().isBadRequest());
        assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.IN_PROGRESS);
        assertThat(applications.findByJobIdOrderByAppliedAtDesc(job.getId()).get(0).getWorkerRating()).isNull();
        job.setStatus(JobStatus.OPEN); jobs.saveAndFlush(job);
        assertThat(complete(job, 5, owner)).isEqualTo(409);
    }

    @Test void concurrentDifferentJobsForSameWorkerKeepCorrectAverage() throws Exception {
        Job first = acceptedJob(owner, "Đồng thời A"), second = acceptedJob(outsider, "Đồng thời B");
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            Future<Integer> a = pool.submit(() -> { start.await(); return complete(first, 5, owner); });
            Future<Integer> b = pool.submit(() -> { start.await(); return complete(second, 1, outsider); });
            start.countDown();
            assertThat(List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS))).containsOnly(200);
            assertThat(users.findById(worker.getId()).orElseThrow().getRating()).isEqualTo(3.0);
        } finally { pool.shutdownNow(); }
    }

    @Test void deletingRatedJobRecalculatesAverageFromRemainingJobs() throws Exception {
        Job first = acceptedJob(owner, "Sẽ xóa"), second = acceptedJob(owner, "Còn lại");
        assertThat(complete(first, 5, owner)).isEqualTo(200);
        assertThat(complete(second, 1, owner)).isEqualTo(200);
        mvc.perform(post("/admin/jobs/" + first.getId() + "/delete").with(csrf())
            .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN")))
            .andExpect(status().is3xxRedirection());
        assertThat(users.findById(worker.getId()).orElseThrow().getRating()).isEqualTo(1.0);
    }

    @Test void filtersTypeAndSortsSalaryWhileHidingContactUntilAcceptance() throws Exception {
        Job low = openJob("Lương thấp", "Phụ hồ", 300000), high = openJob("Lương cao", "Phụ hồ", 700000);
        openJob("Thợ chính", "Thợ chính", 900000);
        mvc.perform(get("/api/jobs/nearby").param("lat", "10").param("lng", "106")
            .param("jobType", "Phụ hồ").param("sort", "SALARY_DESC").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(2))
            .andExpect(jsonPath("$[0].id").value(high.getId())).andExpect(jsonPath("$[1].id").value(low.getId()))
            .andExpect(jsonPath("$[0].contractorPhone").doesNotExist());
        mvc.perform(get("/api/jobs/nearby?lat=10&lng=106&sort=INVALID").header("Authorization", token(worker)))
            .andExpect(status().isBadRequest());
    }

    private String scores(int stars) { return "{\"ratings\":[{\"workerId\":" + worker.getId() + ",\"stars\":" + stars + "}]}"; }
    private int complete(Job job, int stars, User contractor) throws Exception {
        return mvc.perform(put("/api/jobs/" + job.getId() + "/complete").header("Authorization", token(contractor))
            .contentType("application/json").content(scores(stars))).andReturn().getResponse().getStatus();
    }
    private Job acceptedJob(User contractor, String title) {
        Job job = openJob(title, "Thợ chính", 500000); job.setContractor(contractor);
        job.setStatus(JobStatus.IN_PROGRESS); jobs.saveAndFlush(job);
        JobApplication application = new JobApplication(); application.setJob(job); application.setWorker(worker);
        application.setStatus(ApplicationStatus.ACCEPTED); applications.saveAndFlush(application); return job;
    }
    private Job openJob(String title, String type, double salary) {
        Job job = new Job(); job.setContractor(owner); job.setTitle(title); job.setJobType(type);
        job.setAddress("TP.HCM"); job.setSalaryPerDay(salary); job.setLatitude(10); job.setLongitude(106);
        job.setRequiredWorkers(1); return jobs.saveAndFlush(job);
    }
    private String token(User user) { return "Bearer " + jwt.generateToken(user.getPhoneNumber()); }
    private User user(String phone, Role role) {
        User user = new User(); user.setPhoneNumber(phone); user.setPassword("hash");
        user.setFullName("Tài khoản kiểm thử"); user.setRole(role); return users.saveAndFlush(user);
    }
}
