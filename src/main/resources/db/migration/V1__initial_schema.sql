-- Cloud initialization: schema only, no demo accounts or jobs.
-- Run against database tho_xay_db: psql -U postgres -d tho_xay_db -f schema.sql
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  phone_number VARCHAR(15) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  date_of_birth DATE,
  experience_years INTEGER NOT NULL DEFAULT 0,
  experience_summary VARCHAR(2000),
  role VARCHAR(30) NOT NULL CHECK (role IN ('ROLE_WORKER','ROLE_CONTRACTOR','ROLE_ADMIN')),
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  cccd_image VARCHAR(500),
  cccd_front_image VARCHAR(500),
  cccd_back_image VARCHAR(500),
  rating DOUBLE PRECISION NOT NULL DEFAULT 5.0 CHECK (rating BETWEEN 0 AND 5),
  reputation_score INTEGER NOT NULL DEFAULT 100 CHECK (reputation_score BETWEEN 0 AND 100),
  completed_jobs INTEGER NOT NULL DEFAULT 0,
  cancelled_jobs INTEGER NOT NULL DEFAULT 0,
  worker_tier VARCHAR(12) NOT NULL DEFAULT 'SILVER',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_users_verified_cccd_faces CHECK (NOT is_verified OR
    ((COALESCE(cccd_front_image, '') LIKE 'https://_%' OR COALESCE(cccd_front_image, '') LIKE '/admin/kyc/images/%')
     AND (COALESCE(cccd_back_image, '') LIKE 'https://_%' OR COALESCE(cccd_back_image, '') LIKE '/admin/kyc/images/%')))
);
CREATE TABLE IF NOT EXISTS kyc_images (
  id UUID PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content BYTEA NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_kyc_images_user ON kyc_images(user_id);
CREATE TABLE IF NOT EXISTS jobs (
  id BIGSERIAL PRIMARY KEY,
  contractor_id BIGINT NOT NULL REFERENCES users(id),
  title VARCHAR(200) NOT NULL,
  description TEXT,
  job_type VARCHAR(50) NOT NULL CHECK (job_type IN ('Thợ chính','Phụ hồ')),
  salary_per_day DOUBLE PRECISION NOT NULL CHECK (salary_per_day > 0),
  address VARCHAR(255) NOT NULL,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  required_workers INTEGER NOT NULL CHECK (required_workers > 0),
  status VARCHAR(30) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','IN_PROGRESS','COMPLETED','CANCELLED')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS job_applications (
  id BIGSERIAL PRIMARY KEY,
  job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  worker_id BIGINT NOT NULL REFERENCES users(id),
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ACCEPTED','REJECTED','CANCELLED')),
  cancellation_reason VARCHAR(500), cancelled_at TIMESTAMPTZ,
  cancellation_penalty INTEGER NOT NULL DEFAULT 0,
  worker_rating INTEGER CONSTRAINT chk_worker_rating CHECK (worker_rating IS NULL OR (worker_rating BETWEEN 1 AND 5 AND status = 'ACCEPTED')),
  reviewed_at TIMESTAMPTZ,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (job_id, worker_id)
);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_contractor ON jobs(contractor_id);
CREATE INDEX IF NOT EXISTS idx_applications_worker ON job_applications(worker_id);
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
CREATE TABLE IF NOT EXISTS notifications (
  id BIGSERIAL PRIMARY KEY,
  recipient_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  job_id BIGINT REFERENCES jobs(id) ON DELETE SET NULL,
  event_key VARCHAR(200) UNIQUE NOT NULL,
  type VARCHAR(40) NOT NULL, title VARCHAR(120) NOT NULL, body VARCHAR(500) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, read_at TIMESTAMPTZ,
  push_status VARCHAR(20) NOT NULL DEFAULT 'DISABLED', push_attempts INTEGER NOT NULL DEFAULT 0,
  next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_id,id);
CREATE INDEX IF NOT EXISTS idx_notifications_outbox ON notifications(push_status,next_attempt_at);
CREATE TABLE IF NOT EXISTS device_tokens (
  id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(64) UNIQUE NOT NULL, token VARCHAR(4096) NOT NULL,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS user_skills (
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sort_order INTEGER NOT NULL, skill VARCHAR(50) NOT NULL,
  PRIMARY KEY(user_id,sort_order)
);
CREATE TABLE IF NOT EXISTS user_project_images (
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sort_order INTEGER NOT NULL, image_url VARCHAR(500) NOT NULL,
  PRIMARY KEY(user_id,sort_order)
);
CREATE TABLE IF NOT EXISTS reputation_events (
  id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  job_id BIGINT REFERENCES jobs(id) ON DELETE SET NULL,
  application_id BIGINT REFERENCES job_applications(id) ON DELETE SET NULL,
  job_title VARCHAR(200) NOT NULL, type VARCHAR(30) NOT NULL, delta INTEGER NOT NULL,
  score_after INTEGER NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(application_id,type)
);
CREATE INDEX IF NOT EXISTS idx_reputation_user ON reputation_events(user_id,id);

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
