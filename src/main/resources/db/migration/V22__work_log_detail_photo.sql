-- Optional second image; existing one-image work logs remain valid.
ALTER TABLE work_logs ADD COLUMN IF NOT EXISTS detail_photo BYTEA;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
        WHERE conrelid = 'work_logs'::regclass AND conname = 'work_logs_detail_photo_size') THEN
        ALTER TABLE work_logs ADD CONSTRAINT work_logs_detail_photo_size
            CHECK (detail_photo IS NULL OR octet_length(detail_photo) <= 2097152);
    END IF;
END $$;
