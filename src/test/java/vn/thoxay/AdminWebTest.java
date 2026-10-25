package vn.thoxay;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class AdminWebTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    User admin, worker;
    @BeforeEach void setup() {
        admin = user("0944444441", Role.ROLE_ADMIN);
        worker = user("0944444442", Role.ROLE_WORKER);
        worker.setCccdImage("https://example.com/identity.jpg"); users.saveAndFlush(worker);
    }
    @Test void anonymousCanSeeLoginButCannotSeeDashboard() throws Exception {
        mvc.perform(get("/admin/login")).andExpect(status().isOk()).andExpect(content().string(containsString("Số điện thoại quản trị")));
        mvc.perform(get("/admin/dashboard")).andExpect(status().is3xxRedirection());
    }
    @Test @WithMockUser(username = "0944444442", roles = "WORKER")
    void workersCannotManageUsers() throws Exception {
        mvc.perform(get("/admin/dashboard")).andExpect(status().isForbidden());
        mvc.perform(post("/admin/users/" + worker.getId() + "/verify").with(csrf())).andExpect(status().isForbidden());
    }
    @Test @WithMockUser(username = "0944444441", roles = "ADMIN")
    void adminCanRenderVerifyLockUnlockAndDeleteButNeedsCsrf() throws Exception {
        User owner = user("0944444443", Role.ROLE_CONTRACTOR);
        Job job = new Job(); job.setContractor(owner); job.setTitle("Công trình vi phạm"); job.setJobType("Phụ hồ");
        job.setSalaryPerDay(300000); job.setAddress("TP.HCM"); job.setRequiredWorkers(1); jobs.saveAndFlush(job);
        JobApplication application = new JobApplication(); application.setJob(job); application.setWorker(worker); applications.saveAndFlush(application);
        mvc.perform(get("/admin/dashboard")).andExpect(status().isOk()).andExpect(content().string(containsString("Công trình vi phạm")))
            .andExpect(content().string(not(containsString("/admin/users/" + admin.getId() + "/toggle-active"))))
            .andExpect(content().string(containsString("/admin/users/" + worker.getId() + "/toggle-active")));
        mvc.perform(post("/admin/users/" + worker.getId() + "/verify")).andExpect(status().isForbidden());
        mvc.perform(post("/admin/users/" + worker.getId() + "/verify").with(csrf())).andExpect(status().is3xxRedirection());
        assertThat(users.findById(worker.getId()).orElseThrow().isVerified()).isTrue();
        mvc.perform(post("/admin/users/" + worker.getId() + "/toggle-active").with(csrf())).andExpect(status().is3xxRedirection());
        assertThat(users.findById(worker.getId()).orElseThrow().isActive()).isFalse();
        mvc.perform(post("/admin/users/" + worker.getId() + "/toggle-active").with(csrf())).andExpect(status().is3xxRedirection());
        assertThat(users.findById(worker.getId()).orElseThrow().isActive()).isTrue();
        mvc.perform(post("/admin/users/" + admin.getId() + "/toggle-active").with(csrf()))
            .andExpect(flash().attributeExists("error"));
        mvc.perform(post("/admin/jobs/" + job.getId() + "/delete").with(csrf())).andExpect(status().is3xxRedirection());
        assertThat(jobs.existsById(job.getId())).isFalse(); assertThat(applications.existsById(application.getId())).isFalse();
    }
    private User user(String phone, Role role) {
        User u = new User(); u.setPhoneNumber(phone); u.setPassword("hash"); u.setFullName("Tài khoản quản trị thử");
        u.setRole(role); return users.saveAndFlush(u);
    }
}
