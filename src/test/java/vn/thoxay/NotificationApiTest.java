package vn.thoxay;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import vn.thoxay.entity.*;
import vn.thoxay.notification.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import vn.thoxay.service.NotificationService;
import java.time.Instant;
import java.util.Map;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "app.notifications.dispatch-enabled=false") @AutoConfigureMockMvc
class NotificationApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired MessageRepository messages;
    @Autowired NotificationRepository notifications;
    @Autowired DeviceTokenRepository devices;
    @Autowired NotificationService service;
    @Autowired NotificationDispatcher dispatcher;
    @Autowired PlatformTransactionManager transactions;
    @Autowired JwtUtil jwt;
    @MockitoBean PushGateway push;
    User owner, worker;
    Job job;

    @BeforeEach void setup() {
        clean(); when(push.enabled()).thenReturn(true);
        owner = person("0975555501", Role.ROLE_CONTRACTOR); worker = person("0975555502", Role.ROLE_WORKER);
        job = new Job(); job.setContractor(owner); job.setTitle("Thông báo thử"); job.setJobType("Thợ chính");
        job.setAddress("TP.HCM"); job.setSalaryPerDay(500000); job.setRequiredWorkers(1); jobs.saveAndFlush(job);
    }
    @AfterEach void clean() {
        notifications.deleteAllInBatch(); devices.deleteAllInBatch(); messages.deleteAllInBatch();
        applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch();
    }
    @Test void eventsAreTransactionalPrivatePaginatedAndDecisionsAreIdempotent() throws Exception {
        mvc.perform(post("/api/applications/apply").header("Authorization", token(worker)).contentType("application/json")
            .content("{\"jobId\":" + job.getId() + "}")).andExpect(status().isCreated());
        Long application = applications.findByJobIdOrderByAppliedAtDesc(job.getId()).get(0).getId();
        for (int i = 0; i < 2; i++) mvc.perform(put("/api/applications/" + application + "/status").header("Authorization", token(owner))
            .contentType("application/json").content("{\"status\":\"ACCEPTED\"}")).andExpect(status().isOk());
        mvc.perform(post("/api/jobs/" + job.getId() + "/messages").header("Authorization", token(worker)).contentType("application/json")
            .content("{\"recipientId\":" + owner.getId() + ",\"content\":\"Tin riêng tư không được đưa lên push\",\"clientMessageId\":\"notification-chat\"}"))
            .andExpect(status().isCreated());
        mvc.perform(put("/api/jobs/" + job.getId() + "/complete").header("Authorization", token(owner)).contentType("application/json")
            .content("{\"ratings\":[{\"workerId\":" + worker.getId() + ",\"stars\":5}]}"))
            .andExpect(status().isOk());
        assertThat(notifications.count()).isEqualTo(4);
        var chat = notifications.findAll().stream().filter(n -> n.getType().equals("CHAT_MESSAGE")).findFirst().orElseThrow();
        assertThat(chat.getBody()).doesNotContain("Tin riêng tư");
        mvc.perform(get("/api/notifications").header("Authorization", token(worker)).param("limit", "1"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.items.length()").value(1))
            .andExpect(jsonPath("$.hasMore").value(true)).andExpect(jsonPath("$.unreadCount").value(2))
            .andExpect(jsonPath("$.items[0].type").value("JOB_COMPLETED"));
        mvc.perform(put("/api/notifications/" + chat.getId() + "/read").header("Authorization", token(worker))).andExpect(status().isNotFound());
        mvc.perform(put("/api/notifications/read-all").header("Authorization", token(worker))).andExpect(status().isNoContent());
        mvc.perform(get("/api/notifications").header("Authorization", token(worker))).andExpect(jsonPath("$.unreadCount").value(0));
        mvc.perform(get("/api/notifications").header("Authorization", token(owner)).param("beforeId", chat.getId().toString()))
            .andExpect(status().isOk()).andExpect(jsonPath("$.items.length()").value(1)).andExpect(jsonPath("$.unreadCount").value(2));
        mvc.perform(get("/api/notifications")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/notifications").header("Authorization", token(worker)).param("limit", "101")).andExpect(status().isBadRequest());
    }
    @Test void deviceOwnershipCanMoveOnLoginButAnotherUserCannotUnregisterIt() throws Exception {
        device(owner, "fid-device-a"); device(owner, "fid-device-a"); assertThat(devices.count()).isEqualTo(1);
        device(worker, "fid-device-a");
        mvc.perform(post("/api/notifications/devices/unregister").header("Authorization", token(owner)).contentType("application/json")
            .content("{\"token\":\"fid-device-a\"}")).andExpect(status().isNoContent());
        assertThat(devices.findAll().get(0).getUser().getId()).isEqualTo(worker.getId());
        mvc.perform(post("/api/notifications/devices/unregister").header("Authorization", token(worker)).contentType("application/json")
            .content("{\"token\":\"fid-device-a\"}")).andExpect(status().isNoContent());
        assertThat(devices.count()).isZero();
        mvc.perform(put("/api/notifications/devices").header("Authorization", token(worker)).contentType("application/json")
            .content("{\"token\":\"\"}")).andExpect(status().isBadRequest());
    }
    @Test void outboxRetriesTransientErrorsPrunesInvalidDevicesAndKeepsHistory() throws Exception {
        device(worker, "good-fid"); device(worker, "stale-fid");
        Long id = create(worker, "outbox");
        when(push.send(eq("good-fid"), anyString(), anyString(), anyMap())).thenReturn(PushGateway.Result.RETRY);
        when(push.send(eq("stale-fid"), anyString(), anyString(), anyMap())).thenReturn(PushGateway.Result.INVALID_TOKEN);
        dispatcher.deliver(id);
        assertThat(devices.count()).isEqualTo(1);
        var n = notifications.findById(id).orElseThrow(); assertThat(n.getPushStatus()).isEqualTo("PENDING");
        assertThat(n.getPushAttempts()).isEqualTo(1);
        n.setNextAttemptAt(Instant.now().minusSeconds(1)); notifications.saveAndFlush(n);
        when(push.send(eq("good-fid"), anyString(), anyString(), anyMap())).thenReturn(PushGateway.Result.ACCEPTED);
        dispatcher.deliver(id); dispatcher.deliver(id);
        assertThat(notifications.findById(id).orElseThrow().getPushStatus()).isEqualTo("ACCEPTED");
        verify(push, times(2)).send(eq("good-fid"), anyString(), anyString(), argThat(data -> worker.getId().toString().equals(data.get("userId"))));
        mvc.perform(get("/api/notifications").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.items.length()").value(1));
    }
    @Test void rollbackOrLockedAccountCannotSendPushAndRepeatedFailuresAreBounded() throws Exception {
        new TransactionTemplate(transactions).executeWithoutResult(tx -> {
            service.create(worker, job, "rolled-back", "CHAT_MESSAGE", "Không gửi", "Đã rollback"); tx.setRollbackOnly();
        });
        assertThat(notifications.count()).isZero(); verify(push, never()).send(anyString(), anyString(), anyString(), anyMap());
        device(worker, "offline-fid"); Long id = create(worker, "retry-three");
        when(push.send(anyString(), anyString(), anyString(), anyMap())).thenReturn(PushGateway.Result.RETRY);
        for (int i = 0; i < 3; i++) {
            var n = notifications.findById(id).orElseThrow(); n.setNextAttemptAt(Instant.now().minusSeconds(1)); notifications.saveAndFlush(n); dispatcher.deliver(id);
        }
        assertThat(notifications.findById(id).orElseThrow().getPushStatus()).isEqualTo("FAILED");
        assertThat(notifications.findById(id).orElseThrow().getPushAttempts()).isEqualTo(3);
        Long locked = create(worker, "locked"); worker.setActive(false); users.saveAndFlush(worker);
        dispatcher.deliver(locked);
        assertThat(notifications.findById(locked).orElseThrow().getPushStatus()).isEqualTo("SKIPPED");
        verify(push, times(3)).send(anyString(), anyString(), anyString(), anyMap());
    }
    private Long create(User recipient, String key) {
        new TransactionTemplate(transactions).executeWithoutResult(tx -> service.create(recipient, job, key, "CHAT_MESSAGE", "Có thông báo", "Mở ứng dụng để xem."));
        return notifications.findAll().stream().filter(n -> n.getEventKey().equals(key)).findFirst().orElseThrow().getId();
    }
    private void device(User user, String token) throws Exception {
        mvc.perform(put("/api/notifications/devices").header("Authorization", token(user)).contentType("application/json")
            .content("{\"token\":\"" + token + "\"}")).andExpect(status().isNoContent());
    }
    private String token(User user) { return "Bearer " + jwt.generateToken(user.getPhoneNumber()); }
    private User person(String phone, Role role) { User u = new User(); u.setPhoneNumber(phone); u.setRole(role); u.setFullName("Notification test"); u.setPassword("hash"); return users.saveAndFlush(u); }
}
