ALTER TABLE jobs ADD COLUMN IF NOT EXISTS ratings_finalized_at TIMESTAMPTZ;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;

UPDATE job_applications a SET paid_at=p.created_at
 FROM job_payments p WHERE p.application_id=a.id AND a.paid_at IS NULL;
UPDATE jobs j SET ratings_finalized_at=COALESCE(
 (SELECT MIN(a.reviewed_at) FROM job_applications a WHERE a.job_id=j.id AND a.worker_rating IS NOT NULL),CURRENT_TIMESTAMP)
 WHERE j.ratings_finalized_at IS NULL AND EXISTS
 (SELECT 1 FROM job_applications a WHERE a.job_id=j.id AND a.worker_rating IS NOT NULL);
UPDATE jobs SET recruitment_closed=TRUE WHERE ratings_finalized_at IS NOT NULL;

-- A legacy completion without every accepted worker's payment is still active.
UPDATE jobs j SET status='IN_PROGRESS'
 WHERE j.status='COMPLETED' AND j.ratings_finalized_at IS NOT NULL AND EXISTS
 (SELECT 1 FROM job_applications a WHERE a.job_id=j.id AND a.status='ACCEPTED'
  AND NOT EXISTS (SELECT 1 FROM job_payments p WHERE p.application_id=a.id));

-- Rebuild derived experience and stars; preserve money and reputation audit events.
UPDATE users u SET rating=COALESCE(
 (SELECT AVG(a.worker_rating) FROM job_applications a JOIN jobs j ON j.id=a.job_id
  WHERE a.worker_id=u.id AND a.status='ACCEPTED' AND j.status='COMPLETED'),5.0),
 completed_jobs=(SELECT COUNT(*) FROM job_applications a JOIN jobs j ON j.id=a.job_id
  WHERE a.worker_id=u.id AND a.status='ACCEPTED' AND a.worker_rating IS NOT NULL AND j.status='COMPLETED')
 WHERE u.role='ROLE_WORKER' AND EXISTS
 (SELECT 1 FROM job_applications a JOIN jobs j ON j.id=a.job_id WHERE a.worker_id=u.id AND j.ratings_finalized_at IS NOT NULL);
UPDATE users u SET worker_tier=CASE
 WHEN reputation_score>=95 AND completed_jobs>=20 AND rating>=4.7 AND is_verified THEN 'DIAMOND'
 WHEN reputation_score>=80 AND completed_jobs>=5 AND rating>=4.0 THEN 'GOLD'
 WHEN reputation_score>=60 AND completed_jobs>=1 AND rating>=3.0 THEN 'SILVER'
 ELSE 'BRONZE' END
 WHERE u.role='ROLE_WORKER' AND EXISTS
 (SELECT 1 FROM job_applications a JOIN jobs j ON j.id=a.job_id WHERE a.worker_id=u.id AND j.ratings_finalized_at IS NOT NULL);
