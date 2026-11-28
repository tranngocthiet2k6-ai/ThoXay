-- Retain original checkout evidence even after a shift is reopened.
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS latest_correction_id BIGINT;
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS correction_revision BIGINT NOT NULL DEFAULT 0;
ALTER TABLE work_logs ADD COLUMN IF NOT EXISTS correction_revision BIGINT NOT NULL DEFAULT 0;
ALTER TABLE attendance_records DROP CONSTRAINT IF EXISTS attendance_records_checkout_method_check;
ALTER TABLE attendance_records ADD CONSTRAINT attendance_records_checkout_method_check
 CHECK (checkout_method IN ('GPS','QR','ADJUSTED'));
CREATE TABLE IF NOT EXISTS attendance_corrections (
 id BIGSERIAL PRIMARY KEY,
 attendance_id BIGINT NOT NULL REFERENCES attendance_records(id) ON DELETE CASCADE,
 original_checked_out_at TIMESTAMPTZ NOT NULL, original_method VARCHAR(10) NOT NULL,
 original_latitude DOUBLE PRECISION, original_longitude DOUBLE PRECISION, original_accuracy DOUBLE PRECISION,
 status VARCHAR(30) NOT NULL CHECK (status IN ('AUTO_UNDONE','PENDING','APPROVED','REJECTED')),
 reason VARCHAR(500) NOT NULL, requested_at TIMESTAMPTZ NOT NULL, requested_by BIGINT NOT NULL,
 reviewed_at TIMESTAMPTZ, reviewed_by BIGINT, feedback VARCHAR(500) NOT NULL DEFAULT '',
 corrected_checked_out_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_attendance_corrections_attendance ON attendance_corrections(attendance_id,id DESC);
