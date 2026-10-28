-- Run interactively with psql as the database owner, after registering YOUR contractor account.
\set ON_ERROR_STOP on
\prompt 'Phone number of your own registered CONTRACTOR account: ' admin_phone
BEGIN;
UPDATE users SET role = 'ROLE_ADMIN', is_available = FALSE
WHERE phone_number = :'admin_phone' AND role = 'ROLE_CONTRACTOR';
SELECT id, full_name, phone_number, role FROM users WHERE phone_number = :'admin_phone';
COMMIT;
