BEGIN;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_score INTEGER NOT NULL DEFAULT 100 CHECK (reputation_score BETWEEN 0 AND 100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS completed_jobs INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS cancelled_jobs INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS worker_tier VARCHAR(12) NOT NULL DEFAULT 'SILVER';
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;
UPDATE users u SET completed_jobs = (SELECT count(*) FROM job_applications a JOIN jobs j ON j.id=a.job_id
  WHERE a.worker_id=u.id AND a.status='ACCEPTED' AND a.worker_rating IS NOT NULL AND j.status='COMPLETED'),
  rating = COALESCE((SELECT avg(a.worker_rating) FROM job_applications a JOIN jobs j ON j.id=a.job_id
  WHERE a.worker_id=u.id AND a.status='ACCEPTED' AND a.worker_rating IS NOT NULL AND j.status='COMPLETED'), 5.0)
WHERE u.role='ROLE_WORKER';
UPDATE users SET worker_tier = CASE
  WHEN role='ROLE_WORKER' AND reputation_score>=95 AND rating>=4.7 AND completed_jobs>=20 AND is_verified THEN 'DIAMOND'
  WHEN role='ROLE_WORKER' AND reputation_score>=80 AND rating>=4.0 AND completed_jobs>=5 THEN 'GOLD' ELSE 'SILVER' END;
CREATE TABLE IF NOT EXISTS reputation_events (
  id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  job_id BIGINT REFERENCES jobs(id) ON DELETE SET NULL,
  application_id BIGINT REFERENCES job_applications(id) ON DELETE SET NULL,
  job_title VARCHAR(200) NOT NULL, type VARCHAR(30) NOT NULL, delta INTEGER NOT NULL,
  score_after INTEGER NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(application_id,type)
);
CREATE INDEX IF NOT EXISTS idx_reputation_user ON reputation_events(user_id,id);
COMMIT;
