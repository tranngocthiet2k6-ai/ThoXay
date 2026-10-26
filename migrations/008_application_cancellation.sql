BEGIN;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS cancellation_reason VARCHAR(500);
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS cancellation_penalty INTEGER NOT NULL DEFAULT 0;
ALTER TABLE job_applications DROP CONSTRAINT IF EXISTS job_applications_status_check;
ALTER TABLE job_applications ADD CONSTRAINT job_applications_status_check CHECK (status IN ('PENDING','ACCEPTED','REJECTED','CANCELLED'));
COMMIT;
