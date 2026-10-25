package vn.thoxay.repository;

import vn.thoxay.entity.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest(properties = {"spring.jpa.hibernate.ddl-auto=create-drop", "spring.sql.init.mode=never"})
class RepositoryTest {
    @Autowired UserRepository users;
    @Autowired JobRepository jobs;

    @Test void haversineIncludesNearbyOpenJobsOnly() {
        User owner = new User();
        owner.setPhoneNumber("0901234567"); owner.setPassword("hash");
        owner.setFullName("Chủ thầu"); owner.setRole(Role.ROLE_CONTRACTOR);
        users.save(owner);
        Job near = job(owner, 10.7769, 106.7009, JobStatus.OPEN);
        jobs.save(near);
        jobs.save(job(owner, 21.0285, 105.8542, JobStatus.OPEN));
        jobs.save(job(owner, 10.7769, 106.7009, JobStatus.COMPLETED));
        assertThat(jobs.findNearby(10.7769, 106.7009, 10)).extracting(Job::getId).containsExactly(near.getId());
        assertThat(jobs.findNearby(10.7769, 106.7009, 0)).hasSize(1);
    }

    @Test void demoPasswordHashIsValid() {
        assertThat(new BCryptPasswordEncoder().matches("password",
          "$2a$10$ujHVMiRDJR3OBm5yXjsRS.XF8NDGIFPgFIdRQDpYcVr/MUAvSILda")).isTrue();
    }

    private Job job(User owner, double lat, double lng, JobStatus status) {
        Job j = new Job(); j.setContractor(owner); j.setTitle("Công trình");
        j.setJobType("Phụ hồ"); j.setSalaryPerDay(300000); j.setAddress("TP.HCM");
        j.setLatitude(lat); j.setLongitude(lng); j.setRequiredWorkers(2); j.setStatus(status);
        return j;
    }
}
