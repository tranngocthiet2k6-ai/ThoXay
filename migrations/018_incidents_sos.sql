CREATE TABLE IF NOT EXISTS incidents (
 id BIGSERIAL PRIMARY KEY,job_id BIGINT REFERENCES jobs(id) ON DELETE SET NULL,original_job_id BIGINT NOT NULL,
 job_title VARCHAR(200) NOT NULL,job_address VARCHAR(255) NOT NULL,job_latitude DOUBLE PRECISION NOT NULL,job_longitude DOUBLE PRECISION NOT NULL,
 reporter_id BIGINT REFERENCES users(id) ON DELETE SET NULL,reporter_name VARCHAR(100) NOT NULL,reporter_phone VARCHAR(15) NOT NULL,
 client_request_id VARCHAR(80) NOT NULL,type VARCHAR(30) NOT NULL CHECK(type IN ('SOS','SAFETY','PAYMENT_DISPUTE','OTHER')),
 status VARCHAR(30) NOT NULL DEFAULT 'NEW' CHECK(status IN ('NEW','IN_REVIEW','RESOLVED')),description VARCHAR(2000) NOT NULL,
 reported_latitude DOUBLE PRECISION,reported_longitude DOUBLE PRECISION,admin_note VARCHAR(1000) NOT NULL DEFAULT '',
 created_at TIMESTAMPTZ NOT NULL,updated_at TIMESTAMPTZ,version BIGINT NOT NULL DEFAULT 0,
 UNIQUE(reporter_id,client_request_id),
 CHECK((reported_latitude IS NULL AND reported_longitude IS NULL) OR (reported_latitude IS NOT NULL AND reported_longitude IS NOT NULL AND reported_latitude BETWEEN -90 AND 90 AND reported_longitude BETWEEN -180 AND 180))
);
CREATE INDEX IF NOT EXISTS idx_incident_priority ON incidents(status,type,id);
CREATE INDEX IF NOT EXISTS idx_incident_reporter ON incidents(reporter_id,id);
CREATE TABLE IF NOT EXISTS incident_audit (
 id BIGSERIAL PRIMARY KEY,incident_id BIGINT NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
 actor_id BIGINT REFERENCES users(id) ON DELETE SET NULL,status VARCHAR(30) NOT NULL,note VARCHAR(1000) NOT NULL,created_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_incident_audit ON incident_audit(incident_id,id);
