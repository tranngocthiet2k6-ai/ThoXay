-- Re-runnable; recalculate only the derived tier, retaining all earned statistics.
ALTER TABLE users ALTER COLUMN worker_tier SET DEFAULT 'BRONZE';
UPDATE users SET worker_tier = CASE
    WHEN role <> 'ROLE_WORKER' THEN 'BRONZE'
    WHEN reputation_score >= 95 AND rating >= 4.7 AND completed_jobs >= 20 AND is_verified THEN 'DIAMOND'
    WHEN reputation_score >= 80 AND rating >= 4.0 AND completed_jobs >= 5 THEN 'GOLD'
    WHEN reputation_score >= 60 AND rating >= 3.0 AND completed_jobs >= 1 THEN 'SILVER'
    ELSE 'BRONZE' END;
