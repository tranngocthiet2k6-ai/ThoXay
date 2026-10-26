package vn.thoxay;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
class ExtendedProfileApiTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired MessageRepository messages;
    @Autowired JwtUtil jwt;
    User worker, owner;
    @BeforeEach void setup() { clean(); worker = user("0963333301", Role.ROLE_WORKER); owner = user("0963333302", Role.ROLE_CONTRACTOR); }
    @AfterEach void clean() { messages.deleteAllInBatch(); applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch(); }
    @Test void updatesOwnProfileAndPublicWorkerResponseNeverLeaksIdentityFields() throws Exception {
        var request = body(); request.put("dateOfBirth", "1990-05-20"); request.put("fullName", "Tên mới");
        request.put("skills", List.of(" Xây ", "Xây", "Tô")); request.put("projectImages", List.of("https://example.com/project.jpg"));
        request.put("id", owner.getId()); request.put("role", "ROLE_ADMIN"); request.put("rating", 1); request.put("verified", true);
        update(request).andExpect(status().isOk()).andExpect(jsonPath("$.fullName").value("Tên mới"))
            .andExpect(jsonPath("$.dateOfBirth").value("1990-05-20")).andExpect(jsonPath("$.skills.length()").value(2))
            .andExpect(jsonPath("$.role").value("ROLE_WORKER")).andExpect(jsonPath("$.rating").value(5)).andExpect(jsonPath("$.verified").value(false));
        mvc.perform(get("/api/users/me").header("Authorization", token(worker))).andExpect(status().isOk())
            .andExpect(jsonPath("$.projectImages[0]").value("https://example.com/project.jpg"));
        mvc.perform(get("/api/workers/" + worker.getId() + "/profile").header("Authorization", token(owner)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.fullName").value("Tên mới"))
            .andExpect(jsonPath("$.skills[0]").value("Xây")).andExpect(jsonPath("$.dateOfBirth").doesNotExist())
            .andExpect(jsonPath("$.phoneNumber").doesNotExist()).andExpect(jsonPath("$.cccdFrontImage").doesNotExist());
        assertThat(users.findById(owner.getId()).orElseThrow().getFullName()).isEqualTo("Tên gốc");
        mvc.perform(get("/api/workers/" + owner.getId() + "/profile").header("Authorization", token(worker))).andExpect(status().isNotFound());
    }
    @Test void invalidBirthdayExperienceSkillsOrImagesCannotPartiallyChangeProfile() throws Exception {
        for (Map<String, Object> invalid : List.of(Map.<String,Object>of("dateOfBirth", "2099-01-01"), Map.<String,Object>of("experienceYears", -1),
            Map.<String,Object>of("skills", Collections.nCopies(21, "Xây")), Map.<String,Object>of("projectImages", List.of("http://example.com/photo.jpg")))) {
            var request = body(); request.put("fullName", "Không được lưu"); request.putAll(invalid);
            update(request).andExpect(status().isBadRequest());
            assertThat(users.findById(worker.getId()).orElseThrow().getFullName()).isEqualTo("Tên gốc");
        }
        mvc.perform(put("/api/users/me").contentType("application/json").content(json.writeValueAsString(body()))).andExpect(status().isUnauthorized());
    }
    @Test void changingIdentityRevokesKycButEditingOnlyExperienceKeepsIt() throws Exception {
        worker.setCccdFrontImage("https://example.com/front.jpg"); worker.setCccdBackImage("https://example.com/back.jpg"); worker.setVerified(true); users.saveAndFlush(worker);
        update(body()).andExpect(status().isOk()).andExpect(jsonPath("$.verified").value(true));
        var changed = body(); changed.put("fullName", "Tên đã đổi");
        update(changed).andExpect(status().isOk()).andExpect(jsonPath("$.verified").value(false));
        worker = users.findById(worker.getId()).orElseThrow(); worker.setVerified(true); users.saveAndFlush(worker);
        changed.put("dateOfBirth", "1990-01-01");
        update(changed).andExpect(status().isOk()).andExpect(jsonPath("$.verified").value(false));
    }
    private org.springframework.test.web.servlet.ResultActions update(Map<String,Object> body) throws Exception {
        return mvc.perform(put("/api/users/me").header("Authorization", token(worker)).contentType("application/json").content(json.writeValueAsString(body)));
    }
    private Map<String,Object> body() { var value = new HashMap<String,Object>(); value.put("fullName", "Tên gốc"); value.put("dateOfBirth", null); value.put("experienceYears", 5);
        value.put("experienceSummary", "Xây nhà phố"); value.put("skills", List.of("Xây")); value.put("projectImages", List.of()); return value; }
    private String token(User u) { return "Bearer " + jwt.generateToken(u.getPhoneNumber()); }
    private User user(String phone, Role role) { User u = new User(); u.setPhoneNumber(phone); u.setPassword("hash"); u.setFullName("Tên gốc"); u.setRole(role); return users.saveAndFlush(u); }
}
