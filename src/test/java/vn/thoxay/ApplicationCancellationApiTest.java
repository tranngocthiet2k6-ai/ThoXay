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
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;

@SpringBootTest @AutoConfigureMockMvc
class ApplicationCancellationApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired ReputationEventRepository events;
    @Autowired NotificationRepository notifications;
    @Autowired JwtUtil jwt;
    User owner, worker, replacement, admin;
    Job job; JobApplication application;
    @BeforeEach void setup() {
        clean(); owner=user("0965555501",Role.ROLE_CONTRACTOR); worker=user("0965555502",Role.ROLE_WORKER);
        replacement=user("0965555503",Role.ROLE_WORKER); admin=user("0965555504",Role.ROLE_ADMIN);
        job=new Job(); job.setContractor(owner); job.setTitle("Công trình cần thay thế"); job.setJobType("Phụ hồ"); job.setAddress("TP.HCM");
        job.setLatitude(10d); job.setLongitude(106d); job.setSalaryPerDay(300000d); job.setRequiredWorkers(1); job.setStatus(JobStatus.IN_PROGRESS); jobs.saveAndFlush(job);
        application=new JobApplication(); application.setWorker(worker); application.setJob(job); application.setStatus(ApplicationStatus.ACCEPTED); applications.saveAndFlush(application);
    }
    @AfterEach void clean() { applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch(); }
    @Test void concurrentRetriesPenalizeOnceDemoteAndRevokeContactAndChat() throws Exception {
        worker.setReputationScore(80); worker.setCompletedJobs(5); worker.setRating(4); users.saveAndFlush(worker);
        assertThat(users.findById(worker.getId()).orElseThrow().getWorkerTier()).isEqualTo(WorkerTier.GOLD);
        parallel(() -> cancel(worker), () -> cancel(worker));
        User saved=users.findById(worker.getId()).orElseThrow(); assertThat(saved.getReputationScore()).isEqualTo(65);
        assertThat(saved.getCancelledJobs()).isEqualTo(1); assertThat(saved.getWorkerTier()).isEqualTo(WorkerTier.SILVER);
        assertThat(events.count()).isEqualTo(1); assertThat(notifications.count()).isEqualTo(2);
        mvc.perform(get("/api/applications/worker/"+worker.getId()).header("Authorization",token(worker)))
            .andExpect(jsonPath("$[0].status").value("CANCELLED")).andExpect(jsonPath("$[0].cancellationPenalty").value(15))
            .andExpect(jsonPath("$[0].cancellationReason").value("Không thể tiếp tục"))
            .andExpect(jsonPath("$[0].workerPhone").doesNotExist()).andExpect(jsonPath("$[0].job.contractorPhone").doesNotExist());
        mvc.perform(get("/api/jobs/"+job.getId()+"/messages").param("peerId",owner.getId().toString()).header("Authorization",token(worker))).andExpect(status().isForbidden());
    }
    @Test void requiresOwnAcceptedInProgressApplicationAndValidReason() throws Exception {
        assertThat(cancel(owner)).isEqualTo(403); assertThat(cancel(replacement)).isEqualTo(403);
        mvc.perform(put(path()).header("Authorization",token(worker)).contentType("application/json").content("{\"reason\":\" \"}")).andExpect(status().isBadRequest());
        mvc.perform(put(path()).header("Authorization",token(worker)).contentType("application/json").content("{\"reason\":\""+"x".repeat(501)+"\"}")).andExpect(status().isBadRequest());
        application.setStatus(ApplicationStatus.PENDING); applications.saveAndFlush(application); assertThat(cancel(worker)).isEqualTo(409);
        application.setStatus(ApplicationStatus.ACCEPTED); applications.saveAndFlush(application);
        for (JobStatus state : List.of(JobStatus.OPEN,JobStatus.COMPLETED,JobStatus.CANCELLED)) { job.setStatus(state); jobs.saveAndFlush(job); assertThat(cancel(worker)).isEqualTo(409); }
        assertThat(events.count()).isZero(); assertThat(users.findById(worker.getId()).orElseThrow().getReputationScore()).isEqualTo(100);
    }
    @Test void vacancyCanBeFoundAndFilledWithoutRatingCancelledWorker() throws Exception {
        assertThat(cancel(worker)).isEqualTo(200);
        assertThat(jobs.findById(job.getId()).orElseThrow().getStatus()).isEqualTo(JobStatus.IN_PROGRESS);
        mvc.perform(get("/api/jobs/nearby?lat=10&lng=106").header("Authorization",token(replacement))).andExpect(jsonPath("$[0].id").value(job.getId()));
        mvc.perform(post("/api/applications/apply").header("Authorization",token(replacement)).contentType("application/json").content("{\"jobId\":"+job.getId()+"}")).andExpect(status().isCreated());
        JobApplication other=applications.findByJobIdOrderByAppliedAtDesc(job.getId()).stream().filter(a->!a.getId().equals(application.getId()) && a.getStatus()==ApplicationStatus.PENDING).findFirst().orElseThrow();
        mvc.perform(put("/api/applications/"+other.getId()+"/status").header("Authorization",token(owner)).contentType("application/json").content("{\"status\":\"ACCEPTED\"}")).andExpect(status().isOk());
        mvc.perform(get("/api/jobs/nearby?lat=10&lng=106").header("Authorization",token(replacement))).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(put("/api/jobs/"+job.getId()+"/complete").header("Authorization",token(owner)).contentType("application/json")
            .content("{\"ratings\":[{\"workerId\":"+replacement.getId()+",\"stars\":5}]}" )).andExpect(status().isOk());
        assertThat(users.findById(replacement.getId()).orElseThrow().getCompletedJobs()).isEqualTo(1);
        assertThat(users.findById(worker.getId()).orElseThrow().getCompletedJobs()).isZero();
        assertThat(applications.findById(application.getId()).orElseThrow().getWorkerRating()).isNull();
    }
    @Test void penaltyHasFloorAndSurvivesAdminDeletingJob() throws Exception {
        worker.setReputationScore(8); users.saveAndFlush(worker); assertThat(cancel(worker)).isEqualTo(200);
        assertThat(users.findById(worker.getId()).orElseThrow().getReputationScore()).isZero();
        assertThat(applications.findById(application.getId()).orElseThrow().getCancellationPenalty()).isEqualTo(8);
        mvc.perform(post("/admin/jobs/"+job.getId()+"/delete").with(csrf()).with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().is3xxRedirection());
        User saved=users.findById(worker.getId()).orElseThrow(); assertThat(saved.getCancelledJobs()).isEqualTo(1); assertThat(saved.getReputationScore()).isZero();
        var history=events.findAll(); assertThat(history).hasSize(1); assertThat(history.get(0).getJob()).isNull(); assertThat(history.get(0).getApplication()).isNull();
        assertThat(history.get(0).getJobTitle()).isEqualTo("Công trình cần thay thế");
    }
    @Test void completionRacingCancellationCommitsOnlyOneOutcome() throws Exception {
        worker.setReputationScore(80); users.saveAndFlush(worker);
        ExecutorService pool=Executors.newFixedThreadPool(2); CountDownLatch start=new CountDownLatch(1);
        try {
            var a=pool.submit(()->{start.await();return cancel(worker);});
            var b=pool.submit(()->{start.await();return mvc.perform(put("/api/jobs/"+job.getId()+"/complete").header("Authorization",token(owner)).contentType("application/json")
                .content("{\"ratings\":[{\"workerId\":"+worker.getId()+",\"stars\":5}]}" )).andReturn().getResponse().getStatus();});
            start.countDown(); int ca=a.get(15,TimeUnit.SECONDS), co=b.get(15,TimeUnit.SECONDS);
            JobApplication saved=applications.findById(application.getId()).orElseThrow();
            if (saved.getStatus()==ApplicationStatus.CANCELLED) { assertThat(ca).isEqualTo(200); assertThat(co).isEqualTo(400); assertThat(saved.getWorkerRating()).isNull(); }
            else { assertThat(ca).isEqualTo(409); assertThat(co).isEqualTo(200); assertThat(saved.getWorkerRating()).isEqualTo(5); }
            assertThat(events.count()).isEqualTo(1); assertThat(users.findById(worker.getId()).orElseThrow().getReputationScore()).isEqualTo(saved.getStatus()==ApplicationStatus.CANCELLED ? 65 : 82);
        } finally { pool.shutdownNow(); }
    }
    private void parallel(Callable<Integer> a, Callable<Integer> b) throws Exception {
        ExecutorService pool=Executors.newFixedThreadPool(2); CountDownLatch start=new CountDownLatch(1);
        try { var f=pool.submit(()->{start.await();return a.call();}); var g=pool.submit(()->{start.await();return b.call();}); start.countDown(); assertThat(List.of(f.get(15,TimeUnit.SECONDS),g.get(15,TimeUnit.SECONDS))).containsOnly(200); }
        finally { pool.shutdownNow(); }
    }
    private int cancel(User actor) throws Exception { return mvc.perform(put(path()).header("Authorization",token(actor)).contentType("application/json").content("{\"reason\":\"Không thể tiếp tục\"}")).andReturn().getResponse().getStatus(); }
    private String path() { return "/api/applications/"+application.getId()+"/cancel"; }
    private String token(User u) { return "Bearer "+jwt.generateToken(u.getPhoneNumber()); }
    private User user(String phone,Role role) { User u=new User(); u.setPhoneNumber(phone); u.setFullName("Thợ thử nghiệm"); u.setPassword("hash"); u.setRole(role); return users.saveAndFlush(u); }
}
