package vn.thoxay;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import vn.thoxay.entity.*;
import vn.thoxay.repository.*;
import vn.thoxay.security.JwtUtil;
import vn.thoxay.wallet.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class RoleSwitchApiTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired WalletAccountRepository wallets;
    @Autowired JobPaymentRepository payments;
    @Autowired MessageRepository messages;
    @Autowired JwtUtil jwt;
    @Autowired ObjectMapper json;
    User worker, owner;
    @BeforeEach void setup() { worker=user("0977200011", Role.ROLE_WORKER); owner=user("0977200012", Role.ROLE_CONTRACTOR); }
    User user(String phone, Role role) { var u=new User(); u.setPhoneNumber(phone); u.setFullName("Role QA"); u.setPassword("hash"); u.setRole(role); return users.saveAndFlush(u); }
    String token(User u) { return jwt.generateToken(u.getPhoneNumber(), u.getSecurityVersion(), u.getId()); }
    org.springframework.test.web.servlet.ResultActions change(String token, String role) throws Exception {
        return mvc.perform(put("/api/users/me/settings/role").header("Authorization", "Bearer "+token).contentType("application/json").content(json.writeValueAsString(java.util.Map.of("role",role))));
    }
    Job job(JobStatus status) {
        var j=new Job(); j.setContractor(owner); j.setTitle("Role QA job"); j.setJobType("Thợ chính"); j.setAddress("QA"); j.setSalaryPerDay(450000); j.setLatitude(10); j.setLongitude(106); j.setRequiredWorkers(1); j.setStatus(status); return jobs.saveAndFlush(j);
    }
    JobApplication application(Job j, ApplicationStatus status) {
        var a=new JobApplication(); a.setJob(j); a.setWorker(worker); a.setStatus(status); if (j.getStatus()==JobStatus.COMPLETED) a.setWorkerRating(5); return applications.saveAndFlush(a);
    }
    @Test void swapsRoleWithSameAccountProfileAndWalletAndRevokesOldJwt() throws Exception {
        worker.setAvatarVersion(java.util.UUID.randomUUID()); worker.setCompletedJobs(5); worker.setExperienceYears(6); worker.setAvailable(true); users.saveAndFlush(worker);
        var version=worker.getAvatarVersion(); var wallet=new WalletAccount(); wallet.setUser(worker); wallet.setMainBalance(2450000); wallet.setEscrowBalance(200000); wallets.saveAndFlush(wallet);
        String old=token(worker);
        var response=change(old,"ROLE_CONTRACTOR").andExpect(status().isOk()).andExpect(jsonPath("$.userId").value(worker.getId())).andExpect(jsonPath("$.role").value("ROLE_CONTRACTOR")).andReturn();
        String fresh=json.readTree(response.getResponse().getContentAsString()).get("token").asText();
        assertThat(worker.getRole()).isEqualTo(Role.ROLE_CONTRACTOR); assertThat(worker.isAvailable()).isFalse(); assertThat(worker.getExperienceYears()).isEqualTo(6); assertThat(worker.getAvatarVersion()).isEqualTo(version);
        mvc.perform(get("/api/users/me").header("Authorization","Bearer "+old)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/wallet").header("Authorization","Bearer "+fresh)).andExpect(status().isOk()).andExpect(jsonPath("$.mainBalance").value(2450000)).andExpect(jsonPath("$.escrowBalance").value(200000));
        change(fresh,"ROLE_WORKER").andExpect(status().isOk()).andExpect(jsonPath("$.role").value("ROLE_WORKER"));
        assertThat(worker.getCompletedJobs()).isEqualTo(5); assertThat(worker.getWorkerTier()).isEqualTo(WorkerTier.GOLD);
    }
    @Test void pendingAcceptedAndOwnedOpenJobsBlockSwitchWithoutAnyMutation() throws Exception {
        var j=job(JobStatus.OPEN); var a=application(j,ApplicationStatus.PENDING); long version=worker.getSecurityVersion();
        change(token(worker),"ROLE_CONTRACTOR").andExpect(status().isConflict()); assertThat(worker.getSecurityVersion()).isEqualTo(version); assertThat(worker.getRole()).isEqualTo(Role.ROLE_WORKER);
        a.setStatus(ApplicationStatus.ACCEPTED); applications.saveAndFlush(a);
        change(token(worker),"ROLE_CONTRACTOR").andExpect(status().isConflict());
        change(token(owner),"ROLE_WORKER").andExpect(status().isConflict()); assertThat(owner.getRole()).isEqualTo(Role.ROLE_CONTRACTOR);
        a.setStatus(ApplicationStatus.REJECTED); j.setStatus(JobStatus.CANCELLED); applications.saveAndFlush(a); jobs.saveAndFlush(j);
        change(token(worker),"ROLE_CONTRACTOR").andExpect(status().isOk());
    }
    @Test void unsettledCompletedWorkBlocksBothSidesAndPaidHistoryRemainsReadableAfterSwitch() throws Exception {
        var j=job(JobStatus.COMPLETED); var a=application(j,ApplicationStatus.ACCEPTED);
        change(token(worker),"ROLE_CONTRACTOR").andExpect(status().isConflict()); change(token(owner),"ROLE_WORKER").andExpect(status().isConflict());
        var payment=new JobPayment(); payment.setApplication(a); payment.setJob(j); payment.setContractor(owner); payment.setWorker(worker); payment.setJobTitle(j.getTitle()); payment.setWorkDays(1); payment.setDailyRate(450000); payment.setBase(450000); payment.setTotal(450000); payments.saveAndFlush(payment);
        var message=new Message(); message.setJob(j); message.setSender(owner); message.setRecipient(worker); message.setContent("History"); message.setClientMessageId("role-history"); messages.saveAndFlush(message);
        var response=change(token(worker),"ROLE_CONTRACTOR").andExpect(status().isOk()).andReturn();
        String fresh=json.readTree(response.getResponse().getContentAsString()).get("token").asText();
        mvc.perform(get("/api/applications/worker/"+worker.getId()).header("Authorization","Bearer "+fresh)).andExpect(status().isOk()).andExpect(jsonPath("$[0].id").value(a.getId()));
        mvc.perform(get("/api/jobs/"+j.getId()+"/messages").param("peerId",owner.getId().toString()).header("Authorization","Bearer "+fresh)).andExpect(status().isOk());
        mvc.perform(get("/api/messages/unread").header("Authorization","Bearer "+fresh)).andExpect(status().isOk()).andExpect(jsonPath("$.unreadCount").value(1));
        assertThat(payments.findByApplicationId(a.getId())).isPresent();
    }
    @Test void cannotBecomeAdminCannotChangeOtherAccountAndSameRoleIsIdempotent() throws Exception {
        String token=token(worker); change(token,"ROLE_ADMIN").andExpect(status().isBadRequest());
        var admin=user("0977200013",Role.ROLE_ADMIN); change(token(admin),"ROLE_WORKER").andExpect(status().isForbidden());
        mvc.perform(put("/api/users/me/settings/role").contentType("application/json").content("{\"role\":\"ROLE_CONTRACTOR\"}")).andExpect(status().isUnauthorized());
        change(token,"ROLE_WORKER").andExpect(status().isOk()); assertThat(worker.getSecurityVersion()).isZero(); assertThat(owner.getRole()).isEqualTo(Role.ROLE_CONTRACTOR);
    }
}
