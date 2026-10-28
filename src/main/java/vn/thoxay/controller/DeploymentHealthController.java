package vn.thoxay.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

/** Readiness for the cloud load balancer, without disclosing database details. */
@RestController @RequiredArgsConstructor
public class DeploymentHealthController {
    private final JdbcTemplate jdbc;
    @GetMapping("/health")
    public ResponseEntity<?> health() {
        try {
            jdbc.queryForObject("SELECT 1", Integer.class);
            return ResponseEntity.ok(Map.of("status", "UP"));
        } catch (DataAccessException ex) {
            return ResponseEntity.status(503).body(Map.of("status", "DOWN"));
        }
    }
}
