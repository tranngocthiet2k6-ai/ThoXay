package vn.thoxay;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.JwtUtil;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class KycApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JwtUtil jwt;
    @Autowired ObjectMapper json;
    @Autowired EntityManager entityManager;
    int phoneSequence = 1000000;

    @Test void missingFacesCannotRemainVerifiedForAnyRole() {
        for (Role role : Role.values()) {
            User person = person(role);
            person.setVerified(true); users.saveAndFlush(person);
            assertThat(person.isVerified()).isFalse();
            person.setCccdFrontImage("https://example.com/front.jpg");
            person.setVerified(true); users.saveAndFlush(person);
            assertThat(person.isVerified()).isFalse();
            person.setCccdBackImage("https://example.com/back.jpg");
            person.setVerified(true); users.saveAndFlush(person);
            assertThat(person.isVerified()).isTrue();
            person.setCccdBackImage(null); users.saveAndFlush(person);
            assertThat(person.isVerified()).isFalse();
        }
    }

    @Test void databaseDefaultsToUnverifiedAndRejectsBypassingTheTwoFaceInvariant() {
        entityManager.createNativeQuery("""
            INSERT INTO users (phone_number,password,full_name,role,is_active,rating,created_at)
            VALUES ('0989999999','hash','KYC default test','ROLE_ADMIN',TRUE,5,CURRENT_TIMESTAMP)
            """).executeUpdate();
        User person = users.findByPhoneNumber("0989999999").orElseThrow();
        assertThat(person.isVerified()).isFalse();
        assertThatThrownBy(() -> entityManager.createNativeQuery("UPDATE users SET is_verified=TRUE WHERE id=:id")
            .setParameter("id", person.getId()).executeUpdate()).isInstanceOf(PersistenceException.class);
    }

    @Test void profileRejectsMissingOrInsecureFacesWithoutChangingApprovedImages() throws Exception {
        User person = person(Role.ROLE_WORKER);
        person.setCccdFrontImage("https://example.com/old-front.jpg");
        person.setCccdBackImage("https://example.com/old-back.jpg");
        person.setVerified(true); users.saveAndFlush(person);
        String[] invalidRequests = {
            "{\"cccdFrontImage\":\"https://example.com/front.jpg\"}",
            "{\"cccdBackImage\":\"https://example.com/back.jpg\"}",
            "{\"cccdFrontImage\":\"https://example.com/front.jpg\",\"cccdBackImage\":\"http://example.com/back.jpg\"}",
            "{\"cccdFrontImage\":\"\",\"cccdBackImage\":\"https://example.com/back.jpg\"}"
        };
        for (String body : invalidRequests) {
            mvc.perform(put("/api/users/me/cccd").header("Authorization", token(person))
                .contentType("application/json").content(body)).andExpect(status().isBadRequest());
        }
        mvc.perform(get("/api/users/me").header("Authorization", token(person)))
            .andExpect(status().isOk()).andExpect(jsonPath("verified").value(true))
            .andExpect(jsonPath("cccdFrontImage").value("https://example.com/old-front.jpg"))
            .andExpect(jsonPath("cccdBackImage").value("https://example.com/old-back.jpg"))
            .andExpect(jsonPath("cccdImage").doesNotExist());
    }

    @Test void adminRequiresBothCurrentSnapshotsAndCannotApproveMissingFaces() throws Exception {
        User admin = person(Role.ROLE_ADMIN), worker = person(Role.ROLE_WORKER);
        worker.setCccdFrontImage("https://example.com/front.jpg"); users.saveAndFlush(worker);
        verify(admin, worker, worker.getCccdFrontImage(), "https://example.com/back.jpg", false);
        assertThat(worker.isVerified()).isFalse();
        worker.setCccdBackImage("https://example.com/back.jpg"); users.saveAndFlush(worker);
        verify(admin, worker, "https://example.com/stale-front.jpg", worker.getCccdBackImage(), false);
        verify(admin, worker, worker.getCccdFrontImage(), "https://example.com/stale-back.jpg", false);
        assertThat(worker.isVerified()).isFalse();
        verify(admin, worker, worker.getCccdFrontImage(), worker.getCccdBackImage(), true);
        assertThat(worker.isVerified()).isTrue();
        mvc.perform(put("/api/users/me/cccd").header("Authorization", token(worker))
            .contentType("application/json").content("{\"cccdFrontImage\":\"https://example.com/front.jpg\",\"cccdBackImage\":\"https://example.com/new-back.jpg\"}"))
            .andExpect(status().isOk()).andExpect(jsonPath("verified").value(false));
        verify(admin, worker, "https://example.com/front.jpg", "https://example.com/back.jpg", false);
    }

    @Test void registeringWithNoImagesOneImageOrBothNeverAutoVerifies() throws Exception {
        for (String faces : new String[]{"", ",\"cccdFrontImage\":\"https://example.com/front.jpg\"",
            ",\"cccdFrontImage\":\"https://example.com/front.jpg\",\"cccdBackImage\":\"https://example.com/back.jpg\""}) {
            String phone = nextPhone();
            String body = "{\"phoneNumber\":\"" + phone + "\",\"password\":\"password123\",\"fullName\":\"KYC registration\",\"role\":\"ROLE_CONTRACTOR\"" + faces + "}";
            mvc.perform(post("/api/auth/register").contentType("application/json").content(body))
                .andExpect(status().isCreated());
            assertThat(users.findByPhoneNumber(phone).orElseThrow().isVerified()).isFalse();
        }
    }

    private void verify(User admin, User target, String front, String back, boolean success) throws Exception {
        mvc.perform(post("/admin/users/" + target.getId() + "/verify").with(csrf())
            .with(user(admin.getPhoneNumber()).roles("ADMIN"))
            .param("cccdFrontImage", front).param("cccdBackImage", back))
            .andExpect(status().is3xxRedirection()).andExpect(flash().attributeExists(success ? "success" : "error"));
    }
    private String token(User person) { return "Bearer " + jwt.generateToken(person.getPhoneNumber()); }
    private String nextPhone() { return "098" + phoneSequence++; }
    private User person(Role role) {
        User person = new User(); person.setPhoneNumber(nextPhone()); person.setPassword("hash");
        person.setFullName("KYC fixture"); person.setRole(role); return users.saveAndFlush(person);
    }
}
