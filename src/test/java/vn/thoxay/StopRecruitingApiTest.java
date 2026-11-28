package vn.thoxay;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.crew.*;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import java.time.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class StopRecruitingApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired NotificationRepository notifications;
    @Autowired CrewRepository crews;
    @Autowired CrewBatchRepository batches;
    @Autowired JwtUtil jwt;
    @Autowired Clock clock;
    User owner, worker, waiting, outsider, admin;
    Job job;

    @BeforeEach void setup() {
        owner = user("0960000001", Role.ROLE_CONTRACTOR);
        worker = user("0960000002", Role.ROLE_WORKER);
        waiting = user("0960000003", Role.ROLE_WORKER);
        outsider = user("0960000004", Role.ROLE_CONTRACTOR);
        admin = user("0960000005", Role.ROLE_ADMIN);
        job = new Job(); job.setContractor(owner); job.setTitle("Công trình dừng tuyển");
        job.setJobType("Thợ chính"); job.setAddress("TP.HCM"); job.setLatitude(10); job.setLongitude(106);
        job.setSalaryPerDay(500000); job.setRequiredWorkers(5);
        job.setStartsOn(LocalDate.now(clock).plusDays(1)); job.setEndsOn(job.getStartsOn().plusDays(2));
        jobs.saveAndFlush(job);
    }

    @Test void closesRecruitmentAndPreservesAcceptedWorkersForCompletion() throws Exception {
        var accepted = application(worker, ApplicationStatus.ACCEPTED);
        var pending = application(waiting, ApplicationStatus.PENDING);
        mvc.perform(put(path()).header("Authorization", token(owner)))
            .andExpect(status().isOk()).andExpect(jsonPath("recruitmentClosed").value(true))
            .andExpect(jsonPath("status").value("IN_PROGRESS"))
            .andExpect(jsonPath("requiredWorkers").value(5));
        assertThat(accepted.getStatus()).isEqualTo(ApplicationStatus.ACCEPTED);
        assertThat(pending.getStatus()).isEqualTo(ApplicationStatus.REJECTED);
        mvc.perform(get("/api/applications/worker/" + worker.getId()).header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$[0].job.contractorPhone").value(owner.getPhoneNumber()));
        mvc.perform(put("/api/jobs/" + job.getId() + "/complete").header("Authorization", token(owner))
            .contentType("application/json").content("{\"ratings\":[{\"workerId\":" + worker.getId() + ",\"stars\":5}]}"))
            .andExpect(status().isOk()).andExpect(jsonPath("status").value("IN_PROGRESS"))
            .andExpect(jsonPath("ratingsFinalizedAt").isNotEmpty());
    }

    @Test void hidesEmptyClosedJobAndBlocksIndividualCrewApplicationsAndInvitations() throws Exception {
        mvc.perform(put(path()).header("Authorization", token(owner))).andExpect(status().isOk())
            .andExpect(jsonPath("status").value("OPEN"));
        mvc.perform(get("/api/jobs/nearby?lat=10&lng=106").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(post("/api/applications/apply").header("Authorization", token(worker))
            .contentType("application/json").content("{\"jobId\":" + job.getId() + "}"))
            .andExpect(status().isConflict());
        var crew = new Crew(); crew.setLeader(worker); crew.setName("Tổ thợ"); crews.saveAndFlush(crew);
        mvc.perform(post("/api/crews/" + crew.getId() + "/applications").header("Authorization", token(worker))
            .contentType("application/json").content("{\"jobId\":" + job.getId() + "}"))
            .andExpect(status().isConflict());
        mvc.perform(post("/api/users/me/team/invitations").header("Authorization", token(owner))
            .contentType("application/json").content("{\"jobId\":" + job.getId() + ",\"workerIds\":[" + worker.getId() + "]}"))
            .andExpect(status().isConflict());
    }

    @Test void rejectsPendingCrewAndRetryDoesNotDuplicateNotifications() throws Exception {
        var crew = new Crew(); crew.setLeader(worker); crew.setName("Tổ đang chờ"); crews.saveAndFlush(crew);
        var batch = new CrewBatch(); batch.setCrew(crew); batch.setJob(job); batches.saveAndFlush(batch);
        var pending = application(worker, ApplicationStatus.PENDING); pending.setCrewBatch(batch);
        applications.flush();
        mvc.perform(put(path()).header("Authorization", token(owner))).andExpect(status().isOk());
        long notificationCount = notifications.count();
        mvc.perform(put(path()).header("Authorization", token(owner))).andExpect(status().isOk());
        assertThat(notifications.count()).isEqualTo(notificationCount);
        assertThat(batch.getStatus()).isEqualTo("REJECTED");
        assertThat(pending.getStatus()).isEqualTo(ApplicationStatus.REJECTED);
        mvc.perform(put("/api/crew-applications/" + batch.getId() + "/status").header("Authorization", token(owner))
            .contentType("application/json").content("{\"status\":\"ACCEPTED\"}"))
            .andExpect(status().isConflict());
    }

    @Test void onlyOwnerCanStopAndTerminalJobsCannotBeStopped() throws Exception {
        for (User actor : new User[]{worker, outsider, admin})
            mvc.perform(put(path()).header("Authorization", token(actor))).andExpect(status().isForbidden());
        mvc.perform(put(path())).andExpect(status().isUnauthorized());
        assertThat(job.isRecruitmentClosed()).isFalse();
        for (JobStatus status : new JobStatus[]{JobStatus.COMPLETED, JobStatus.CANCELLED}) {
            job.setStatus(status); jobs.flush();
            mvc.perform(put(path()).header("Authorization", token(owner))).andExpect(status().isConflict());
        }
    }

    @Test void aStalePendingApplicationCannotBeAcceptedAfterRecruitmentStops() throws Exception {
        mvc.perform(put(path()).header("Authorization", token(owner))).andExpect(status().isOk());
        var stale = application(worker, ApplicationStatus.PENDING);
        mvc.perform(put("/api/applications/" + stale.getId() + "/status").header("Authorization", token(owner))
            .contentType("application/json").content("{\"status\":\"ACCEPTED\"}"))
            .andExpect(status().isConflict());
        assertThat(stale.getStatus()).isEqualTo(ApplicationStatus.PENDING);
    }

    @Test void cancellationDoesNotReopenRecruitment() throws Exception {
        var accepted = application(worker, ApplicationStatus.ACCEPTED);
        mvc.perform(put(path()).header("Authorization", token(owner))).andExpect(status().isOk());
        mvc.perform(put("/api/applications/" + accepted.getId() + "/cancel").header("Authorization", token(worker))
            .contentType("application/json").content("{\"reason\":\"Không thể tiếp tục công việc\"}"))
            .andExpect(status().isOk());
        mvc.perform(get("/api/jobs/nearby?lat=10&lng=106").header("Authorization", token(waiting)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(post("/api/applications/apply").header("Authorization", token(waiting))
            .contentType("application/json").content("{\"jobId\":" + job.getId() + "}"))
            .andExpect(status().isConflict());
    }

    private String path() { return "/api/jobs/" + job.getId() + "/stop-recruiting"; }
    private String token(User user) { return "Bearer " + jwt.generateToken(user.getPhoneNumber()); }
    private User user(String phone, Role role) {
        var user = new User(); user.setPhoneNumber(phone); user.setPassword("hash");
        user.setFullName("Tài khoản kiểm thử"); user.setRole(role); return users.saveAndFlush(user);
    }
    private JobApplication application(User user, ApplicationStatus status) {
        var a = new JobApplication(); a.setJob(job); a.setWorker(user); a.setStatus(status);
        return applications.saveAndFlush(a);
    }
}
