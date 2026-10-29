package vn.thoxay;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
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
    @Autowired BCryptPasswordEncoder encoder;
    User admin, worker;
    @BeforeEach void setup() {
        admin = user("0944444441", Role.ROLE_ADMIN);
        worker = user("0944444442", Role.ROLE_WORKER);
        worker.setCccdFrontImage("https://example.com/front.jpg");
        worker.setCccdBackImage("https://example.com/back.jpg"); users.saveAndFlush(worker);
    }
    @Test void anonymousCanSeeLoginButCannotSeeDashboard() throws Exception {
        mvc.perform(get("/admin/login")).andExpect(status().isOk()).andExpect(content().string(containsString("Số điện thoại quản trị")));
        mvc.perform(get("/admin/dashboard")).andExpect(status().is3xxRedirection());
    }
    @Test void missingOrInvalidLoginCsrfReturnsToFreshForm() throws Exception {
        mvc.perform(post("/admin/login"))
            .andExpect(status().is3xxRedirection())
            .andExpect(redirectedUrl("/admin/login?expired"));
        mvc.perform(post("/admin/login").with(csrf().useInvalidToken()))
            .andExpect(status().is3xxRedirection())
            .andExpect(redirectedUrl("/admin/login?expired"));
        mvc.perform(get("/admin/login?expired"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("Phiên đăng nhập đã hết hạn")))
            .andExpect(content().string(containsString("name=\"_csrf\"")));
    }
    @Test void freshAdminLoginOpensDashboard() throws Exception {
        admin.setPassword(encoder.encode("test-admin-password"));
        users.saveAndFlush(admin);
        var login = mvc.perform(post("/admin/login").with(csrf())
                .param("phoneNumber", admin.getPhoneNumber()).param("password", "test-admin-password"))
            .andExpect(status().is3xxRedirection())
            .andExpect(redirectedUrl("/admin/dashboard")).andReturn();
        mvc.perform(get("/admin/dashboard").session((MockHttpSession) login.getRequest().getSession(false)))
            .andExpect(status().isOk());
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
            .andExpect(content().string(containsString("id=\"stat-total-users\">3</strong>")))
            .andExpect(content().string(containsString("id=\"stat-open-jobs\">1</strong>")))
            .andExpect(content().string(containsString("id=\"stat-kyc-rate\">0%</strong>")))
            .andExpect(content().string(not(containsString("/admin/users/" + admin.getId() + "/toggle-active"))))
            .andExpect(content().string(containsString("/admin/users/" + worker.getId() + "/toggle-active")))
            .andExpect(content().string(containsString("data-bs-target=\"#kyc-modal\"")))
            .andExpect(content().string(containsString("id=\"kyc-front-image\"")))
            .andExpect(content().string(containsString("id=\"kyc-back-image\"")))
            .andExpect(content().string(containsString("Xác thực danh tính")))
            .andExpect(content().string(not(containsString("target=\"_blank\""))));
        mvc.perform(post("/admin/users/" + worker.getId() + "/verify")).andExpect(status().isForbidden());
        mvc.perform(post("/admin/users/" + worker.getId() + "/verify").with(csrf())
            .param("cccdFrontImage", worker.getCccdFrontImage())
            .param("cccdBackImage", worker.getCccdBackImage())).andExpect(status().is3xxRedirection());
        assertThat(users.findById(worker.getId()).orElseThrow().isVerified()).isTrue();
        mvc.perform(get("/admin/dashboard")).andExpect(status().isOk())
            .andExpect(content().string(containsString("id=\"stat-kyc-rate\">33%</strong>")));
        mvc.perform(post("/admin/users/" + worker.getId() + "/toggle-active").with(csrf())).andExpect(status().is3xxRedirection());
        assertThat(users.findById(worker.getId()).orElseThrow().isActive()).isFalse();
        mvc.perform(post("/admin/users/" + worker.getId() + "/toggle-active").with(csrf())).andExpect(status().is3xxRedirection());
        assertThat(users.findById(worker.getId()).orElseThrow().isActive()).isTrue();
        mvc.perform(post("/admin/users/" + admin.getId() + "/toggle-active").with(csrf()))
            .andExpect(flash().attributeExists("error"));
        mvc.perform(post("/admin/jobs/" + job.getId() + "/delete").with(csrf())).andExpect(status().is3xxRedirection());
        assertThat(jobs.existsById(job.getId())).isFalse(); assertThat(applications.existsById(application.getId())).isFalse();
    }
    @Test void emptyDashboardHasZeroVerificationRate() {
        var dashboard = new vn.thoxay.admin.AdminService.Dashboard(java.util.List.of(), java.util.List.of(), 0, 0, 0);
        assertThat(dashboard.verificationRate()).isZero();
        assertThat(dashboard.verifiedUsers()).isZero();
    }
    @Test @WithMockUser(username = "0944444441", roles = "ADMIN")
    void adminCanInspectCommitmentPageWithoutSigningForParticipants() throws Exception {
        var owner=user("0944444443",Role.ROLE_CONTRACTOR);
        var job=new Job(); job.setContractor(owner); job.setTitle("Lịch công trình QA"); job.setJobType("Phụ hồ");
        job.setAddress("QA"); job.setSalaryPerDay(300000); job.setRequiredWorkers(1); jobs.saveAndFlush(job);
        mvc.perform(get("/admin/jobs/"+job.getId()+"/commitments")).andExpect(status().isOk())
            .andExpect(content().string(containsString("Cam kết và lương công trình")));
        mvc.perform(get("/admin/dashboard")).andExpect(status().isOk())
            .andExpect(content().string(containsString("/admin/jobs/"+job.getId()+"/commitments")));
    }
    private User user(String phone, Role role) {
        User u = new User(); u.setPhoneNumber(phone); u.setPassword("hash"); u.setFullName("Tài khoản quản trị thử");
        u.setRole(role); return users.saveAndFlush(u);
    }
}
