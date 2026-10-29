-- Run against database tho_xay_db: psql -U postgres -d tho_xay_db -f schema.sql
BEGIN;
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
  starts_on DATE, ends_on DATE, terms_version INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT chk_job_schedule CHECK ((starts_on IS NULL AND ends_on IS NULL) OR (starts_on IS NOT NULL AND ends_on IS NOT NULL AND ends_on>=starts_on AND ends_on-starts_on<=365)),
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
  proposed_daily_rate BIGINT CHECK(proposed_daily_rate IS NULL OR proposed_daily_rate BETWEEN 1 AND 1000000000),
  wage_note VARCHAR(500), agreed_daily_rate BIGINT CHECK(agreed_daily_rate IS NULL OR agreed_daily_rate BETWEEN 1 AND 1000000000),
  consent_version INTEGER, accepted_terms_at TIMESTAMPTZ,
  contract_snapshot TEXT, contract_hash VARCHAR(64), contractor_confirmed_at TIMESTAMPTZ,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (job_id, worker_id)
);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_contractor ON jobs(contractor_id);
CREATE INDEX IF NOT EXISTS idx_applications_worker ON job_applications(worker_id);
CREATE TABLE IF NOT EXISTS worker_calendar_blocks (
  id BIGSERIAL PRIMARY KEY, worker_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  work_day DATE NOT NULL, note VARCHAR(200) NOT NULL DEFAULT '', UNIQUE(worker_id,work_day)
);
CREATE INDEX IF NOT EXISTS idx_jobs_schedule ON jobs(starts_on,ends_on);
CREATE INDEX IF NOT EXISTS idx_calendar_worker ON worker_calendar_blocks(worker_id,work_day);
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
  work_days INTEGER NOT NULL CHECK(work_days BETWEEN 1 AND 366),daily_rate BIGINT NOT NULL CHECK(daily_rate>0),
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


CREATE TABLE IF NOT EXISTS saved_jobs (
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(owner_id,job_id)
);
CREATE TABLE IF NOT EXISTS saved_workers (
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    worker_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(owner_id,worker_id), CHECK(owner_id<>worker_id)
);

CREATE TABLE IF NOT EXISTS crews (
 id BIGSERIAL PRIMARY KEY, leader_id BIGINT NOT NULL REFERENCES users(id), name VARCHAR(100) NOT NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS crew_members (
 id BIGSERIAL PRIMARY KEY, crew_id BIGINT NOT NULL REFERENCES crews(id) ON DELETE CASCADE,
 worker_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 status VARCHAR(20) NOT NULL DEFAULT 'INVITED' CHECK(status IN ('INVITED','CONFIRMED','DECLINED')),
 confirmed_at TIMESTAMPTZ, UNIQUE(crew_id,worker_id)
);
CREATE INDEX IF NOT EXISTS idx_crew_member_worker ON crew_members(worker_id,id);
CREATE TABLE IF NOT EXISTS crew_batches (
 id BIGSERIAL PRIMARY KEY, crew_id BIGINT NOT NULL REFERENCES crews(id),
 job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
 status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','ACCEPTED','REJECTED')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE(crew_id,job_id)
);
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS crew_batch_id BIGINT REFERENCES crew_batches(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_application_crew ON job_applications(crew_batch_id);

CREATE TABLE IF NOT EXISTS portfolio_photos (
 id UUID PRIMARY KEY,owner_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 caption VARCHAR(160) NOT NULL DEFAULT '',content BYTEA NOT NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CHECK(octet_length(content)<=2097152)
);
CREATE INDEX IF NOT EXISTS idx_portfolio_owner ON portfolio_photos(owner_id,created_at);

ALTER TABLE jobs ADD COLUMN IF NOT EXISTS attendance_required BOOLEAN NOT NULL DEFAULT FALSE;
CREATE TABLE IF NOT EXISTS attendance_records (
 id BIGSERIAL PRIMARY KEY,application_id BIGINT NOT NULL REFERENCES job_applications(id) ON DELETE CASCADE,
 work_day DATE NOT NULL,checked_in_at TIMESTAMPTZ NOT NULL,checked_out_at TIMESTAMPTZ,
 checkin_method VARCHAR(10) NOT NULL CHECK(checkin_method IN ('GPS','QR')),
 checkout_method VARCHAR(10) CHECK(checkout_method IN ('GPS','QR')),
 checkin_latitude DOUBLE PRECISION,checkin_longitude DOUBLE PRECISION,checkin_accuracy DOUBLE PRECISION,
 checkout_latitude DOUBLE PRECISION,checkout_longitude DOUBLE PRECISION,checkout_accuracy DOUBLE PRECISION,
 UNIQUE(application_id,work_day),CHECK(checked_out_at IS NULL OR checked_out_at>=checked_in_at)
);
CREATE TABLE IF NOT EXISTS attendance_shift_codes (
 job_id BIGINT PRIMARY KEY REFERENCES jobs(id) ON DELETE CASCADE,token_hash VARCHAR(64) NOT NULL,
 expires_at TIMESTAMPTZ NOT NULL
);
CREATE TABLE IF NOT EXISTS work_logs (
 id BIGSERIAL PRIMARY KEY,attendance_id BIGINT NOT NULL UNIQUE REFERENCES attendance_records(id) ON DELETE CASCADE,
 caption VARCHAR(1000) NOT NULL DEFAULT '',photo BYTEA NOT NULL CHECK(octet_length(photo)<=2097152),
 status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','APPROVED','CHANGES_REQUESTED')),
 feedback VARCHAR(500) NOT NULL DEFAULT '',created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
 reviewed_at TIMESTAMPTZ,version BIGINT NOT NULL DEFAULT 0
);

-- Demo-only password for all three accounts: password
INSERT INTO users (phone_number,password,full_name,role,is_verified)
VALUES
('0900000001','$2a$10$ujHVMiRDJR3OBm5yXjsRS.XF8NDGIFPgFIdRQDpYcVr/MUAvSILda','Quản trị viên','ROLE_ADMIN',FALSE),
('0900000002','$2a$10$ujHVMiRDJR3OBm5yXjsRS.XF8NDGIFPgFIdRQDpYcVr/MUAvSILda','Nguyễn Văn Thầu','ROLE_CONTRACTOR',FALSE),
('0900000003','$2a$10$ujHVMiRDJR3OBm5yXjsRS.XF8NDGIFPgFIdRQDpYcVr/MUAvSILda','Trần Văn Thợ','ROLE_WORKER',FALSE)
ON CONFLICT (phone_number) DO NOTHING;
INSERT INTO jobs (contractor_id,title,description,job_type,salary_per_day,address,latitude,longitude,required_workers)
SELECT id,'Cần thợ xây nhà phố','Làm việc từ 7h đến 17h, bao cơm trưa.','Thợ chính',500000,
'Quận 1, TP. Hồ Chí Minh',10.7769,106.7009,3 FROM users
WHERE phone_number='0900000002' AND NOT EXISTS (SELECT 1 FROM jobs WHERE title='Cần thợ xây nhà phố');
INSERT INTO job_applications(job_id,worker_id)
SELECT j.id,u.id FROM jobs j CROSS JOIN users u WHERE j.title='Cần thợ xây nhà phố'
AND u.phone_number='0900000003' ON CONFLICT(job_id,worker_id) DO NOTHING;
COMMIT;
