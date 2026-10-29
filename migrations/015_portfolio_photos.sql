CREATE TABLE IF NOT EXISTS portfolio_photos (
 id UUID PRIMARY KEY,owner_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 caption VARCHAR(160) NOT NULL DEFAULT '',content BYTEA NOT NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CHECK(octet_length(content)<=2097152)
);
CREATE INDEX IF NOT EXISTS idx_portfolio_owner ON portfolio_photos(owner_id,created_at);
