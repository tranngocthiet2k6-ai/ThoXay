BEGIN;
CREATE TABLE IF NOT EXISTS wallet_accounts (
  user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  main_balance BIGINT NOT NULL DEFAULT 0, escrow_balance BIGINT NOT NULL DEFAULT 0,
  held_balance BIGINT NOT NULL DEFAULT 0,
  CHECK (main_balance>=0 AND escrow_balance>=0 AND held_balance>=0 AND main_balance+escrow_balance+held_balance<=1000000000000)
);
CREATE TABLE IF NOT EXISTS wallet_requests (
  id BIGSERIAL PRIMARY KEY,user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind VARCHAR(15) NOT NULL CHECK(kind IN ('TOP_UP','WITHDRAW')),
  status VARCHAR(15) NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','APPROVED','REJECTED')),
  amount BIGINT NOT NULL CHECK(amount BETWEEN 1000 AND 100000000),client_request_id VARCHAR(80) NOT NULL,
  transfer_reference VARCHAR(200),bank_name VARCHAR(100),bank_account VARCHAR(34),account_name VARCHAR(100),
  external_reference VARCHAR(100) UNIQUE,note VARCHAR(300),processed_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,processed_at TIMESTAMPTZ,
  UNIQUE(user_id,client_request_id)
);
CREATE TABLE IF NOT EXISTS job_payments (
  id BIGSERIAL PRIMARY KEY,application_id BIGINT UNIQUE REFERENCES job_applications(id) ON DELETE SET NULL,
  job_id BIGINT REFERENCES jobs(id) ON DELETE SET NULL,
  contractor_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,job_title VARCHAR(200) NOT NULL,
  work_days INTEGER NOT NULL CHECK(work_days BETWEEN 1 AND 365),daily_rate BIGINT NOT NULL CHECK(daily_rate>0),
  base BIGINT NOT NULL,tip BIGINT NOT NULL CHECK(tip>=0),bonus BIGINT NOT NULL CHECK(bonus>=0),total BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK(base=work_days*daily_rate AND total=base+tip+bonus)
);
CREATE TABLE IF NOT EXISTS wallet_entries (
  id BIGSERIAL PRIMARY KEY,user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  request_id BIGINT REFERENCES wallet_requests(id) ON DELETE SET NULL,
  payment_id BIGINT REFERENCES job_payments(id) ON DELETE SET NULL,
  kind VARCHAR(30) NOT NULL,amount BIGINT NOT NULL CHECK(amount>0),
  main_delta BIGINT NOT NULL,escrow_delta BIGINT NOT NULL,held_delta BIGINT NOT NULL,
  main_after BIGINT NOT NULL CHECK(main_after>=0),escrow_after BIGINT NOT NULL CHECK(escrow_after>=0),held_after BIGINT NOT NULL CHECK(held_after>=0),
  reference VARCHAR(150) NOT NULL UNIQUE,description VARCHAR(250) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_wallet_entry_user ON wallet_entries(user_id,id);
CREATE INDEX IF NOT EXISTS idx_wallet_income_date ON wallet_entries(user_id,created_at);
CREATE INDEX IF NOT EXISTS idx_wallet_pending ON wallet_requests(status,id);
COMMIT;
