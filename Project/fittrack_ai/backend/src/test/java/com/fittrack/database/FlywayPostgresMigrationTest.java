package com.fittrack.database;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;

import static org.junit.jupiter.api.Assertions.assertTrue;

@Testcontainers(disabledWithoutDocker = true)
class FlywayPostgresMigrationTest {

    @Container
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine")
            .withDatabaseName("fittrack_migration_test")
            .withUsername("fittrack")
            .withPassword("fittrack");

    @Test
    void appliesEveryMigrationToRealPostgresAndCreatesCriticalSchema() throws Exception {
        Flyway flyway = Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .baselineOnMigrate(true)
                .baselineVersion("0")
                .load();

        var result = flyway.migrate();

        assertTrue(result.migrationsExecuted >= 15);
        try (Connection connection = DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword()
        )) {
            assertTrue(exists(connection,
                    "select 1 from information_schema.tables where table_name = 'lunch_payment_requests'"));
            assertTrue(exists(connection,
                    "select 1 from information_schema.columns where table_name = 'users' and column_name = 'token_version'"));
            assertTrue(exists(connection,
                    "select 1 from information_schema.columns where table_name = 'health_reminders' and column_name = 'next_run_at'"));
            assertTrue(exists(connection,
                    "select 1 from information_schema.columns where table_name = 'users' and column_name = 'email_notifications_enabled'"));
            assertTrue(exists(connection,
                    "select 1 from information_schema.columns where table_name = 'user_auth_tokens' and column_name = 'failed_attempts'"));
            assertTrue(exists(connection,
                    "select 1 from pg_indexes where indexname = 'idx_meal_logs_user_date'"));
            assertTrue(exists(connection,
                    "select 1 from information_schema.columns where table_name = 'workout_sets' and column_name = 'set_type'"));
            assertTrue(exists(connection,
                    "select 1 from information_schema.columns where table_name = 'workout_sets' and column_name = 'exercise_order'"));
            assertTrue(exists(connection,
                    "select 1 from information_schema.tables where table_name = 'nutrition_day_states'"));
            assertTrue(exists(connection,
                    "select 1 from information_schema.tables where table_name = 'water_logs'"));
            assertTrue(exists(connection,
                    "select 1 from information_schema.columns where table_name = 'meal_items' and column_name = 'serving_unit'"));
            assertTrue(count(connection,
                    "select count(*) from flyway_schema_history where success") >= 15);
        }
    }

    private boolean exists(Connection connection, String sql) throws Exception {
        try (var statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            return resultSet.next();
        }
    }

    private int count(Connection connection, String sql) throws Exception {
        try (var statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            resultSet.next();
            return resultSet.getInt(1);
        }
    }
}
