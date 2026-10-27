package vn.thoxay;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.kyc.*;
import vn.thoxay.security.JwtUtil;
import vn.thoxay.admin.AdminService;
import com.fasterxml.jackson.databind.ObjectMapper;
import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;

@SpringBootTest @AutoConfigureMockMvc
class KycPhotosApiTest {
    @Autowired MockMvc mvc; @Autowired UserRepository users; @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications; @Autowired KycImageRepository images;
    @Autowired JwtUtil jwt; @Autowired ObjectMapper json;
    User worker, other, admin;
    @BeforeEach void setup() {
        clean(); worker = create("0977777701", Role.ROLE_WORKER); other = create("0977777702", Role.ROLE_CONTRACTOR); admin = create("0977777703", Role.ROLE_ADMIN);
    }
    @AfterEach void clean() { applications.deleteAllInBatch(); jobs.deleteAllInBatch(); users.deleteAllInBatch(); }

    @Test void uploadStoresPrivateImagesAndAdminCanReviewExactSnapshot() throws Exception {
        var result = upload(Color.BLUE, Color.RED);
        String front = result.get("cccdFrontImage").asText(), back = result.get("cccdBackImage").asText();
        assertThat(result.get("verified").asBoolean()).isFalse();
        assertThat(images.count()).isEqualTo(2);
        mvc.perform(get(front)).andExpect(status().isUnauthorized());
        mvc.perform(get(front).with(user(other.getPhoneNumber()).roles("CONTRACTOR"))).andExpect(status().isForbidden());
        mvc.perform(get(front).with(user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isOk())
            .andExpect(content().contentType("image/jpeg")).andExpect(header().string("Cache-Control", "no-store"));
        String own = front.replace("/admin/kyc/images/", "/api/users/me/cccd/images/");
        mvc.perform(get(own).header("Authorization", token(worker))).andExpect(status().isOk());
        mvc.perform(get(own).header("Authorization", token(other))).andExpect(status().isNotFound());
        mvc.perform(get(own)).andExpect(status().isUnauthorized());
        mvc.perform(post("/admin/users/" + worker.getId() + "/verify")
            .with(user(admin.getPhoneNumber()).roles("ADMIN")).with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf())
            .param("cccdFrontImage", front).param("cccdBackImage", back)).andExpect(status().is3xxRedirection());
        assertThat(users.findById(worker.getId()).orElseThrow().isVerified()).isTrue();
        var replacement = upload(Color.GREEN, Color.YELLOW);
        assertThat(replacement.get("verified").asBoolean()).isFalse();
        assertThat(images.count()).isEqualTo(2);
        mvc.perform(get(front).with(user(admin.getPhoneNumber()).roles("ADMIN"))).andExpect(status().isNotFound());
        mvc.perform(post("/admin/users/" + worker.getId() + "/verify")
            .with(user(admin.getPhoneNumber()).roles("ADMIN")).with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf())
            .param("cccdFrontImage", front).param("cccdBackImage", back)).andExpect(status().is3xxRedirection());
        assertThat(users.findById(worker.getId()).orElseThrow().isVerified()).isFalse();
    }

    @Test void invalidOrMissingFacesNeverOverwritePreviousSubmission() throws Exception {
        String front = upload(Color.BLUE, Color.RED).get("cccdFrontImage").asText();
        mvc.perform(multipart("/api/users/me/cccd/photos").file(photo("front", Color.GREEN))
            .file(new MockMultipartFile("back", "fake.jpg", "image/jpeg", "not-an-image".getBytes()))
            .header("Authorization", token(worker))).andExpect(status().isBadRequest());
        mvc.perform(multipart("/api/users/me/cccd/photos").file(photo("front", Color.GREEN))
            .header("Authorization", token(worker))).andExpect(status().isBadRequest());
        mvc.perform(multipart("/api/users/me/cccd/photos").file(photo("front", Color.GREEN)).file(photo("back", Color.GREEN))
            .header("Authorization", token(worker))).andExpect(status().isBadRequest());
        mvc.perform(multipart("/api/users/me/cccd/photos").file(new MockMultipartFile("front", new byte[5 * 1024 * 1024 + 1])).file(photo("back", Color.GREEN))
            .header("Authorization", token(worker))).andExpect(status().isPayloadTooLarge());
        assertThat(users.findById(worker.getId()).orElseThrow().getCccdFrontImage()).isEqualTo(front);
        assertThat(images.count()).isEqualTo(2);
    }

    @Test void uploadRequiresActiveAccountAndOwnerOrContractorRole() throws Exception {
        mvc.perform(multipart("/api/users/me/cccd/photos").file(photo("front", Color.BLUE)).file(photo("back", Color.RED)))
            .andExpect(status().isUnauthorized());
        mvc.perform(multipart("/api/users/me/cccd/photos").file(photo("front", Color.BLUE)).file(photo("back", Color.RED)).header("Authorization", token(admin)))
            .andExpect(status().isForbidden());
        other.setActive(false); users.saveAndFlush(other);
        mvc.perform(multipart("/api/users/me/cccd/photos").file(photo("front", Color.BLUE)).file(photo("back", Color.RED)).header("Authorization", token(other)))
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCOUNT_LOCKED"));
        assertThat(images.count()).isZero();
    }

    private com.fasterxml.jackson.databind.JsonNode upload(Color front, Color back) throws Exception {
        var result = mvc.perform(multipart("/api/users/me/cccd/photos").file(photo("front", front)).file(photo("back", back))
            .header("Authorization", token(worker))).andExpect(status().isOk()).andReturn();
        return json.readTree(result.getResponse().getContentAsString());
    }
    private MockMultipartFile photo(String face, Color color) throws Exception {
        var image = new BufferedImage(640, 400, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics(); g.setColor(color); g.fillRect(0, 0, 640, 400); g.dispose();
        var out = new ByteArrayOutputStream(); ImageIO.write(image, "png", out);
        return new MockMultipartFile(face, "../../untrusted.png", "text/plain", out.toByteArray());
    }
    private String token(User u) { return "Bearer " + jwt.generateToken(u.getPhoneNumber()); }
    private User create(String phone, Role role) { var u = new User(); u.setPhoneNumber(phone); u.setFullName("Test"); u.setPassword("hash"); u.setRole(role); return users.saveAndFlush(u); }
}
