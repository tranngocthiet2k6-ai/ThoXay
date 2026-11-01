"""Append a dated, synthetic presentation scenario to the dedicated local demo only.

Preserves existing users, bank settings, balances, ledger, ratings and earlier demos.
Uses the same fail-closed target guards as the initial seed; safe to run twice.
"""
import hashlib,sys
from datetime import datetime,timedelta,timezone
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import psycopg
from psycopg import sql
from demo_seed import validate_target,illustration

def refresh(conn):
    validate_target(conn)
    with conn.cursor() as q:
        q.execute("SELECT count(*) FROM flyway_schema_history WHERE success AND version='22'")
        if q.fetchone()[0]!=1:raise ValueError('Start the updated demo Backend through Flyway V22 first')
        q.execute('SELECT pg_advisory_xact_lock(20261102,18083)')
        today=datetime.now(timezone(timedelta(hours=7))).date()
        title=f'[DEMO] Ca bảo vệ {today.isoformat()}'
        q.execute('SELECT id FROM jobs WHERE title=%s',(title,))
        if q.fetchone():return False
        def account(index):
            q.execute('SELECT id FROM users WHERE phone_number=%s',(f'000106{index:06}',))
            row=q.fetchone()
            if not row:raise ValueError('Expected the existing eight synthetic demo accounts')
            return row[0]
        def insert(table,**values):
            q.execute(sql.SQL('INSERT INTO {} ({}) VALUES ({}) RETURNING id').format(sql.Identifier(table),sql.SQL(',').join(map(sql.Identifier,values)),sql.SQL(',').join(sql.Placeholder() for _ in values)),list(values.values()))
            return q.fetchone()[0]
        now=datetime.now(timezone.utc);vn=timezone(timedelta(hours=7))
        owner=account(1);workers=[account(i) for i in [3,4,5,6]]
        start=today-timedelta(days=1);end=today+timedelta(days=2)
        job=insert('jobs',contractor_id=owner,title=title,description='[DEMO] Công trình trình diễn hai ảnh cuối ca, nghiệm thu và đánh giá. Dữ liệu tổng hợp.',job_type='Thợ chính',salary_per_day=650000,address='Bình Thạnh, TP.HCM (địa điểm minh họa)',latitude=10.8015,longitude=106.714,required_workers=2,status='IN_PROGRESS',starts_on=start,ends_on=end,attendance_required=True,created_at=(now-timedelta(days=3)).astimezone(vn).replace(tzinfo=None))
        applications=[]
        snapshot=f'[DEMO] {title}. Lịch {start}–{end}. Lương 650000 VND/ngày; hủy việc trừ 15 điểm uy tín. Mô phỏng, không có giá trị pháp lý.'
        for worker in workers[:2]:
            applications.append(insert('job_applications',job_id=job,worker_id=worker,status='ACCEPTED',agreed_daily_rate=650000,consent_version=1,accepted_terms_at=now-timedelta(days=2),contractor_confirmed_at=now-timedelta(days=2),contract_snapshot=snapshot,contract_hash=hashlib.sha256(snapshot.encode()).hexdigest(),applied_at=(now-timedelta(days=2,hours=1)).astimezone(vn).replace(tzinfo=None)))
        began=datetime.combine(start,datetime.min.time(),tzinfo=vn).replace(hour=8)
        record=insert('attendance_records',application_id=applications[0],work_day=start,checked_in_at=began,checked_out_at=began+timedelta(hours=9),checkin_method='GPS',checkout_method='GPS',checkin_latitude=10.8015,checkin_longitude=106.714,checkout_latitude=10.8015,checkout_longitude=106.714,checkin_accuracy=8,checkout_accuracy=8)
        insert('work_logs',attendance_id=record,photo=illustration('TOAN CANH - DEMO'),detail_photo=illustration('CHI TIET - DEMO'),caption='[DEMO] Hai ảnh minh họa toàn cảnh và chi tiết, chờ Chủ thầu nghiệm thu.',status='PENDING',created_at=began+timedelta(hours=9,minutes=10))
        opening=insert('jobs',contractor_id=owner,title=f'[DEMO] Tuyển thợ bảo vệ {today.isoformat()}',description='[DEMO] Tin để trình diễn duyệt ứng viên, xem tay nghề và thương lượng.',job_type='Thợ chính',salary_per_day=500000,address='Bình Thạnh, TP.HCM (địa điểm minh họa)',latitude=10.806,longitude=106.717,required_workers=3,status='OPEN',starts_on=today+timedelta(days=3),ends_on=today+timedelta(days=5),attendance_required=True)
        for worker in workers[2:]:insert('job_applications',job_id=opening,worker_id=worker,status='PENDING',proposed_daily_rate=550000,wage_note='[DEMO] Đề xuất theo kinh nghiệm xây tô.',consent_version=1,accepted_terms_at=now)
        return True

if __name__=='__main__':
    with psycopg.connect('host=127.0.0.1 port=55433 user=postgres dbname=thoxay_defense_demo') as connection:
        created=refresh(connection)
    print('Fresh dated DEMO scenario added; no balances or ratings changed.' if created else 'Dated DEMO scenario already exists; preserved unchanged.')
