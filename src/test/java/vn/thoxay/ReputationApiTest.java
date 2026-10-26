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
class ReputationApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired ReputationEventRepository events;
    @Autowired JwtUtil jwt;
    User worker, owner;
    @BeforeEach void setup() { clean(); worker = user("0964444401", Role.ROLE_WORKER); owner = user("0964444402", Role.ROLE_CONTRACTOR); }
    @AfterEach void clean() { applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch(); }
    @Test void tierBoundariesRequireRealExperienceAndDiamondKyc() {
        worker.setCompletedJobs(4); worker.setRating(5); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.SILVER);
        worker.setCompletedJobs(5); worker.setReputationScore(80); worker.setRating(4); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.GOLD);
        worker.setReputationScore(79); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.SILVER);
        worker.setCompletedJobs(20); worker.setReputationScore(95); worker.setRating(4.7); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.GOLD);
        worker.setCccdFrontImage("https://example.com/front"); worker.setCccdBackImage("https://example.com/back"); worker.setVerified(true);
        users.saveAndFlush(worker); assertThat(users.findById(worker.getId()).orElseThrow().getWorkerTier()).isEqualTo(WorkerTier.DIAMOND);
        worker.setVerified(false); users.saveAndFlush(worker); assertThat(users.findById(worker.getId()).orElseThrow().getWorkerTier()).isEqualTo(WorkerTier.GOLD);
    }
    @Test void completionAwardsOnceCapsScoreAndPublishesOnlyActualReviews() throws Exception {
        worker.setReputationScore(99); users.saveAndFlush(worker);
        Job job = new Job(); job.setContractor(owner); job.setTitle("Công trình đánh giá"); job.setJobType("Phụ hồ"); job.setSalaryPerDay(300000d);
        job.setAddress("TP.HCM"); job.setLatitude(10d); job.setLongitude(106d); job.setRequiredWorkers(1); job.setStatus(JobStatus.IN_PROGRESS); jobs.saveAndFlush(job);
        JobApplication a = new JobApplication(); a.setWorker(worker); a.setJob(job); a.setStatus(ApplicationStatus.ACCEPTED); applications.saveAndFlush(a);
        String body = "{\"ratings\":[{\"workerId\":" + worker.getId() + ",\"stars\":4}]}";
        for (int i=0;i<2;i++) mvc.perform(put("/api/jobs/"+job.getId()+"/complete").header("Authorization", token(owner)).contentType("application/json").content(body)).andExpect(status().isOk());
        User saved = users.findById(worker.getId()).orElseThrow(); assertThat(saved.getReputationScore()).isEqualTo(100); assertThat(saved.getCompletedJobs()).isEqualTo(1); assertThat(saved.getRating()).isEqualTo(4);
        assertThat(events.count()).isEqualTo(1); assertThat(events.findAll().get(0).getDelta()).isEqualTo(1);
        mvc.perform(get("/api/workers/"+worker.getId()+"/reviews").header("Authorization", token(owner))).andExpect(status().isOk())
            .andExpect(jsonPath("$.items[0].stars").value(4)).andExpect(jsonPath("$.items[0].reviewedAt").isNotEmpty()).andExpect(jsonPath("$.items[0].phoneNumber").doesNotExist());
        mvc.perform(get("/api/users/me/reputation").header("Authorization", token(worker))).andExpect(jsonPath("$.items[0].delta").value(1));
        mvc.perform(get("/api/users/me/reputation").header("Authorization", token(owner))).andExpect(jsonPath("$.items.length()").value(0));
        mvc.perform(get("/api/workers/leaderboard").header("Authorization", token(owner))).andExpect(jsonPath("$[0].workerId").value(worker.getId())).andExpect(jsonPath("$[0].phoneNumber").doesNotExist());
    }
    @Test void leaderboardExcludesUnratedLockedAndContractorAccountsAndOrdersDeterministically() throws Exception {
        User gold=user("0964444403", Role.ROLE_WORKER); gold.setCompletedJobs(5); gold.setRating(4); users.saveAndFlush(gold);
        User locked=user("0964444404",Role.ROLE_WORKER); locked.setCompletedJobs(10); locked.setActive(false); users.saveAndFlush(locked);
        owner.setCompletedJobs(99); users.saveAndFlush(owner);
        mvc.perform(get("/api/workers/leaderboard").header("Authorization",token(worker))).andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1)).andExpect(jsonPath("$[0].workerId").value(gold.getId())).andExpect(jsonPath("$[0].workerTier").value("GOLD"));
        mvc.perform(get("/api/workers/leaderboard?limit=101").header("Authorization",token(worker))).andExpect(status().isBadRequest());
        mvc.perform(get("/api/workers/leaderboard")).andExpect(status().isUnauthorized());
    }
    private String token(User u) { return "Bearer " + jwt.generateToken(u.getPhoneNumber()); }
    private User user(String phone, Role role) { User u=new User(); u.setPhoneNumber(phone); u.setFullName("Thợ thử nghiệm"); u.setPassword("hash"); u.setRole(role); return users.saveAndFlush(u); }
}
