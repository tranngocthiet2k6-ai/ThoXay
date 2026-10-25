package vn.thoxay;

import com.fasterxml.jackson.databind.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.web.servlet.MockMvc;
import vn.thoxay.chat.ChatWebSocketHandler;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import java.net.URI;
import java.net.http.*;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT) @AutoConfigureMockMvc
class ChatApiTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired MessageRepository messages;
    @Autowired JwtUtil jwt;
    @Autowired ChatWebSocketHandler sockets;
    @LocalServerPort int port;
    User owner, worker, otherWorker, stranger, admin;
    Job job;
    final List<SocketClient> clients = new ArrayList<>();

    @BeforeEach void setup() {
        clean();
        owner = user("0981111101", Role.ROLE_CONTRACTOR); worker = user("0981111102", Role.ROLE_WORKER);
        otherWorker = user("0981111103", Role.ROLE_WORKER); stranger = user("0981111104", Role.ROLE_CONTRACTOR);
        admin = user("0981111105", Role.ROLE_ADMIN);
        job = job(); accept(job, worker); accept(job, otherWorker);
    }
    @AfterEach void clean() {
        for (SocketClient c : clients) c.socket.abort();
        clients.clear(); messages.deleteAllInBatch(); applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch();
    }

    @Test void persistsBothDirectionsAndRetriesWithoutDuplicatesOrSpoofedSender() throws Exception {
        var first = send(worker, job, owner, "  Chào chủ thầu  ", "once");
        assertThat(first.path("content").asText()).isEqualTo("Chào chủ thầu");
        assertThat(first.path("senderId").asLong()).isEqualTo(worker.getId());
        var retry = send(worker, job, owner, "Chào chủ thầu", "once");
        assertThat(retry.path("id")).isEqualTo(first.path("id"));
        send(owner, job, worker, "Hẹn sáng mai", "reply");
        assertThat(messages.count()).isEqualTo(2);
        mvc.perform(get(path(job)).header("Authorization", token(worker)).param("peerId", owner.getId().toString()))
            .andExpect(status().isOk()).andExpect(jsonPath("$.messages.length()").value(2))
            .andExpect(jsonPath("$.messages[0].content").value("Chào chủ thầu"))
            .andExpect(jsonPath("$.messages[1].content").value("Hẹn sáng mai"));
        mvc.perform(post(path(job)).header("Authorization", token(worker)).contentType("application/json")
            .content(body(owner, "Nội dung khác", "once"))).andExpect(status().isConflict());
        assertThat(messages.count()).isEqualTo(2);
    }

    @Test void onlyAcceptedPairCanReadOrSendAndCannotReadAnotherWorkersHistory() throws Exception {
        send(owner, job, worker, "Riêng tư", "private");
        mvc.perform(get(path(job)).header("Authorization", token(otherWorker)).param("peerId", owner.getId().toString()))
            .andExpect(status().isOk()).andExpect(jsonPath("$.messages.length()").value(0));
        for (User actor : List.of(stranger, admin, otherWorker)) {
            mvc.perform(get(path(job)).header("Authorization", token(actor)).param("peerId", worker.getId().toString()))
                .andExpect(status().isForbidden());
            mvc.perform(post(path(job)).header("Authorization", token(actor)).contentType("application/json")
                .content(body(worker, "Không được gửi", "denied"))).andExpect(status().isForbidden());
        }
        Job pending = job();
        JobApplication a = new JobApplication(); a.setJob(pending); a.setWorker(worker); applications.saveAndFlush(a);
        for (ApplicationStatus status : List.of(ApplicationStatus.PENDING, ApplicationStatus.REJECTED)) {
            a.setStatus(status); applications.saveAndFlush(a);
            mvc.perform(get(path(pending)).header("Authorization", token(worker)).param("peerId", owner.getId().toString()))
                .andExpect(status().isForbidden());
            mvc.perform(post(path(pending)).header("Authorization", token(worker)).contentType("application/json")
                .content(body(owner, "Chưa được duyệt", "pending"))).andExpect(status().isForbidden());
        }
        mvc.perform(get(path(job)).param("peerId", owner.getId().toString())).andExpect(status().isUnauthorized());
    }

    @Test void historyCursorsAreBoundedOrderedAndIsolatedByJob() throws Exception {
        List<Long> ids = new ArrayList<>();
        for (int i = 0; i < 5; i++) ids.add(send(worker, job, owner, "Tin " + i, "cursor" + i).path("id").asLong());
        Job another = job(); accept(another, worker); send(worker, another, owner, "Công việc khác", "different-job");
        mvc.perform(get(path(job)).header("Authorization", token(owner)).param("peerId", worker.getId().toString()).param("limit", "2"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.hasMore").value(true))
            .andExpect(jsonPath("$.messages[0].id").value(ids.get(3))).andExpect(jsonPath("$.messages[1].id").value(ids.get(4)));
        mvc.perform(get(path(job)).header("Authorization", token(worker)).param("peerId", owner.getId().toString())
            .param("beforeId", ids.get(3).toString()).param("limit", "2"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.messages[0].id").value(ids.get(1)))
            .andExpect(jsonPath("$.messages[1].id").value(ids.get(2)));
        mvc.perform(get(path(job)).header("Authorization", token(worker)).param("peerId", owner.getId().toString())
            .param("afterId", ids.get(2).toString()))
            .andExpect(status().isOk()).andExpect(jsonPath("$.messages.length()").value(2))
            .andExpect(jsonPath("$.messages[0].id").value(ids.get(3))).andExpect(jsonPath("$.hasMore").value(false));
        mvc.perform(get(path(job)).header("Authorization", token(worker)).param("peerId", owner.getId().toString()).param("limit", "101"))
            .andExpect(status().isBadRequest());
        mvc.perform(get(path(job)).header("Authorization", token(worker)).param("peerId", owner.getId().toString())
            .param("afterId", "0").param("beforeId", "10")).andExpect(status().isBadRequest());
    }

    @Test void validatesContentAndKeepsChatAfterCompletion() throws Exception {
        for (String content : List.of(" ", "x".repeat(2001)))
            mvc.perform(post(path(job)).header("Authorization", token(worker)).contentType("application/json")
                .content(body(owner, content, "invalid"))).andExpect(status().isBadRequest());
        job.setStatus(JobStatus.COMPLETED); jobs.saveAndFlush(job);
        send(owner, job, worker, "Cảm ơn đã hoàn thành", "complete");
        assertThat(messages.count()).isEqualTo(1);
    }

    @Test void actualWebSocketDeliversCommittedMessageOnlyToTheCorrectPair() throws Exception {
        SocketClient workerSocket = subscribe(worker, job, owner);
        SocketClient ownerSocket = subscribe(owner, job, worker);
        SocketClient otherSocket = subscribe(otherWorker, job, owner);
        Job another = job(); accept(another, worker);
        SocketClient anotherSocket = subscribe(worker, another, owner);
        JsonNode sent = send(worker, job, owner, "Realtime không tải lại", "realtime");
        for (SocketClient c : List.of(workerSocket, ownerSocket)) {
            JsonNode event = c.await("message");
            assertThat(event.path("message").path("id")).isEqualTo(sent.path("id"));
        }
        assertThat(messages.existsById(sent.path("id").asLong())).isTrue();
        assertThat(otherSocket.events.poll(200, TimeUnit.MILLISECONDS)).isNull();
        assertThat(anotherSocket.events.poll(200, TimeUnit.MILLISECONDS)).isNull();
        send(worker, job, owner, "Realtime không tải lại", "realtime");
        assertThat(workerSocket.events.poll(200, TimeUnit.MILLISECONDS)).isNull();
    }

    @Test void websocketRejectsBadJwtPendingPairAndOldTokensAfterLock() throws Exception {
        SocketClient bad = open(); bad.subscribe("bad-jwt", job.getId(), owner.getId());
        assertThat(bad.await("error").path("code").asText()).isEqualTo("UNAUTHORIZED");
        SocketClient outsider = open(); outsider.subscribe(jwt.generateToken(stranger.getPhoneNumber()), job.getId(), worker.getId());
        assertThat(outsider.await("error").path("code").asText()).isEqualTo("CHAT_FORBIDDEN");
        SocketClient valid = subscribe(worker, job, owner);
        worker.setActive(false); users.saveAndFlush(worker);
        sockets.heartbeat();
        assertThat(valid.await("error").path("code").asText()).isEqualTo("ACCOUNT_LOCKED");
        mvc.perform(get(path(job)).header("Authorization", token(worker)).param("peerId", owner.getId().toString()))
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCOUNT_LOCKED"));
        mvc.perform(post(path(job)).header("Authorization", token(owner)).contentType("application/json")
            .content(body(worker, "Thợ bị khóa", "locked-peer"))).andExpect(status().isForbidden());
    }

    @Test void websocketRejectsRevokedParticipationAndMessagesAreDeletedWithJob() throws Exception {
        SocketClient valid = subscribe(owner, job, worker);
        send(owner, job, worker, "Sắp xóa", "delete"); valid.await("message");
        mvc.perform(post("/admin/jobs/" + job.getId() + "/delete").with(csrf())
            .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN")))
            .andExpect(status().is3xxRedirection());
        assertThat(messages.count()).isZero();
        sockets.heartbeat();
        assertThat(valid.await("error").path("code").asText()).isEqualTo("CHAT_FORBIDDEN");
    }

    private String path(Job j) { return "/api/jobs/" + j.getId() + "/messages"; }
    private String token(User u) { return "Bearer " + jwt.generateToken(u.getPhoneNumber()); }
    private String body(User recipient, String content, String id) throws Exception {
        return json.writeValueAsString(Map.of("recipientId", recipient.getId(), "content", content, "clientMessageId", id));
    }
    private JsonNode send(User sender, Job j, User recipient, String content, String id) throws Exception {
        return json.readTree(mvc.perform(post(path(j)).header("Authorization", token(sender)).contentType("application/json")
            .content(body(recipient, content, id))).andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
    }
    private User user(String phone, Role role) {
        User u = new User(); u.setPhoneNumber(phone); u.setPassword("hash"); u.setFullName("Chat demo"); u.setRole(role);
        return users.saveAndFlush(u);
    }
    private Job job() {
        Job j = new Job(); j.setContractor(owner); j.setTitle("Công trình chat"); j.setAddress("TP.HCM");
        j.setJobType("Thợ chính"); j.setSalaryPerDay(500000); j.setRequiredWorkers(3); return jobs.saveAndFlush(j);
    }
    private void accept(Job j, User worker) {
        JobApplication a = new JobApplication(); a.setJob(j); a.setWorker(worker); a.setStatus(ApplicationStatus.ACCEPTED);
        applications.saveAndFlush(a);
    }
    private SocketClient subscribe(User actor, Job j, User peer) throws Exception {
        SocketClient c = open(); c.subscribe(jwt.generateToken(actor.getPhoneNumber()), j.getId(), peer.getId()); c.await("ready"); return c;
    }
    private SocketClient open() {
        SocketClient c = new SocketClient();
        c.socket = HttpClient.newHttpClient().newWebSocketBuilder().buildAsync(URI.create("ws://127.0.0.1:" + port + "/ws/chat"), c).join();
        clients.add(c); return c;
    }
    private class SocketClient implements WebSocket.Listener {
        WebSocket socket;
        final BlockingQueue<JsonNode> events = new LinkedBlockingQueue<>();
        final StringBuilder fragments = new StringBuilder();
        @Override public void onOpen(WebSocket socket) { socket.request(1); }
        @Override public CompletionStage<?> onText(WebSocket socket, CharSequence text, boolean last) {
            fragments.append(text);
            if (last) {
                try { JsonNode event = json.readTree(fragments.toString()); if (!"heartbeat".equals(event.path("type").asText())) events.add(event); }
                catch (Exception e) { throw new IllegalStateException(e); }
                fragments.setLength(0);
            }
            socket.request(1); return CompletableFuture.completedFuture(null);
        }
        void subscribe(String token, Long jobId, Long peerId) throws Exception {
            socket.sendText(json.writeValueAsString(Map.of("type", "subscribe", "token", token, "jobId", jobId, "peerId", peerId)), true).join();
        }
        JsonNode await(String type) throws Exception {
            JsonNode event = events.poll(8, TimeUnit.SECONDS);
            assertThat(event).as("Expected WebSocket %s event", type).isNotNull();
            assertThat(event.path("type").asText()).isEqualTo(type); return event;
        }
    }
}
