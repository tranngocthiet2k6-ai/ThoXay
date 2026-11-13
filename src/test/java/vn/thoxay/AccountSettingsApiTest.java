package vn.thoxay;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.JwtUtil;
import vn.thoxay.service.ChatAccessService;
import vn.thoxay.notification.NotificationDispatcher;
import java.util.Map;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class AccountSettingsApiTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired UserRepository users;
    @Autowired BCryptPasswordEncoder encoder;
    @Autowired JwtUtil jwt;
    @Autowired ChatAccessService chat;
    User user;
    String token;
    @BeforeEach void setup() {
        user = new User(); user.setPhoneNumber("0988881234"); user.setPassword(encoder.encode("Oldpass123"));
        user.setFullName("Thợ thử nghiệm"); user.setRole(Role.ROLE_WORKER); users.saveAndFlush(user);
        token = jwt.generateToken(user.getPhoneNumber());
    }
    private org.springframework.test.web.servlet.ResultActions putSettings(String path, Map<String,Object> body) throws Exception {
        return mvc.perform(put("/api/users/me/settings/" + path).header("Authorization", "Bearer " + token)
            .contentType("application/json").content(json.writeValueAsString(body)));
    }
    @Test void passwordChangeHashesAndRevokesOldTokensWhileNewSessionWorks() throws Exception {
        var response = putSettings("password", Map.of("currentPassword", "Oldpass123", "newPassword", "Newpass456"))
            .andExpect(status().isOk()).andReturn();
        String fresh = json.readTree(response.getResponse().getContentAsString()).get("token").asText();
        assertThat(encoder.matches("Newpass456", users.findById(user.getId()).orElseThrow().getPassword())).isTrue();
        mvc.perform(get("/api/users/me").header("Authorization", "Bearer " + token)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/users/me").header("Authorization", "Bearer " + fresh)).andExpect(status().isOk());
    }
    @Test void wrongPasswordWeakPasswordAndIdenticalPasswordLeaveCredentialsIntact() throws Exception {
        String original = user.getPassword();
        putSettings("password", Map.of("currentPassword", "wrong", "newPassword", "Newpass456")).andExpect(status().isBadRequest());
        for (String candidate : new String[]{"short", "abcdefghijk", "1234567890", "Oldpass123", "é".repeat(36)+"1"})
            putSettings("password", Map.of("currentPassword", "Oldpass123", "newPassword", candidate)).andExpect(status().isBadRequest());
        assertThat(user.getPassword()).isEqualTo(original); assertThat(user.getSecurityVersion()).isZero();
    }
    @Test void phoneChangeRequiresPasswordAndProvidesFreshSession() throws Exception {
        putSettings("phone", Map.of("currentPassword", "wrong", "phoneNumber", "0977771234")).andExpect(status().isBadRequest());
        var response = putSettings("phone", Map.of("currentPassword", "Oldpass123", "phoneNumber", "0977771234"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.phoneNumber").value("0977771234")).andReturn();
        String fresh = json.readTree(response.getResponse().getContentAsString()).get("token").asText();
        mvc.perform(get("/api/users/me").header("Authorization", "Bearer " + token)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/users/me").header("Authorization", "Bearer " + fresh)).andExpect(status().isOk());
    }
    @Test void duplicateOrInvalidPhoneCannotBeSaved() throws Exception {
        User other = new User(); other.setPhoneNumber("0977771234"); other.setPassword("hash"); other.setFullName("Khác"); other.setRole(Role.ROLE_WORKER); users.saveAndFlush(other);
        putSettings("phone", Map.of("currentPassword", "Oldpass123", "phoneNumber", "0977771234")).andExpect(status().isConflict());
        putSettings("phone", Map.of("currentPassword", "Oldpass123", "phoneNumber", "abc")).andExpect(status().isBadRequest());
        assertThat(user.getPhoneNumber()).isEqualTo("0988881234");
    }
    @Test void pushPreferencesAreIndependentAndDoNotSuppressFinancialOrSafetyMessages() throws Exception {
        putSettings("notifications", Map.of("jobPushEnabled", false, "chatPushEnabled", true)).andExpect(status().isOk());
        mvc.perform(get("/api/users/me/settings/notifications").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.jobPushEnabled").value(false)).andExpect(jsonPath("$.chatPushEnabled").value(true));
        assertThat(NotificationDispatcher.allows("APPLICATION_ACCEPTED", user)).isFalse();
        assertThat(NotificationDispatcher.allows("CHAT_MESSAGE", user)).isTrue();
        user.setChatPushEnabled(false);
        assertThat(NotificationDispatcher.allows("CHAT_MESSAGE", user)).isFalse();
        assertThat(NotificationDispatcher.allows("WALLET_REQUEST", user)).isTrue();
        assertThat(NotificationDispatcher.allows("SOS", user)).isTrue();
    }
    @Test void settingsRequireAuthentication() throws Exception {
        mvc.perform(get("/api/users/me/settings/notifications")).andExpect(status().isUnauthorized());
        mvc.perform(put("/api/users/me/settings/password").contentType("application/json")
            .content("{\"currentPassword\":\"Oldpass123\",\"newPassword\":\"Newpass456\"}")).andExpect(status().isUnauthorized());
    }
    @Test void tokensCannotBeReusedByAnotherAccountWithTheSamePhoneAndVersion() throws Exception {
        String wrongIdentity = jwt.generateToken(user.getPhoneNumber(), user.getSecurityVersion(), user.getId() + 1000);
        mvc.perform(get("/api/users/me").header("Authorization", "Bearer " + wrongIdentity)).andExpect(status().isUnauthorized());
    }
}
