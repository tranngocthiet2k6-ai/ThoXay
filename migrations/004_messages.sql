-- Apply after 003_cccd_front_back.sql; safe to run again.
BEGIN;
CREATE TABLE IF NOT EXISTS messages (
  id BIGSERIAL PRIMARY KEY,
  sender_id BIGINT NOT NULL REFERENCES users(id),
  recipient_id BIGINT NOT NULL REFERENCES users(id),
  job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  content VARCHAR(2000) NOT NULL CHECK (length(trim(content)) > 0),
  client_message_id VARCHAR(64) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (sender_id <> recipient_id),
  UNIQUE (sender_id, client_message_id)
);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(job_id, sender_id, recipient_id, id);
COMMIT;
