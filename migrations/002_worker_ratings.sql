-- Apply to an existing tho_xay_db before running the upgraded backend.
BEGIN;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS worker_rating INTEGER;
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_worker_rating'
                 AND conrelid = 'job_applications'::regclass) THEN
    ALTER TABLE job_applications ADD CONSTRAINT chk_worker_rating
      CHECK (worker_rating IS NULL OR (worker_rating BETWEEN 1 AND 5 AND status = 'ACCEPTED'));
  END IF;
END $$;
COMMIT;
