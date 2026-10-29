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
                "SELECT role,rating,password FROM " + schema + ".users WHERE phone_number='0999999911'")) {
            assertThat(r.next()).isTrue(); assertThat(r.getString(1)).isEqualTo("ROLE_WORKER");
            assertThat(r.getDouble(2)).isEqualTo(4.5); assertThat(r.getString(3)).isEqualTo("qa-bcrypt-placeholder");
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
        assertThat(migrations().migrate().migrationsExecuted).isZero();
    }
}
