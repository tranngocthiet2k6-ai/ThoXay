package vn.thoxay;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.UserRepository;
import vn.thoxay.security.JwtUtil;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class JobApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JwtUtil jwt;
    private final String request = """
        {"title":"Xây nhà phố","description":"Bao cơm trưa","jobType":"Thợ chính",
        "salaryPerDay":500000,"address":"Quận 1","latitude":10.7769,"longitude":106.7009,"requiredWorkers":2}
        """;

    @Test void contractorCreatesAndWorkerFindsJobWithDistance() throws Exception {
        User owner = user("0922222221", Role.ROLE_CONTRACTOR);
        User worker = user("0922222222", Role.ROLE_WORKER);
        mvc.perform(post("/api/jobs").header("Authorization", token(owner)).contentType("application/json").content(request))
            .andExpect(status().isCreated()).andExpect(jsonPath("contractorId").value(owner.getId()))
            .andExpect(jsonPath("status").value("OPEN"));
        mvc.perform(get("/api/jobs/nearby?lat=10.7769&lng=106.7009&radius=10").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$[0].title").value("Xây nhà phố"))
            .andExpect(jsonPath("$[0].distanceKm").value(0.0));
        mvc.perform(get("/api/jobs/nearby?lat=21&lng=105&radius=10").header("Authorization", token(worker)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(get("/api/jobs/contractor/" + owner.getId()).header("Authorization", token(owner)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1));
    }

    @Test void enforcesRoleOwnershipValidationAndDisablesExistingToken() throws Exception {
        User owner = user("0922222223", Role.ROLE_CONTRACTOR);
        User other = user("0922222224", Role.ROLE_CONTRACTOR);
        User worker = user("0922222225", Role.ROLE_WORKER);
        mvc.perform(post("/api/jobs").header("Authorization", token(worker)).contentType("application/json").content(request))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/jobs/contractor/" + owner.getId()).header("Authorization", token(other)))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/jobs").header("Authorization", token(owner)).contentType("application/json")
            .content(request.replace("500000", "-1"))).andExpect(status().isBadRequest());
        mvc.perform(get("/api/jobs/nearby?lat=91&lng=106&radius=10").header("Authorization", token(worker)))
            .andExpect(status().isBadRequest());
        String existingToken = token(worker); worker.setActive(false); users.saveAndFlush(worker);
        mvc.perform(get("/api/jobs/nearby?lat=10&lng=106").header("Authorization", existingToken))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("code").value("ACCOUNT_LOCKED"))
            .andExpect(jsonPath("message").value(vn.thoxay.exception.AccountLockedException.MESSAGE));
    }

    private String token(User user) { return "Bearer " + jwt.generateToken(user.getPhoneNumber()); }
    private User user(String phone, Role role) {
        User user = new User(); user.setPhoneNumber(phone); user.setPassword("hash");
        user.setFullName("Tài khoản thử"); user.setRole(role); return users.saveAndFlush(user);
    }
}
