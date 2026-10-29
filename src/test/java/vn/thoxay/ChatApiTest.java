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
import org.springframework.mock.web.MockMultipartFile;
import vn.thoxay.chat.MessageAttachmentRepository;
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
    @Autowired MessageAttachmentRepository attachments;
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

    @Test void photoIsSanitizedPrivateIdempotentAndDeletedWithItsJob() throws Exception {
        byte[] image = image(java.awt.Color.ORANGE);
        JsonNode sent = upload(image, "photo-once", "Ảnh tiến độ");
        String photo = sent.path("imagePath").asText();
        assertThat(sent.path("kind").asText()).isEqualTo("IMAGE");
        assertThat(upload(image, "photo-once", "Ảnh tiến độ").path("id")).isEqualTo(sent.path("id"));
        assertThat(attachments.count()).isEqualTo(1);
        for (User actor : List.of(worker, owner)) {
            byte[] clean = mvc.perform(get(photo).header("Authorization", token(actor)))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(content().contentType("image/jpeg")).andReturn().getResponse().getContentAsByteArray();
            var decoded = javax.imageio.ImageIO.read(new java.io.ByteArrayInputStream(clean));
            assertThat(decoded.getWidth()).isEqualTo(320);
        }
        for (User actor : List.of(otherWorker, stranger, admin))
            mvc.perform(get(photo).header("Authorization", token(actor))).andExpect(status().isForbidden());
        mvc.perform(get(photo)).andExpect(status().isUnauthorized());
        mvc.perform(multipart(path(job) + "/photo").file(new MockMultipartFile("photo", "bad.jpg", "image/jpeg", new byte[]{1,2,3}))
            .header("Authorization", token(worker)).param("recipientId", owner.getId().toString())
            .param("clientMessageId", "bad")).andExpect(status().isBadRequest());
        mvc.perform(multipart(path(job) + "/photo").file(new MockMultipartFile("photo", image(java.awt.Color.BLUE)))
            .header("Authorization", token(worker)).param("recipientId", owner.getId().toString())
            .param("clientMessageId", "photo-once").param("caption", "Ảnh tiến độ")).andExpect(status().isConflict());
        // Same idempotency namespace spans text, images and GPS.
        mvc.perform(post(path(job)).header("Authorization", token(worker)).contentType("application/json")
            .content(body(owner, "Ảnh tiến độ", "photo-once"))).andExpect(status().isConflict());
        mvc.perform(post("/admin/jobs/" + job.getId() + "/delete").with(csrf())
            .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().is3xxRedirection());
        assertThat(attachments.count()).isZero();
    }

    @Test void gpsSharesExactConfirmedCoordinatesOverRealtimeAndRejectsChangedRetry() throws Exception {
        var listener = subscribe(owner, job, worker);
        String location = json.writeValueAsString(Map.of("recipientId", owner.getId(), "clientMessageId", "gps-once",
            "latitude", 10.762622, "longitude", 106.660172));
        var first = mvc.perform(post(path(job) + "/location").header("Authorization", token(worker))
            .contentType("application/json").content(location)).andExpect(status().isCreated())
            .andExpect(jsonPath("$.kind").value("LOCATION")).andReturn();
        var event = listener.await("message").path("message");
        assertThat(event.path("latitude").asDouble()).isEqualTo(10.762622);
        assertThat(event.path("longitude").asDouble()).isEqualTo(106.660172);
        mvc.perform(post(path(job) + "/location").header("Authorization", token(worker)).contentType("application/json")
            .content(location)).andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value(json.readTree(first.getResponse().getContentAsString()).path("id").asLong()));
        assertThat(messages.count()).isEqualTo(1);
        assertThat(listener.events.poll(200, TimeUnit.MILLISECONDS)).isNull();
        mvc.perform(post(path(job) + "/location").header("Authorization", token(worker)).contentType("application/json")
            .content(location.replace("10.762622", "11.0"))).andExpect(status().isConflict());
        for (String invalid : List.of(location.replace("10.762622", "91"), location.replace("106.660172", "181")))
            mvc.perform(post(path(job) + "/location").header("Authorization", token(worker)).contentType("application/json")
                .content(invalid)).andExpect(status().isBadRequest());
        worker.setActive(false); users.saveAndFlush(worker);
        mvc.perform(post(path(job) + "/location").header("Authorization", token(owner)).contentType("application/json")
            .content(location.replace(owner.getId().toString(), worker.getId().toString()))).andExpect(status().isForbidden());
    }

    @Test void inboxAndReadReceiptsArePerPairMonotonicAndRejectForeignOrFutureCursor() throws Exception {
        long first = send(owner, job, worker, "Một", "inbox1").path("id").asLong();
        long second = send(owner, job, worker, "Hai", "inbox2").path("id").asLong();
        long other = send(owner, job, otherWorker, "Riêng cho thợ khác", "inbox-other").path("id").asLong();
        mvc.perform(get("/api/messages/inbox").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.unreadCount").value(2))
            .andExpect(jsonPath("$.conversations.length()").value(1))
            .andExpect(jsonPath("$.conversations[0].peerId").value(owner.getId()))
            .andExpect(jsonPath("$.conversations[0].latest.id").value(second))
            .andExpect(jsonPath("$.conversations[0].job.contractorPhone").isEmpty());
        read(worker, job, owner, second, 200);
        read(worker, job, owner, first, 200); // A late receipt never rewinds the cursor.
        mvc.perform(get("/api/messages/unread").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.unreadCount").value(0));
        mvc.perform(get("/api/messages/unread").header("Authorization", token(otherWorker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.unreadCount").value(1));
        read(worker, job, owner, other, 400); read(worker, job, owner, Long.MAX_VALUE, 400);
        Job different = job(); accept(different, worker);
        long foreign = send(owner, different, worker, "Công trình khác", "inbox-other-job").path("id").asLong();
        read(worker, job, owner, foreign, 400);
        send(worker, job, owner, "Trả lời", "reply-inbox");
        mvc.perform(get("/api/messages/unread").header("Authorization", token(owner)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.unreadCount").value(1));
        for (User actor : List.of(admin, stranger)) {
            read(actor, job, worker, second, 403);
        }
        mvc.perform(get("/api/messages/inbox").header("Authorization", token(admin))).andExpect(status().isForbidden());
    }

    @Test void inboxPaginatesConversationsByLatestMessageAndExcludesRevokedPairs() throws Exception {
        long older = send(owner, job, worker, "Cũ", "inbox-old").path("id").asLong();
        Job another = job(); accept(another, worker);
        long newer = send(owner, another, worker, "Mới", "inbox-new").path("id").asLong();
        mvc.perform(get("/api/messages/inbox").header("Authorization", token(worker)).param("beforeId", String.valueOf(newer)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.conversations.length()").value(1))
            .andExpect(jsonPath("$.conversations[0].latest.id").value(older));
        var application = applications.findByJobIdOrderByAppliedAtDesc(another.getId()).stream()
            .filter(a -> a.getWorker().getId().equals(worker.getId())).findFirst().orElseThrow();
        application.setStatus(ApplicationStatus.CANCELLED); applications.saveAndFlush(application);
        mvc.perform(get("/api/messages/unread").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.unreadCount").value(1));
        owner.setActive(false); users.saveAndFlush(owner);
        mvc.perform(get("/api/messages/inbox").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.conversations.length()").value(0))
            .andExpect(jsonPath("$.unreadCount").value(0));
    }

    private void read(User actor, Job job, User peer, long messageId, int status) throws Exception {
        mvc.perform(put(path(job) + "/read").header("Authorization", token(actor)).contentType("application/json")
            .content(json.writeValueAsString(Map.of("peerId", peer.getId(), "lastReadMessageId", messageId))))
            .andExpect(status().is(status));
    }

    private JsonNode upload(byte[] bytes, String key, String caption) throws Exception {
        return json.readTree(mvc.perform(multipart(path(job) + "/photo")
            .file(new MockMultipartFile("photo", "photo.png", "image/png", bytes))
            .header("Authorization", token(worker)).param("recipientId", owner.getId().toString())
            .param("clientMessageId", key).param("caption", caption))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
    }
    private byte[] image(java.awt.Color color) throws Exception {
        var image = new java.awt.image.BufferedImage(320, 240, java.awt.image.BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics(); g.setColor(color); g.fillRect(0,0,320,240); g.dispose();
        var bytes = new java.io.ByteArrayOutputStream(); javax.imageio.ImageIO.write(image, "png", bytes); return bytes.toByteArray();
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
