package vn.thoxay.config;

import org.flywaydb.core.api.MigrationVersion;
import org.springframework.boot.autoconfigure.flyway.FlywayConfigurationCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Adopt the existing 002..011 schema once; all later changes are versioned. */
@Configuration
public class DatabaseMigrationConfig {
    @Bean
    FlywayConfigurationCustomizer existingDatabaseBaseline() {
        return configuration -> configuration
            .baselineOnMigrate(true)
            .baselineVersion(MigrationVersion.fromVersion("11"))
            .cleanDisabled(true);
    }
}
