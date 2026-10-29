ALTER TABLE messages ADD COLUMN IF NOT EXISTS kind VARCHAR(16) NOT NULL DEFAULT 'TEXT';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS image_hash VARCHAR(64);
DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='ck_message_payload' AND conrelid='messages'::regclass) THEN
  ALTER TABLE messages ADD CONSTRAINT ck_message_payload CHECK (
   (kind='TEXT' AND latitude IS NULL AND longitude IS NULL AND image_hash IS NULL) OR
   (kind='IMAGE' AND latitude IS NULL AND longitude IS NULL AND image_hash IS NOT NULL AND length(image_hash)=64) OR
   (kind='LOCATION' AND latitude IS NOT NULL AND longitude IS NOT NULL AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180 AND image_hash IS NULL));
 END IF;
END $$;
CREATE TABLE IF NOT EXISTS message_attachments (
 message_id BIGINT PRIMARY KEY REFERENCES messages(id) ON DELETE CASCADE,
 content BYTEA NOT NULL CHECK(octet_length(content)<=2097152)
);
