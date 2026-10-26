BEGIN;
-- Preserve existing workers' ability to apply; newly registered accounts start offline in AuthService.
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_available BOOLEAN NOT NULL DEFAULT TRUE;
COMMIT;
