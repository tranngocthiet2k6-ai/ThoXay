package vn.thoxay;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.media.UserAvatarRepository;
import vn.thoxay.security.JwtUtil;
import java.awt.image.BufferedImage;
import java.io.*;
import javax.imageio.ImageIO;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class UserAvatarApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired UserAvatarRepository avatars;
    @Autowired JwtUtil jwt;
    @Autowired ObjectMapper json;
    User worker, other;
    @BeforeEach void setup() { worker = user("0977000011", Role.ROLE_WORKER); other = user("0977000012", Role.ROLE_CONTRACTOR); }
    User user(String phone, Role role) {
        User u = new User(); u.setPhoneNumber(phone); u.setFullName("Avatar QA"); u.setPassword("hash"); u.setRole(role);
        u.setCccdFrontImage("https://example.com/front.jpg"); u.setCccdBackImage("https://example.com/back.jpg"); u.setVerified(true);
        return users.saveAndFlush(u);
    }
    String token(User u) { return "Bearer " + jwt.generateToken(u.getPhoneNumber()); }
    MockMultipartFile photo(int size) throws Exception {
        var image = new BufferedImage(size, size, BufferedImage.TYPE_INT_RGB); var bytes = new ByteArrayOutputStream();
        ImageIO.write(image, "png", bytes); return new MockMultipartFile("photo", "avatar.png", "image/png", bytes.toByteArray());
    }
    org.springframework.test.web.servlet.ResultActions upload(User u, MockMultipartFile image) throws Exception {
        return mvc.perform(multipart("/api/users/me/avatar").file(image).with(request -> { request.setMethod("PUT"); return request; })
            .header("Authorization", token(u)).param("userId", other.getId().toString()));
    }
    @Test void sanitizedAvatarBelongsOnlyToCurrentUserAndDoesNotRevokeKyc() throws Exception {
        upload(worker, photo(900)).andExpect(status().isOk()).andExpect(jsonPath("$.verified").value(true))
            .andExpect(jsonPath("$.avatarUrl").value(org.hamcrest.Matchers.startsWith("/api/users/" + worker.getId() + "/avatar?v=")));
        assertThat(avatars.findByUserId(worker.getId())).isPresent(); assertThat(avatars.findByUserId(other.getId())).isEmpty();
        byte[] bytes = mvc.perform(get("/api/users/" + worker.getId() + "/avatar").header("Authorization", token(other)))
            .andExpect(status().isOk()).andExpect(content().contentType("image/jpeg"))
            .andExpect(header().string("X-Content-Type-Options", "nosniff")).andReturn().getResponse().getContentAsByteArray();
        assertThat(ImageIO.read(new ByteArrayInputStream(bytes)).getWidth()).isEqualTo(640);
        assertThat(bytes[0] & 255).isEqualTo(255); assertThat(bytes[1] & 255).isEqualTo(216);
    }
    @Test void replacingAvatarKeepsOneRowAndChangesVersionToRefreshClients() throws Exception {
        upload(worker, photo(256)).andExpect(status().isOk()); var first = worker.getAvatarVersion();
        upload(worker, photo(300)).andExpect(status().isOk());
        assertThat(worker.getAvatarVersion()).isNotEqualTo(first);
        assertThat(avatars.findAll().stream().filter(a -> a.getUser().getId().equals(worker.getId())).count()).isEqualTo(1);
        mvc.perform(get("/api/users/me").header("Authorization", token(worker))).andExpect(jsonPath("$.avatarUrl").value(worker.avatarUrl()));
    }
    @Test void invalidTinyOrOversizedImagesCannotChangeExistingAvatar() throws Exception {
        upload(worker, photo(256)).andExpect(status().isOk()); var version = worker.getAvatarVersion();
        upload(worker, new MockMultipartFile("photo", "bad.jpg", "image/jpeg", "not an image".getBytes())).andExpect(status().isBadRequest());
        upload(worker, photo(16)).andExpect(status().isBadRequest());
        upload(worker, new MockMultipartFile("photo", "big.jpg", "image/jpeg", new byte[5*1024*1024+1])).andExpect(status().isPayloadTooLarge());
        assertThat(worker.getAvatarVersion()).isEqualTo(version);
    }
    @Test void avatarRequiresAuthenticationAndInactiveTargetsAreHidden() throws Exception {
        mvc.perform(multipart("/api/users/me/avatar").file(photo(256)).with(request -> { request.setMethod("PUT"); return request; })).andExpect(status().isUnauthorized());
        upload(worker, photo(256)).andExpect(status().isOk()); worker.setActive(false); users.saveAndFlush(worker);
        mvc.perform(get("/api/users/" + worker.getId() + "/avatar").header("Authorization", token(other))).andExpect(status().isNotFound());
        upload(worker, photo(256)).andExpect(status().isForbidden());
    }
    @Test void administratorCannotCreatePublicAvatar() throws Exception {
        User admin = user("0977000013", Role.ROLE_ADMIN);
        upload(admin, photo(256)).andExpect(status().isForbidden());
        assertThat(avatars.findByUserId(admin.getId())).isEmpty();
    }
}
