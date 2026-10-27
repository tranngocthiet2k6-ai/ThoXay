-- Existing installations retain cccd_image for historical data.
-- A previous single image becomes the front image; it does not prove both faces.
BEGIN;
ALTER TABLE users ADD COLUMN IF NOT EXISTS cccd_front_image VARCHAR(500);
ALTER TABLE users ADD COLUMN IF NOT EXISTS cccd_back_image VARCHAR(500);
ALTER TABLE users ALTER COLUMN is_verified SET DEFAULT FALSE;
UPDATE users SET cccd_front_image = cccd_image
  WHERE NULLIF(BTRIM(cccd_front_image), '') IS NULL AND NULLIF(BTRIM(cccd_image), '') IS NOT NULL;
UPDATE users SET is_verified = FALSE
  WHERE is_verified AND NOT (
    COALESCE(cccd_front_image, '') ~ '^(https://[^[:space:]]+|/admin/kyc/images/[0-9a-f-]{36})$'
    AND COALESCE(cccd_back_image, '') ~ '^(https://[^[:space:]]+|/admin/kyc/images/[0-9a-f-]{36})$');
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_users_verified_cccd_faces'
                 AND conrelid = 'users'::regclass) THEN
    ALTER TABLE users ADD CONSTRAINT chk_users_verified_cccd_faces CHECK (NOT is_verified OR
      (COALESCE(cccd_front_image, '') LIKE 'https://_%' AND COALESCE(cccd_back_image, '') LIKE 'https://_%'));
  END IF;
END $$;
COMMIT;
