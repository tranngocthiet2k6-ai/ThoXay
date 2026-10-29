CREATE TABLE IF NOT EXISTS chat_read_states (
 id BIGSERIAL PRIMARY KEY,
 user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
 peer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 last_read_message_id BIGINT NOT NULL DEFAULT 0 CHECK(last_read_message_id>=0),
 UNIQUE(user_id,job_id,peer_id), CHECK(user_id<>peer_id)
);
CREATE INDEX IF NOT EXISTS idx_messages_recipient_unread ON messages(recipient_id,job_id,id);
