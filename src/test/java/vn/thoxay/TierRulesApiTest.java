package vn.thoxay;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class TierRulesApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired JwtUtil jwt;
    User user(String phone, Role role, int completed) {
        var u = new User(); u.setPhoneNumber(phone); u.setFullName("Tier QA"); u.setPassword("hash"); u.setRole(role); u.setCompletedJobs(completed); return users.saveAndFlush(u);
    }
    @Test void bronzeSilverGoldDiamondRespectEveryBoundaryAndKyc() {
        var worker = new User(); worker.setRole(Role.ROLE_WORKER);
        assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.BRONZE);
        worker.setCompletedJobs(1); worker.setReputationScore(60); worker.setRating(2.99); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.BRONZE);
        worker.setRating(3); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.SILVER);
        worker.setCompletedJobs(5); worker.setRating(4); worker.setReputationScore(79); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.SILVER);
        worker.setReputationScore(80); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.GOLD);
        worker.setCompletedJobs(20); worker.setRating(4.7); worker.setReputationScore(95); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.GOLD);
        worker.setVerified(true); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.DIAMOND);
        worker.setReputationScore(59); assertThat(WorkerTier.of(worker)).isEqualTo(WorkerTier.BRONZE);
    }
    @Test void catalogPublishesActualThresholdsAndDoesNotPromiseFeeDiscounts() throws Exception {
        var worker = user("0977100011", Role.ROLE_WORKER, 0);
        mvc.perform(get("/api/reputation/tiers").header("Authorization", "Bearer " + jwt.generateToken(worker.getPhoneNumber())))
            .andExpect(status().isOk()).andExpect(jsonPath("$.tiers.length()").value(4))
            .andExpect(jsonPath("$.tiers[0].code").value("BRONZE"))
            .andExpect(jsonPath("$.tiers[1].minCompletedJobs").value(1))
            .andExpect(jsonPath("$.tiers[2].minCompletedJobs").value(5))
            .andExpect(jsonPath("$.tiers[3].requiresKyc").value(true))
            .andExpect(jsonPath("$.feePolicy").value(org.hamcrest.Matchers.containsString("chưa áp dụng")));
        mvc.perform(get("/api/reputation/tiers")).andExpect(status().isUnauthorized());
    }
    @Test void higherTierActuallyAppearsFirstInApplicantsEvenWhenItAppliedEarlier() throws Exception {
        var owner = user("0977100012", Role.ROLE_CONTRACTOR, 0);
        var bronze = user("0977100013", Role.ROLE_WORKER, 0);
        var gold = user("0977100014", Role.ROLE_WORKER, 5);
        var job = new Job(); job.setContractor(owner); job.setTitle("Tier ordering"); job.setJobType("Thợ chính"); job.setSalaryPerDay(450000); job.setAddress("QA"); job.setLatitude(10); job.setLongitude(106); job.setRequiredWorkers(2); jobs.saveAndFlush(job);
        var old = new JobApplication(); old.setWorker(gold); old.setJob(job); old.setAppliedAt(java.time.LocalDateTime.now().minusDays(1)); applications.saveAndFlush(old);
        var recent = new JobApplication(); recent.setWorker(bronze); recent.setJob(job); applications.saveAndFlush(recent);
        mvc.perform(get("/api/applications/job/" + job.getId()).header("Authorization", "Bearer " + jwt.generateToken(owner.getPhoneNumber())))
            .andExpect(status().isOk()).andExpect(jsonPath("$[0].workerId").value(gold.getId()))
            .andExpect(jsonPath("$[1].workerId").value(bronze.getId()));
    }
}
