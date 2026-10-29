ALTER TABLE jobs ADD COLUMN IF NOT EXISTS starts_on DATE;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS ends_on DATE;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS terms_version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS proposed_daily_rate BIGINT;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS wage_note VARCHAR(500);
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS agreed_daily_rate BIGINT;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS consent_version INTEGER;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS accepted_terms_at TIMESTAMPTZ;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS contract_snapshot TEXT;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS contract_hash VARCHAR(64);
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS contractor_confirmed_at TIMESTAMPTZ;
UPDATE job_applications a SET agreed_daily_rate = ROUND(j.salary_per_day)::BIGINT
FROM jobs j WHERE a.job_id=j.id AND a.status='ACCEPTED' AND a.agreed_daily_rate IS NULL;
CREATE TABLE IF NOT EXISTS worker_calendar_blocks (
  id BIGSERIAL PRIMARY KEY,
  worker_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  work_day DATE NOT NULL,
  note VARCHAR(200) NOT NULL DEFAULT '',
  UNIQUE(worker_id,work_day)
);
CREATE INDEX IF NOT EXISTS idx_jobs_schedule ON jobs(starts_on,ends_on);
CREATE INDEX IF NOT EXISTS idx_calendar_worker ON worker_calendar_blocks(worker_id,work_day);
DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_job_schedule' AND conrelid='jobs'::regclass) THEN
  ALTER TABLE jobs ADD CONSTRAINT chk_job_schedule CHECK
   ((starts_on IS NULL AND ends_on IS NULL) OR (starts_on IS NOT NULL AND ends_on IS NOT NULL AND ends_on>=starts_on AND ends_on-starts_on<=365));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_application_rates' AND conrelid='job_applications'::regclass) THEN
  ALTER TABLE job_applications ADD CONSTRAINT chk_application_rates CHECK
   ((proposed_daily_rate IS NULL OR proposed_daily_rate BETWEEN 1 AND 1000000000) AND
    (agreed_daily_rate IS NULL OR agreed_daily_rate BETWEEN 1 AND 1000000000));
 END IF;
END $$;
