CREATE INDEX IF NOT EXISTS idx_wallet_entries_user_time ON wallet_entries(user_id,created_at);
