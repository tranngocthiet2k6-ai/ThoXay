CREATE TABLE IF NOT EXISTS contractor_groups (
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(80) NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 80),
    UNIQUE(owner_id, name)
);
CREATE TABLE IF NOT EXISTS contractor_group_members (
    id BIGSERIAL PRIMARY KEY,
    group_id BIGINT NOT NULL REFERENCES contractor_groups(id) ON DELETE CASCADE,
    saved_worker_id BIGINT NOT NULL REFERENCES saved_workers(id) ON DELETE CASCADE,
    UNIQUE(group_id, saved_worker_id)
);
