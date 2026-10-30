"""Read-only reconciliation, plus one idempotent simulated QR request via API."""
import json,re,sys,urllib.request
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import psycopg
from demo_seed import validate_target

def main():
    with psycopg.connect('host=127.0.0.1 port=55433 user=postgres dbname=thoxay_defense_demo') as c:
        validate_target(c); q=c.cursor()
        q.execute('''SELECT count(*) FROM wallet_accounts a LEFT JOIN (
          SELECT user_id,sum(main_delta) m,sum(escrow_delta) e,sum(held_delta) h
          FROM wallet_entries GROUP BY user_id) l ON a.user_id=l.user_id
          WHERE a.main_balance<>coalesce(l.m,0) OR a.escrow_balance<>coalesce(l.e,0) OR a.held_balance<>coalesce(l.h,0)''')
        assert q.fetchone()[0]==0,'Ledger balances differ'
        q.execute('''SELECT count(*) FROM users u WHERE role='ROLE_WORKER' AND
          (completed_jobs<>(SELECT count(*) FROM job_applications a JOIN jobs j ON j.id=a.job_id WHERE a.worker_id=u.id AND a.status='ACCEPTED' AND j.status='COMPLETED') OR
          abs(rating-coalesce((SELECT avg(worker_rating) FROM job_applications a JOIN jobs j ON j.id=a.job_id WHERE a.worker_id=u.id AND j.status='COMPLETED'),5))>0.00001)''')
        assert q.fetchone()[0]==0,'Ratings/completion totals differ'
        q.execute("SELECT count(*) FROM users WHERE is_verified AND (cccd_front_image IS NULL OR cccd_back_image IS NULL)")
        assert q.fetchone()[0]==0
        q.execute("SELECT count(*) FROM users WHERE full_name LIKE '[DEMO] %'");assert q.fetchone()[0]==8
        q.execute("SELECT count(*) FROM jobs WHERE status='OPEN'");assert q.fetchone()[0]>=8
    password=re.search(r'`([^`]+)`',Path('.local/demo/access.md').read_text(encoding='utf-8')).group(1)
    base='http://127.0.0.1:18083'
    def call(path,body=None,token=None):
        req=urllib.request.Request(base+path,data=json.dumps(body).encode() if body else None,headers={'Content-Type':'application/json',**({'Authorization':'Bearer '+token} if token else {})})
        with urllib.request.urlopen(req,timeout=10) as r: return json.load(r)
    session=call('/api/auth/login',{'phoneNumber':'000106000003','password':password})
    token=session['token']
    jobs=call('/api/jobs/nearby?lat=10.8015&lng=106.714&radius=20&sort=SALARY_DESC',token=token);assert len(jobs)>=6
    ranks=call('/api/workers/leaderboard?limit=3',token=token);assert len(ranks)==3 and ranks[0]['workerTier']=='DIAMOND'
    earnings=call('/api/wallet/earnings?period=MONTH',token=token);assert earnings['total']>0 and any(d['total']>0 for d in earnings['days'])
    body={'amount':250000,'clientRequestId':'demo-defense-qr-v1'}
    qr=call('/api/wallet/deposits',body,token);repeat=call('/api/wallet/deposits',body,token)
    assert qr['requestId']==repeat['requestId'] and qr['bankBin']=='000000' and qr['status']=='PENDING'
    payload=qr['payload'];crc=0xFFFF
    for b in payload[:-4].encode('ascii'):
        crc^=b<<8
        for _ in range(8): crc=((crc<<1)^0x1021 if crc&0x8000 else crc<<1)&0xFFFF
    assert payload[-4:]==f'{crc:04X}'
    inbox=call('/api/messages/inbox',token=token);assert inbox['conversations']
    print('Demo verified: 8 accounts, jobs, actual Top 3/rating averages, ledger reconciliation, daily earnings, inbox, QR CRC/idempotency. No real payments.')

if __name__=='__main__': main()
