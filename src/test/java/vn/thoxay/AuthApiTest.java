package vn.thoxay;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.repository.UserRepository;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class AuthApiTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired UserRepository users;

    @Test void registerLoginAndRejectDuplicatesAndAdminEscalation() throws Exception {
        String body = """
          {"phoneNumber":"0911111111","password":"password123","fullName":"Nguyễn Văn A","role":"ROLE_WORKER"}
          """;
        var result = mvc.perform(post("/api/auth/register").contentType("application/json").content(body))
            .andExpect(status().isCreated()).andExpect(jsonPath("role").value("ROLE_WORKER"))
            .andExpect(jsonPath("password").doesNotExist()).andReturn();
        assertThat(json.readTree(result.getResponse().getContentAsString()).get("token").asText()).isNotBlank();
        assertThat(users.findByPhoneNumber("0911111111").orElseThrow().getPassword()).startsWith("$2a$");
        mvc.perform(post("/api/auth/register").contentType("application/json").content(body)).andExpect(status().isConflict());
        mvc.perform(post("/api/auth/register").contentType("application/json").content(body.replace("ROLE_WORKER", "ROLE_ADMIN")))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/auth/login").contentType("application/json").content("""
          {"phoneNumber":"0911111111","password":"password123"}
          """)).andExpect(status().isOk()).andExpect(jsonPath("token").isString());
        mvc.perform(post("/api/auth/login").contentType("application/json").content("""
          {"phoneNumber":"0911111111","password":"wrong-password"}
          """)).andExpect(status().isUnauthorized());
        var user = users.findByPhoneNumber("0911111111").orElseThrow(); user.setActive(false); users.saveAndFlush(user);
        mvc.perform(post("/api/auth/login").contentType("application/json").content("""
          {"phoneNumber":"0911111111","password":"password123"}
          """)).andExpect(status().isForbidden())
            .andExpect(jsonPath("code").value("ACCOUNT_LOCKED"))
            .andExpect(jsonPath("message").value(vn.thoxay.exception.AccountLockedException.MESSAGE));
    }

    @Test void protectedEndpointsRejectMissingAndForgedJwt() throws Exception {
        mvc.perform(get("/api/jobs/nearby")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/jobs/nearby").header("Authorization", "Bearer forged.token.value"))
            .andExpect(status().isUnauthorized());
    }
}
