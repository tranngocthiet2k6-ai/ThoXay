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
import java.time.LocalDate;
import java.util.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @Transactional
class JobStaffingUpdateTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;
    @Autowired JobApplicationRepository applications;
    @Autowired JwtUtil jwt;
    User owner;
    Job job;

    @BeforeEach void setup() {
        owner = user("0988888851", Role.ROLE_CONTRACTOR);
        job = new Job(); job.setContractor(owner); job.setTitle("Xây tường"); job.setDescription("Công trình QA");
        job.setJobType("Thợ chính, Phụ hồ"); job.setSalaryPerDay(250000); job.setAddress("Công trường QA");
        job.setLatitude(10); job.setLongitude(106); job.setRequiredWorkers(5); job.setSkilledWorkers(2); job.setHelpers(3);
        job.setStartsOn(LocalDate.now().plusDays(1)); job.setEndsOn(LocalDate.now().plusDays(2));
        jobs.saveAndFlush(job);
        for (String phone : List.of("0988888852", "0988888853")) {
            var a = new JobApplication(); a.setJob(job); a.setWorker(user(phone, Role.ROLE_WORKER));
            a.setStatus(ApplicationStatus.ACCEPTED); a.setAgreedDailyRate(250000L); a.setConsentVersion(1);
            a.setContractSnapshot("Cam kết đã chốt"); a.setContractHash("frozen"); applications.saveAndFlush(a);
        }
    }

    @Test void canReduceStaffingToAcceptedCountWithoutChangingFrozenTerms() throws Exception {
        var body = input(1,1);
        mvc.perform(put("/api/jobs/" + job.getId()).header("Authorization", token(owner))
            .contentType("application/json").content(json.writeValueAsString(body)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.requiredWorkers").value(2))
            .andExpect(jsonPath("$.status").value("IN_PROGRESS")).andExpect(jsonPath("$.termsVersion").value(1));
        for (var a : applications.findByJobIdOrderByAppliedAtDesc(job.getId())) {
            assertThat(a.getAgreedDailyRate()).isEqualTo(250000L);
            assertThat(a.getContractSnapshot()).isEqualTo("Cam kết đã chốt");
            assertThat(a.getContractHash()).isEqualTo("frozen");
        }
    }

    @Test void existingPastStartDateDoesNotBlockStaffingOnlyUpdate() throws Exception {
        job.setStartsOn(LocalDate.now().minusDays(1)); jobs.saveAndFlush(job);
        canReduceStaffingToAcceptedCountWithoutChangingFrozenTerms();
    }

    @Test void cannotReduceBelowTwoAcceptedWorkers() throws Exception {
        mvc.perform(put("/api/jobs/" + job.getId()).header("Authorization",token(owner))
            .contentType("application/json").content(json.writeValueAsString(input(1,0))))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.message").value("Đã nhận 2 thợ. Tổng số cần tuyển phải ít nhất 2 người"));
        assertThat(jobs.findById(job.getId()).orElseThrow().getRequiredWorkers()).isEqualTo(5);
    }

    @Test void startedJobCanAddRecruitmentSlotsAndExistingConsentRemainsValid() throws Exception {
        job.setStatus(JobStatus.IN_PROGRESS); jobs.saveAndFlush(job);
        mvc.perform(put("/api/jobs/" + job.getId()).header("Authorization",token(owner))
            .contentType("application/json").content(json.writeValueAsString(input(3,4))))
            .andExpect(status().isOk()).andExpect(jsonPath("$.requiredWorkers").value(7))
            .andExpect(jsonPath("$.status").value("IN_PROGRESS")).andExpect(jsonPath("$.termsVersion").value(1));
    }

    @Test void staffingUpdateCannotAlsoChangePayDatesLocationOrWorkDescription() throws Exception {
        for (var change : Map.of("salaryPerDay",(Object)500000,"description","Đổi việc","latitude",11,
                "startsOn",LocalDate.now().plusDays(2)).entrySet()) {
            var body = input(1,1); body.put(change.getKey(),change.getValue());
            mvc.perform(put("/api/jobs/" + job.getId()).header("Authorization",token(owner))
                .contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().isConflict());
        }
        assertThat(job.getRequiredWorkers()).isEqualTo(5);
        assertThat(job.getSalaryPerDay()).isEqualTo(250000);
    }

    @Test void stoppedOrCompletedJobCannotChangeStaffing() throws Exception {
        job.setRecruitmentClosed(true); jobs.saveAndFlush(job);
        mvc.perform(put("/api/jobs/" + job.getId()).header("Authorization",token(owner))
            .contentType("application/json").content(json.writeValueAsString(input(1,1)))).andExpect(status().isConflict());
        job.setRecruitmentClosed(false); job.setStatus(JobStatus.COMPLETED); jobs.saveAndFlush(job);
        mvc.perform(put("/api/jobs/" + job.getId()).header("Authorization",token(owner))
            .contentType("application/json").content(json.writeValueAsString(input(1,1)))).andExpect(status().isConflict());
    }

    private Map<String,Object> input(int skilled,int helpers) {
        var body = new LinkedHashMap<String,Object>();
        body.put("title",job.getTitle()); body.put("description",job.getDescription());
        body.put("jobType",skilled > 0 ? (helpers > 0 ? "Thợ chính, Phụ hồ" : "Thợ chính") : "Phụ hồ");
        body.put("salaryPerDay",job.getSalaryPerDay()); body.put("address",job.getAddress());
        body.put("latitude",job.getLatitude()); body.put("longitude",job.getLongitude());
        body.put("requiredWorkers",skilled+helpers); body.put("skilledWorkers",skilled); body.put("helpers",helpers);
        body.put("startsOn",job.getStartsOn()); body.put("endsOn",job.getEndsOn());
        return body;
    }
    private User user(String phone,Role role) {
        var u = new User(); u.setPhoneNumber(phone); u.setFullName("Staffing QA"); u.setPassword("hash"); u.setRole(role);
        return users.saveAndFlush(u);
    }
    private String token(User u) { return "Bearer " + jwt.generateToken(u.getPhoneNumber()); }
}
