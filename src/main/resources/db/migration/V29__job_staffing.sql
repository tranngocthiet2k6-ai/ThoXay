-- Nullable counts preserve old clients and existing single-trade jobs.
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS skilled_workers INTEGER;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helpers INTEGER;
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_job_type_check;
ALTER TABLE jobs ADD CONSTRAINT jobs_job_type_check
    CHECK (job_type IN ('Thợ chính', 'Phụ hồ', 'Thợ chính, Phụ hồ'));
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS chk_job_staffing;
ALTER TABLE jobs ADD CONSTRAINT chk_job_staffing CHECK (
    (skilled_workers IS NULL AND helpers IS NULL AND job_type IN ('Thợ chính', 'Phụ hồ'))
    OR (skilled_workers IS NOT NULL AND helpers IS NOT NULL
        AND skilled_workers BETWEEN 0 AND 10000 AND helpers BETWEEN 0 AND 10000
        AND skilled_workers + helpers = required_workers AND required_workers BETWEEN 1 AND 10000
        AND job_type = CASE WHEN skilled_workers > 0 THEN
            CASE WHEN helpers > 0 THEN 'Thợ chính, Phụ hồ' ELSE 'Thợ chính' END
            ELSE 'Phụ hồ' END)
);
