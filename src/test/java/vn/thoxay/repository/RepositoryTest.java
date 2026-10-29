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
    @Autowired vn.thoxay.wallet.WalletEntryRepository entries;

    @Test void incomeDateProjectionKeepsVietnamCalendarDateInAnyJvmTimezone() {
        User worker=new User();worker.setPhoneNumber("0009998877665");worker.setPassword("QA");worker.setFullName("Income timezone QA");worker.setRole(Role.ROLE_WORKER);users.saveAndFlush(worker);
        var entry=new vn.thoxay.wallet.WalletEntry();entry.setUser(worker);entry.setKind("WORK_EARNING");entry.setAmount(600000);
        entry.setReference("qa-timezone-income");entry.setDescription("Timezone fixture");entry.setCreatedAt(java.time.Instant.parse("2026-01-04T17:00:00Z"));entries.saveAndFlush(entry);
        var rows=entries.daily(worker.getId(),java.time.Instant.parse("2026-01-04T17:00:00Z"),java.time.Instant.parse("2026-01-05T17:00:00Z"));
        assertThat(rows).hasSize(1);
        assertThat(rows.get(0).getIncomeDay()).isEqualTo(java.time.LocalDate.of(2026,1,5));
        assertThat(rows.get(0).getBase()).isEqualTo(600000);
    }

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
