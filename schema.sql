-- Run against database tho_xay_db: psql -U postgres -d tho_xay_db -f schema.sql
BEGIN;
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  phone_number VARCHAR(15) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  role VARCHAR(30) NOT NULL CHECK (role IN ('ROLE_WORKER','ROLE_CONTRACTOR','ROLE_ADMIN')),
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  cccd_image VARCHAR(500),
  rating DOUBLE PRECISION NOT NULL DEFAULT 5.0 CHECK (rating BETWEEN 0 AND 5),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
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
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ACCEPTED','REJECTED')),
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (job_id, worker_id)
);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_contractor ON jobs(contractor_id);
CREATE INDEX IF NOT EXISTS idx_applications_worker ON job_applications(worker_id);
-- Demo-only password for all three accounts: password
INSERT INTO users (phone_number,password,full_name,role,is_verified)
VALUES
('0900000001','$2a$10$ujHVMiRDJR3OBm5yXjsRS.XF8NDGIFPgFIdRQDpYcVr/MUAvSILda','Quản trị viên','ROLE_ADMIN',TRUE),
('0900000002','$2a$10$ujHVMiRDJR3OBm5yXjsRS.XF8NDGIFPgFIdRQDpYcVr/MUAvSILda','Nguyễn Văn Thầu','ROLE_CONTRACTOR',TRUE),
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
