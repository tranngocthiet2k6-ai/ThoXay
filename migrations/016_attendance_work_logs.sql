ALTER TABLE jobs ADD COLUMN IF NOT EXISTS attendance_required BOOLEAN NOT NULL DEFAULT FALSE;
CREATE TABLE IF NOT EXISTS attendance_records (
 id BIGSERIAL PRIMARY KEY,application_id BIGINT NOT NULL REFERENCES job_applications(id) ON DELETE CASCADE,
 work_day DATE NOT NULL,checked_in_at TIMESTAMPTZ NOT NULL,checked_out_at TIMESTAMPTZ,
 checkin_method VARCHAR(10) NOT NULL CHECK(checkin_method IN ('GPS','QR')),
 checkout_method VARCHAR(10) CHECK(checkout_method IN ('GPS','QR')),
 checkin_latitude DOUBLE PRECISION,checkin_longitude DOUBLE PRECISION,checkin_accuracy DOUBLE PRECISION,
 checkout_latitude DOUBLE PRECISION,checkout_longitude DOUBLE PRECISION,checkout_accuracy DOUBLE PRECISION,
 UNIQUE(application_id,work_day),CHECK(checked_out_at IS NULL OR checked_out_at>=checked_in_at)
);
CREATE TABLE IF NOT EXISTS attendance_shift_codes (
 job_id BIGINT PRIMARY KEY REFERENCES jobs(id) ON DELETE CASCADE,token_hash VARCHAR(64) NOT NULL,
 expires_at TIMESTAMPTZ NOT NULL
);
CREATE TABLE IF NOT EXISTS work_logs (
 id BIGSERIAL PRIMARY KEY,attendance_id BIGINT NOT NULL UNIQUE REFERENCES attendance_records(id) ON DELETE CASCADE,
 caption VARCHAR(1000) NOT NULL DEFAULT '',photo BYTEA NOT NULL CHECK(octet_length(photo)<=2097152),
 status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','APPROVED','CHANGES_REQUESTED')),
 feedback VARCHAR(500) NOT NULL DEFAULT '',created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
 reviewed_at TIMESTAMPTZ,version BIGINT NOT NULL DEFAULT 0
);

ALTER TABLE job_payments DROP CONSTRAINT IF EXISTS job_payments_work_days_check;
DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='job_payments'::regclass AND conname='chk_job_payment_days_366') THEN
  ALTER TABLE job_payments ADD CONSTRAINT chk_job_payment_days_366 CHECK(work_days BETWEEN 1 AND 366);
 END IF;
END $$;
