CREATE TABLE IF NOT EXISTS receiving_bank_settings (
 id BIGINT PRIMARY KEY CHECK(id=1),enabled BOOLEAN NOT NULL DEFAULT FALSE,
 bank_bin VARCHAR(6),bank_name VARCHAR(100),account_no VARCHAR(19),account_name VARCHAR(100),
 version BIGINT NOT NULL DEFAULT 0,
 CHECK(NOT enabled OR (bank_bin IS NOT NULL AND bank_name IS NOT NULL AND account_no IS NOT NULL AND account_name IS NOT NULL))
);
CREATE TABLE IF NOT EXISTS receiving_bank_audit (
 id BIGSERIAL PRIMARY KEY,actor_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
 enabled BOOLEAN NOT NULL,bank_bin VARCHAR(6),bank_name VARCHAR(100),account_no VARCHAR(19),account_name VARCHAR(100),
 revision BIGINT NOT NULL,changed_at TIMESTAMPTZ NOT NULL
);
ALTER TABLE wallet_requests ADD COLUMN IF NOT EXISTS receiving_bank_bin VARCHAR(6);
ALTER TABLE wallet_requests ADD COLUMN IF NOT EXISTS deposit_reference VARCHAR(25);
ALTER TABLE wallet_requests ADD COLUMN IF NOT EXISTS qr_payload TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS uq_wallet_deposit_reference ON wallet_requests(deposit_reference);
