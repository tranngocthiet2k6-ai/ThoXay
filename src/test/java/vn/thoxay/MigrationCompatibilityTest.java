package vn.thoxay;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import java.sql.*;
import java.util.UUID;
import static org.assertj.core.api.Assertions.assertThat;

/** Isolated schemas in a dedicated PostgreSQL QA database; never the running app DB. */
@EnabledIfEnvironmentVariable(named = "THOXAY_PG_TEST_URL", matches = ".+")
class MigrationCompatibilityTest {
    String schema;
    String url() { return System.getenv("THOXAY_PG_TEST_URL"); }
    Connection connect() throws SQLException {
        return DriverManager.getConnection(url(), System.getenv().getOrDefault("THOXAY_PG_TEST_USER", "postgres"),
            System.getenv().getOrDefault("THOXAY_PG_TEST_PASSWORD", "postgres"));
    }
    Flyway migrations() {
        return Flyway.configure().dataSource(url(), System.getenv().getOrDefault("THOXAY_PG_TEST_USER", "postgres"),
            System.getenv().getOrDefault("THOXAY_PG_TEST_PASSWORD", "postgres"))
            .schemas(schema).defaultSchema(schema).baselineOnMigrate(true).baselineVersion("11")
            .cleanDisabled(true).locations("classpath:db/migration").load();
    }
    @BeforeEach void isolate() throws Exception {
        assertThat(url()).contains("thoxay_upgrade_qa");
        schema = "qa_" + UUID.randomUUID().toString().replace("-", "");
        try (var c = connect(); var s = c.createStatement()) { s.execute("CREATE SCHEMA " + schema); }
    }
    @AfterEach void removeOwnSchema() throws Exception {
        if (schema == null || !schema.matches("qa_[a-f0-9]{32}")) return;
        try (var c = connect(); var s = c.createStatement()) { s.execute("DROP SCHEMA " + schema + " CASCADE"); }
    }
    @Test void freshDatabaseMigratesAndSecondRunDoesNothing() throws Exception {
        assertThat(migrations().migrate().migrationsExecuted).isGreaterThanOrEqualTo(1);
        assertThat(migrations().migrate().migrationsExecuted).isZero();
        try (var c = connect(); var s = c.createStatement();
             var r = s.executeQuery("SELECT count(*) FROM " + schema + ".users")) {
            r.next(); assertThat(r.getLong(1)).isZero();
        }
        assertThat(migrations().validateWithResult().validationSuccessful).isTrue();
    }
    @Test void checkoutUpgradePreservesExistingTimesAndCanBeRepeated() throws Exception {
        Flyway.configure().configuration(migrations().getConfiguration()).target("29").load().migrate();
        try(var c=connect();var s=c.createStatement()) {
            c.setSchema(schema);
            s.executeUpdate("INSERT INTO users(phone_number,password,full_name,role) VALUES ('0999999901','qa-hash','Owner','ROLE_CONTRACTOR'),('0999999902','qa-hash','Worker','ROLE_WORKER')");
            s.executeUpdate("INSERT INTO jobs(contractor_id,title,job_type,salary_per_day,address,latitude,longitude,required_workers) SELECT id,'QA shift','Thợ chính',350000,'QA',10,106,1 FROM users WHERE role='ROLE_CONTRACTOR'");
            s.executeUpdate("INSERT INTO job_applications(job_id,worker_id,status) SELECT j.id,u.id,'ACCEPTED' FROM jobs j,users u WHERE u.role='ROLE_WORKER'");
            s.executeUpdate("INSERT INTO attendance_records(application_id,work_day,checked_in_at,checked_out_at,checkin_method,checkout_method) SELECT id,'2030-03-01','2030-03-01T01:00:00Z','2030-03-01T09:00:00Z','GPS','QR' FROM job_applications");
        }
        migrations().migrate();
        try(var c=connect()) {
            c.setSchema(schema);
            ScriptUtils.executeSqlScript(c,new ClassPathResource("db/migration/V30__attendance_checkout_corrections.sql"));
            ScriptUtils.executeSqlScript(c,new ClassPathResource("db/migration/V30__attendance_checkout_corrections.sql"));
            try(var s=c.createStatement();var r=s.executeQuery("SELECT checked_out_at,checkout_method,version,latest_correction_id FROM attendance_records")) {
                assertThat(r.next()).isTrue();
                assertThat(r.getTimestamp(1).toInstant()).isEqualTo(java.time.Instant.parse("2030-03-01T09:00:00Z"));
                assertThat(r.getString(2)).isEqualTo("QR");assertThat(r.getLong(3)).isZero();assertThat(r.getObject(4)).isNull();
            }
            try(var s=c.createStatement()) { assertThat(s.executeUpdate("UPDATE attendance_records SET checkout_method='ADJUSTED'")).isEqualTo(1); }
        }
        assertThat(migrations().migrate().migrationsExecuted).isZero();
    }
    @Test void legacyUnpaidCompletionReturnsToInProgressWithoutChangingMoneyOrRepeatingMigration()throws Exception {
        Flyway.configure().configuration(migrations().getConfiguration()).target("30").load().migrate();
        try(var c=connect();var s=c.createStatement()) {
            c.setSchema(schema);
            s.executeUpdate("INSERT INTO users(phone_number,password,full_name,role,rating,completed_jobs,reputation_score,worker_tier) VALUES ('0999999981','hash','Owner','ROLE_CONTRACTOR',5,0,100,'BRONZE'),('0999999982','hash','Worker','ROLE_WORKER',3,2,80,'SILVER')");
            s.executeUpdate("INSERT INTO jobs(contractor_id,title,job_type,salary_per_day,address,latitude,longitude,required_workers,status) SELECT u.id,v.title,'Thợ chính',250000,'QA',10,106,1,'COMPLETED' FROM users u CROSS JOIN (VALUES ('legacy-paid'),('legacy-unpaid')) v(title) WHERE u.role='ROLE_CONTRACTOR'");
            s.executeUpdate("INSERT INTO job_applications(job_id,worker_id,status,worker_rating,reviewed_at) SELECT j.id,u.id,'ACCEPTED',CASE WHEN j.title='legacy-paid' THEN 4 ELSE 2 END,'2030-03-01T09:00:00Z' FROM jobs j,users u WHERE u.role='ROLE_WORKER'");
            s.executeUpdate("INSERT INTO job_payments(application_id,job_id,contractor_id,worker_id,job_title,work_days,daily_rate,base,tip,bonus,total) SELECT a.id,j.id,j.contractor_id,a.worker_id,j.title,1,250000,250000,0,0,250000 FROM job_applications a JOIN jobs j ON j.id=a.job_id WHERE j.title='legacy-paid'");
        }
        migrations().migrate();
        try(var c=connect()) {
            c.setSchema(schema);
            for(int i=0;i<2;i++) ScriptUtils.executeSqlScript(c,new ClassPathResource("db/migration/V31__complete_only_after_payment.sql"));
            try(var s=c.createStatement();var r=s.executeQuery("SELECT title,status,ratings_finalized_at FROM jobs ORDER BY title")) {
                assertThat(r.next()).isTrue();assertThat(r.getString(2)).isEqualTo("COMPLETED");assertThat(r.getTimestamp(3)).isNotNull();
                assertThat(r.next()).isTrue();assertThat(r.getString(2)).isEqualTo("IN_PROGRESS");assertThat(r.getTimestamp(3)).isNotNull();
            }
            try(var s=c.createStatement();var r=s.executeQuery("SELECT rating,completed_jobs,reputation_score,worker_tier FROM users WHERE role='ROLE_WORKER'")) {
                assertThat(r.next()).isTrue();assertThat(r.getDouble(1)).isEqualTo(4);assertThat(r.getInt(2)).isEqualTo(1);
                assertThat(r.getInt(3)).isEqualTo(80);assertThat(r.getString(4)).isEqualTo("SILVER");
            }
            try(var s=c.createStatement();var r=s.executeQuery("SELECT COUNT(*),SUM(total) FROM job_payments")) {
                assertThat(r.next()).isTrue();assertThat(r.getInt(1)).isEqualTo(1);assertThat(r.getLong(2)).isEqualTo(250000);
            }
            try(var s=c.createStatement();var r=s.executeQuery("SELECT COUNT(*) FROM job_applications WHERE paid_at IS NOT NULL")) {
                assertThat(r.next()).isTrue();assertThat(r.getInt(1)).isEqualTo(1);
            }
        }
    }
    @Test void adoptsLegacySchemaWithoutChangingExistingUser() throws Exception {
        try (var c = connect()) {
            c.setSchema(schema);
            ScriptUtils.executeSqlScript(c, new ClassPathResource("db/migration/V1__initial_schema.sql"));
            try (var s = c.createStatement()) {
                s.executeUpdate("INSERT INTO users(phone_number,password,full_name,role,is_verified,rating,is_active,created_at) "
                    + "VALUES('0999999911','qa-bcrypt-placeholder','Legacy QA worker','ROLE_WORKER',false,4.5,true,CURRENT_TIMESTAMP)");
            }
        }
        migrations().migrate();
        try (var c = connect(); var s = c.createStatement(); var r = s.executeQuery(
                "SELECT role,rating,password,security_version,job_push_enabled,chat_push_enabled,avatar_version,worker_tier FROM " + schema + ".users WHERE phone_number='0999999911'")) {
            assertThat(r.next()).isTrue(); assertThat(r.getString(1)).isEqualTo("ROLE_WORKER");
            assertThat(r.getDouble(2)).isEqualTo(4.5); assertThat(r.getString(3)).isEqualTo("qa-bcrypt-placeholder");
            assertThat(r.getLong(4)).isZero(); assertThat(r.getBoolean(5)).isTrue(); assertThat(r.getBoolean(6)).isTrue();
            assertThat(r.getObject(7)).isNull(); assertThat(r.getString(8)).isEqualTo("BRONZE");
        }
        assertThat(migrations().migrate().migrationsExecuted).isZero();
        assertThat(migrations().validateWithResult().validationSuccessful).isTrue();
    }
    @Test void upgradeBackfillsAcceptedRateWithoutInventingConsent() throws Exception {
        try(var c=connect()) {
            c.setSchema(schema);
            ScriptUtils.executeSqlScript(c,new ClassPathResource("db/migration/V1__initial_schema.sql"));
            try(var s=c.createStatement()) {
                s.executeUpdate("INSERT INTO users(phone_number,password,full_name,role,is_verified,rating,is_active,created_at) VALUES"
                    + "('0999999921','qa-hash','QA owner','ROLE_CONTRACTOR',false,5,true,CURRENT_TIMESTAMP),"
                    + "('0999999922','qa-hash','QA worker','ROLE_WORKER',false,5,true,CURRENT_TIMESTAMP)");
                s.executeUpdate("INSERT INTO jobs(contractor_id,title,job_type,salary_per_day,address,latitude,longitude,required_workers) "
                    + "SELECT id,'Legacy paid rate','Thợ chính',450000.75,'QA',10,106,1 FROM users WHERE phone_number='0999999921'");
                s.executeUpdate("INSERT INTO job_applications(job_id,worker_id,status) SELECT j.id,u.id,'ACCEPTED' FROM jobs j,users u WHERE u.phone_number='0999999922'");
                s.executeUpdate("INSERT INTO messages(job_id,sender_id,recipient_id,content,client_message_id) "
                    + "SELECT j.id,u.id,j.contractor_id,'Legacy text','legacy-chat' FROM jobs j,users u WHERE u.phone_number='0999999922'");
            }
        }
        migrations().migrate();
        try(var c=connect();var s=c.createStatement();var r=s.executeQuery("SELECT agreed_daily_rate,accepted_terms_at,contract_snapshot FROM "+schema+".job_applications")) {
            assertThat(r.next()).isTrue(); assertThat(r.getLong(1)).isEqualTo(450001);
            assertThat(r.getTimestamp(2)).isNull(); assertThat(r.getString(3)).isNull();
        }
        try(var c=connect();var s=c.createStatement();var r=s.executeQuery("SELECT attendance_required FROM "+schema+".jobs")) {
            assertThat(r.next()).isTrue();assertThat(r.getBoolean(1)).isFalse();
        }
        try(var c=connect()) {
            c.setSchema(schema);
            // Re-running the manual upgrade must preserve an existing legacy job.
            ScriptUtils.executeSqlScript(c,new ClassPathResource("db/migration/V29__job_staffing.sql"));
            ScriptUtils.executeSqlScript(c,new ClassPathResource("db/migration/V29__job_staffing.sql"));
            try(var s=c.createStatement();var r=s.executeQuery("SELECT job_type,required_workers,skilled_workers,helpers FROM jobs")) {
                assertThat(r.next()).isTrue();assertThat(r.getString(1)).isEqualTo("Thợ chính");
                assertThat(r.getInt(2)).isEqualTo(1);assertThat(r.getObject(3)).isNull();assertThat(r.getObject(4)).isNull();
            }
            try(var s=c.createStatement()) {
                s.executeUpdate("UPDATE jobs SET job_type='Thợ chính, Phụ hồ',required_workers=5,skilled_workers=2,helpers=3");
                org.assertj.core.api.Assertions.assertThatThrownBy(() -> s.executeUpdate("UPDATE jobs SET helpers=4"))
                    .isInstanceOf(SQLException.class);
                org.assertj.core.api.Assertions.assertThatThrownBy(() -> s.executeUpdate("UPDATE jobs SET skilled_workers=NULL"))
                    .isInstanceOf(SQLException.class);
            }
        }
        try(var c=connect();var s=c.createStatement();var r=s.executeQuery("SELECT content,kind,latitude,longitude,image_hash FROM "+schema+".messages")) {
            assertThat(r.next()).isTrue();assertThat(r.getString(1)).isEqualTo("Legacy text");assertThat(r.getString(2)).isEqualTo("TEXT");
            assertThat(r.getObject(3)).isNull();assertThat(r.getObject(4)).isNull();assertThat(r.getObject(5)).isNull();
        }
        // Run the shared inbox ACL on PostgreSQL too, not only H2's compatibility mode.
        try(var c=connect();var s=c.createStatement()) {
            c.setSchema(schema);
            long owner;
            try(var r=s.executeQuery("SELECT contractor_id FROM jobs")) { r.next(); owner=r.getLong(1); }
            String acl=vn.thoxay.repository.MessageRepository.ACTIVE_PAIR.replace(":actor",String.valueOf(owner));
            String count="SELECT COUNT(*) "+acl+"AND m.recipient_id="+owner+" AND m.id>COALESCE(r.last_read_message_id,0)";
            try(var r=s.executeQuery(count)) { r.next(); assertThat(r.getLong(1)).isEqualTo(1); }
            try(var r=s.executeQuery("SELECT MAX(m.id) AS latestId, SUM(CASE WHEN m.recipient_id="+owner+" AND m.id>COALESCE(r.last_read_message_id,0) THEN 1 ELSE 0 END) AS unreadCount "
                +acl+"GROUP BY m.job_id,CASE WHEN m.sender_id="+owner+" THEN m.recipient_id ELSE m.sender_id END ORDER BY MAX(m.id) DESC")) {
                assertThat(r.next()).isTrue(); assertThat(r.getLong("unreadCount")).isEqualTo(1);
            }
            s.executeUpdate("INSERT INTO chat_read_states(user_id,job_id,peer_id,last_read_message_id) SELECT recipient_id,job_id,sender_id,id FROM messages");
            try(var r=s.executeQuery(count)) { r.next(); assertThat(r.getLong(1)).isZero(); }
        }
        assertThat(migrations().migrate().migrationsExecuted).isZero();
    }
}
