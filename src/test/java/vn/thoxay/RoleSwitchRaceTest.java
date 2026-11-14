package vn.thoxay;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

@SpringBootTest(properties="spring.datasource.url=jdbc:h2:mem:role_race;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;LOCK_TIMEOUT=10000")
@AutoConfigureMockMvc
class RoleSwitchRaceTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired NotificationRepository notifications;
    @Autowired JwtUtil jwt;
    User owner, worker;
    @BeforeEach void setup() {
        clean(); owner=user("0977300011",Role.ROLE_CONTRACTOR); worker=user("0977300012",Role.ROLE_WORKER);
    }
    @AfterEach void clean() { notifications.deleteAllInBatch(); applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch(); }
    User user(String phone, Role role) { var u=new User(); u.setPhoneNumber(phone); u.setFullName("Race QA"); u.setPassword("hash"); u.setRole(role); u.setAvailable(true); return users.saveAndFlush(u); }
    String token(User u) { return "Bearer "+jwt.generateToken(u.getPhoneNumber(),u.getSecurityVersion(),u.getId()); }
    int change(User user, String target) throws Exception { return mvc.perform(put("/api/users/me/settings/role").header("Authorization",token(user)).contentType("application/json").content("{\"role\":\""+target+"\"}")).andReturn().getResponse().getStatus(); }
    int[] race(Callable<Integer> first, Callable<Integer> second) throws Exception {
        var pool=Executors.newFixedThreadPool(2); var start=new CountDownLatch(1);
        try {
            var a=pool.submit(() -> { start.await(); return first.call(); });
            var b=pool.submit(() -> { start.await(); return second.call(); }); start.countDown();
            return new int[]{a.get(25,TimeUnit.SECONDS),b.get(25,TimeUnit.SECONDS)};
        } finally { pool.shutdownNow(); }
    }
    @Test void postingAndSwitchingCannotLeaveAnOpenJobOwnedByActiveWorkerMode() throws Exception {
        int[] status=race(() -> change(owner,"ROLE_WORKER"), () -> mvc.perform(post("/api/jobs").header("Authorization",token(owner)).contentType("application/json")
            .content("{\"title\":\"Race job\",\"description\":\"QA\",\"jobType\":\"Thợ chính\",\"salaryPerDay\":450000,\"address\":\"QA\",\"latitude\":10,\"longitude\":106,\"requiredWorkers\":1}")).andReturn().getResponse().getStatus());
        assertThat(status[0]).isIn(200,409); assertThat(status[1]).isIn(201,401,403,409);
        var actual=users.findById(owner.getId()).orElseThrow();
        assertThat(actual.getRole()==Role.ROLE_WORKER && jobs.count()>0).isFalse();
    }
    @Test void applyingAndSwitchingCannotLeaveActiveApplicationsInContractorMode() throws Exception {
        var j=new Job(); j.setContractor(owner); j.setTitle("Race apply"); j.setJobType("Thợ chính"); j.setSalaryPerDay(450000); j.setAddress("QA"); j.setLatitude(10); j.setLongitude(106); j.setRequiredWorkers(1); jobs.saveAndFlush(j);
        int[] status=race(() -> change(worker,"ROLE_CONTRACTOR"), () -> mvc.perform(post("/api/applications/apply").header("Authorization",token(worker)).contentType("application/json")
            .content("{\"jobId\":"+j.getId()+"}")).andReturn().getResponse().getStatus());
        assertThat(status[0]).isIn(200,409); assertThat(status[1]).isIn(201,401,403,409);
        var actual=users.findById(worker.getId()).orElseThrow();
        assertThat(actual.getRole()==Role.ROLE_CONTRACTOR && applications.count()>0).isFalse();
    }
}
