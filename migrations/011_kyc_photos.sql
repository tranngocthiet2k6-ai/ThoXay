-- Private uploads are served only to the account owner or a logged-in Admin.
BEGIN;
CREATE TABLE IF NOT EXISTS kyc_images (
  id UUID PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content BYTEA NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_kyc_images_user ON kyc_images(user_id);
ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_verified_cccd_faces;
ALTER TABLE users ADD CONSTRAINT chk_users_verified_cccd_faces CHECK (NOT is_verified OR
  ((COALESCE(cccd_front_image, '') LIKE 'https://_%' OR COALESCE(cccd_front_image, '') LIKE '/admin/kyc/images/%')
   AND (COALESCE(cccd_back_image, '') LIKE 'https://_%' OR COALESCE(cccd_back_image, '') LIKE '/admin/kyc/images/%')));
COMMIT;
