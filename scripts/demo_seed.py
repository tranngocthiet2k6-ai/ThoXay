"""Synthetic defense fixtures. Refuses remote databases and all non-demo users.

Run after the normal Flyway migrations. This is deliberately NOT a startup seed.
Passwords/connection details are never committed. Re-running preserves demo edits.
"""
from __future__ import annotations
import argparse, hashlib, io, json, os, secrets, uuid
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
import bcrypt
import psycopg
from PIL import Image, ImageDraw, ImageFont

PREFIX = '[DEMO] '
DATABASE = 'thoxay_defense_demo'

def validate_target(conn):
    """Check the actual connected server, not just the supplied DSN."""
    host, db = conn.info.host, conn.info.dbname
    if host not in ('127.0.0.1', 'localhost', '::1') or db != DATABASE:
        raise ValueError('Demo seed requires the dedicated loopback database thoxay_defense_demo')
    with conn.cursor() as q:
        q.execute('SELECT host(inet_server_addr()), current_database()')
        addr, actual_db = q.fetchone()
        if addr not in ('127.0.0.1', '::1') or actual_db != DATABASE:
            raise ValueError('Connected database is not the local demo database')
        q.execute("SELECT count(*) FROM users WHERE full_name NOT LIKE '[DEMO] %%'")
        if q.fetchone()[0]:
            raise ValueError('Refusing to seed a database containing non-demo users')
        q.execute("SELECT count(*) FROM flyway_schema_history WHERE version='21' AND success")
        if q.fetchone()[0] != 1:
            raise ValueError('Start the normal Backend first so Flyway migrates through V21')

def illustration(label, kyc=False):
    # Explicitly synthetic cards, never photographs or identity documents.
    img=Image.new('RGB',(1000,630),'#0F172A')
    d=ImageDraw.Draw(img)
    font_path=Path('C:/Windows/Fonts/arialbd.ttf')
    font=ImageFont.truetype(str(font_path),48) if font_path.exists() else ImageFont.load_default(size=42)
    small=ImageFont.truetype(str(font_path),28) if font_path.exists() else ImageFont.load_default(size=24)
    d.text((64,64),'THOXAY  /  DEMO',font=font,fill='#FB923C')
    d.text((64,200),label,font=small,fill='white')
    d.text((64,320),'DU LIEU MINH HOA - KHONG CO GIA TRI THAT',font=small,fill='#CBD5E1')
    if kyc: d.text((64,430),'KHONG PHAI GIAY TO TUY THAN',font=small,fill='#FCA5A5')
    out=io.BytesIO();img.save(out,format='JPEG',quality=90);return out.getvalue()

def seed(conn, output):
    validate_target(conn)
    q=conn.cursor()
    q.execute('SELECT pg_advisory_xact_lock(20261030, 18083)')
    q.execute('SELECT count(*) FROM users')
    if q.fetchone()[0]:
        print('Demo already exists. Preserving accounts, bank configuration and demo interactions.')
        return False
    password=secrets.token_urlsafe(12)
    hashed=bcrypt.hashpw(password.encode(),bcrypt.gensalt()).decode()
    today=datetime.now(timezone(timedelta(hours=7))).date()
    now=datetime.now(timezone.utc)
    def insert(table, **data):
        from psycopg import sql
        query=sql.SQL('INSERT INTO {} ({}) VALUES ({}) RETURNING id').format(sql.Identifier(table),sql.SQL(',').join(map(sql.Identifier,data)),sql.SQL(',').join(sql.Placeholder() for _ in data))
        q.execute(query,list(data.values()));return q.fetchone()[0]
    users=[]
    roster=[('Quản trị trình diễn','ROLE_ADMIN'),('Xây dựng Minh Thành','ROLE_CONTRACTOR'),('Kiến trúc An Gia','ROLE_CONTRACTOR'),('Nguyễn Minh An','ROLE_WORKER'),('Trần Quốc Bảo','ROLE_WORKER'),('Lê Hoàng Phúc','ROLE_WORKER'),('Phạm Văn Sơn','ROLE_WORKER'),('Đỗ Thanh Tâm','ROLE_WORKER')]
    for i,(name,role) in enumerate(roster):
        uid=insert('users',phone_number=f'000106{i:06d}',password=hashed,full_name=PREFIX+name,role=role,is_verified=False,experience_years=3+i,experience_summary='Hồ sơ trình diễn tổng hợp, không đại diện người thật.',created_at=now.replace(tzinfo=None)-timedelta(days=90))
        users.append(uid)
        if role!='ROLE_ADMIN':
            faces=[]
            for side in ['MAT TRUOC','MAT SAU']:
                image_id=uuid.uuid4();q.execute('INSERT INTO kyc_images(id,user_id,content) VALUES (%s,%s,%s)',(image_id,uid,illustration(side,True)))
                faces.append('/admin/kyc/images/'+str(image_id))
            q.execute('UPDATE users SET cccd_front_image=%s,cccd_back_image=%s,is_verified=true WHERE id=%s',(*faces,uid))
            for order,skill in enumerate(['Xây tô','Ốp lát','Hoàn thiện'] if role=='ROLE_WORKER' else ['Quản lý công trình']):
                q.execute('INSERT INTO user_skills VALUES (%s,%s,%s)',(uid,order,skill))
            insert('portfolio_photos',id=uuid.uuid4(),owner_id=uid,caption='Ảnh minh họa tay nghề DEMO, không phải dự án thật',content=illustration('MINH HOA THI CONG XAY TO'))
            q.execute('INSERT INTO wallet_accounts(user_id) VALUES (%s)',(uid,))
    admin,owner,owner2,*workers=users
    balances={u:[0,0,0] for u in users[1:]}
    def ledger(uid,kind,amount,when,description,*,escrow=0,payment=None,request=None):
        delta=amount if kind in ('TOP_UP','WORK_EARNING','TIP','BONUS') else -amount
        b=balances[uid];b[0]+=delta;b[1]+=escrow
        if min(b)<0: raise AssertionError('Negative demo ledger')
        insert('wallet_entries',user_id=uid,kind=kind,amount=amount,main_delta=delta,escrow_delta=escrow,held_delta=0,main_after=b[0],escrow_after=b[1],held_after=b[2],reference='demo:'+uuid.uuid4().hex,description=description,created_at=when,payment_id=payment,request_id=request)
    for u in users[1:]:
        amount=100_000_000 if u in [owner,owner2] else 2_000_000
        req=insert('wallet_requests',user_id=u,kind='TOP_UP',status='APPROVED',amount=amount,client_request_id='demo-opening',transfer_reference='DEMO ONLY',external_reference='DEMO-'+str(u),processed_by=admin,created_at=now-timedelta(days=60),processed_at=now-timedelta(days=60),note='Số dư mô phỏng, không có chuyển tiền thật')
        ledger(u,'TOP_UP',amount,now-timedelta(days=60),'[DEMO] Số dư mở đầu mô phỏng',request=req)
        escrow=100_000 if u==workers[0] else 300_000
        ledger(u,'ESCROW_LOCK',escrow,now-timedelta(days=59),'[DEMO] Chuyển ký quỹ',escrow=escrow)
    places=[('Bình Thạnh',10.8015,106.7140),('Thủ Đức',10.8506,106.7721),('Quận 7',10.7325,106.7217),('Tân Bình',10.8011,106.6526),('Bình Tân',10.7652,106.6040),('Gò Vấp',10.8389,106.6652),('Quận 3',10.7848,106.6822),('Quận 10',10.7729,106.6685)]
    def job(title,index,status='OPEN',start=None,end=None,required=4,attendance=True,rate=650000):
        area,lat,lng=places[index%len(places)]
        return insert('jobs',contractor_id=owner if index%2==0 else owner2,title=PREFIX+title,description='Công trình minh họa phục vụ bảo vệ đồ án. Không phải tin tuyển dụng thật. Có dụng cụ bảo hộ, ca ngày và nghỉ trưa.',job_type='Thợ chính' if index%2==0 else 'Phụ hồ',salary_per_day=rate,address=f'{area}, TP. Hồ Chí Minh (vị trí minh họa khu vực)',latitude=lat,longitude=lng,required_workers=required,status=status,starts_on=start,ends_on=end,attendance_required=attendance)
    def application(j,w,status='ACCEPTED',rate=650000,when=None,stars=None):
        when=when or now
        snapshot=f'[DEMO] Cam kết mô phỏng. Lương {rate} VND/ngày. Hủy việc trừ 15 điểm uy tín. Chỉ sử dụng trong buổi bảo vệ.'
        return insert('job_applications',job_id=j,worker_id=w,status=status,agreed_daily_rate=rate if status=='ACCEPTED' else None,consent_version=1,accepted_terms_at=when,contractor_confirmed_at=when if status=='ACCEPTED' else None,contract_snapshot=snapshot if status=='ACCEPTED' else None,contract_hash=hashlib.sha256(snapshot.encode()).hexdigest() if status=='ACCEPTED' else None,worker_rating=stars,reviewed_at=when if stars else None,applied_at=(when-timedelta(hours=1)).astimezone(timezone(timedelta(hours=7))).replace(tzinfo=None))
    for wi,count in enumerate([20,10,6,3,0]):
        w=workers[wi];ratings=[]
        for n in range(count):
            day=today-timedelta(days=n+1)
            when=datetime.combine(day,datetime.min.time(),timezone(timedelta(hours=7)))+timedelta(hours=17)
            rate=650000-wi*50000;stars=4 if wi in (1,2) and n==0 else 5;ratings.append(stars)
            j=job(f'Hoàn thiện nhà phố {n+1} - {places[(n+wi)%8][0]}',n+wi,'COMPLETED',day,day,1,False,rate)
            a=application(j,w,rate=rate,when=when,stars=stars)
            payer=owner if (n+wi)%2==0 else owner2
            tip=50000 if n%3==0 else 0;bonus=100000 if n%5==0 else 0
            p=insert('job_payments',application_id=a,job_id=j,contractor_id=payer,worker_id=w,job_title=PREFIX+f'Hoàn thiện nhà phố {n+1}',work_days=1,daily_rate=rate,base=rate,tip=tip,bonus=bonus,total=rate+tip+bonus,created_at=when)
            ledger(payer,'JOB_PAYMENT',rate+tip+bonus,when,'[DEMO] Chi trả công trình',payment=p)
            ledger(w,'WORK_EARNING',rate,when,'[DEMO] Tiền công đã nghiệm thu',payment=p)
            if tip: ledger(w,'TIP',tip,when,'[DEMO] Tip từ chủ thầu',payment=p)
            if bonus: ledger(w,'BONUS',bonus,when,'[DEMO] Thưởng hoàn thành',payment=p)
            insert('reputation_events',user_id=w,job_id=j,application_id=a,job_title=PREFIX+'Hoàn thành công trình',type='JOB_COMPLETED',delta=0,score_after=100,created_at=when)
        rating=sum(ratings)/len(ratings) if ratings else 5.0
        tier='DIAMOND' if count>=20 else 'GOLD' if count>=5 else 'SILVER'
        q.execute('UPDATE users SET rating=%s,completed_jobs=%s,worker_tier=%s WHERE id=%s',(rating,count,tier,w))
    open_jobs=[]
    titles=['Xây tô nhà phố 3 tầng','Ốp lát căn hộ mới','Thi công tường rào sân vườn','Phụ hồ cải tạo văn phòng','Hoàn thiện biệt thự','Sơn sửa nhà ở','Cải tạo mặt tiền cửa hàng','Thi công phòng trọ']
    for i,title in enumerate(titles): open_jobs.append(job(title,i,start=today+timedelta(days=i+2),end=today+timedelta(days=i+4),rate=700000-i*40000))
    active=job('Nhà phố ven sông - ca trình diễn',0,'IN_PROGRESS',today,today,2,True)
    a=application(active,workers[0]);application(active,workers[1])
    attendance=insert('attendance_records',application_id=a,work_day=today,checked_in_at=now-timedelta(hours=3),checked_out_at=now-timedelta(hours=1),checkin_method='GPS',checkout_method='GPS',checkin_latitude=10.8015,checkin_longitude=106.714,checkin_accuracy=10,checkout_latitude=10.8015,checkout_longitude=106.714,checkout_accuracy=10)
    insert('work_logs',attendance_id=attendance,caption='[DEMO] Đã hoàn tất mảng tường, chờ nghiệm thu',photo=illustration('NHAT KY THI CONG CUOI NGAY'),status='PENDING')
    application(open_jobs[0],workers[2],'PENDING')
    q.execute('INSERT INTO worker_calendar_blocks(worker_id,work_day,note) VALUES (%s,%s,%s)',(workers[0],today+timedelta(days=14),'[DEMO] Nghỉ cá nhân'))
    crew=insert('crews',leader_id=workers[0],name=PREFIX+'Tổ xây tô Bình Thạnh')
    for w in workers[:3]: insert('crew_members',crew_id=crew,worker_id=w,status='CONFIRMED',confirmed_at=now)
    q.execute('INSERT INTO saved_jobs(owner_id,job_id) VALUES (%s,%s)',(workers[0],open_jobs[0]))
    q.execute('INSERT INTO saved_workers(owner_id,worker_id) VALUES (%s,%s)',(owner,workers[0]))
    for i,(sender,recipient,body) in enumerate([(owner,workers[0],'[DEMO] Ngày mai anh em tập trung tại cổng công trình nhé.'),(workers[0],owner,'[DEMO] Em đã gửi ảnh cuối ca để anh nghiệm thu.'),(owner,workers[0],'[DEMO] Cảm ơn An, tôi sẽ kiểm tra và xác nhận trong hôm nay.')]):
        insert('messages',sender_id=sender,recipient_id=recipient,job_id=active,content=body,client_message_id='demo-chat-'+str(i),created_at=now-timedelta(minutes=10-i))
    for u in users:
        insert('notifications',recipient_id=u,job_id=active,event_key='demo:welcome:'+str(u),type='JOB_ACCEPTED' if u!=admin else 'INCIDENT_REPORTED',title='[DEMO] Sẵn sàng buổi bảo vệ',body='Dữ liệu mô phỏng để minh họa quy trình ThoXay. Không có giao dịch thật.',created_at=now)
    incident=insert('incidents',job_id=active,original_job_id=active,job_title=PREFIX+'Ca trình diễn',job_address='Bình Thạnh, TP.HCM',job_latitude=10.8015,job_longitude=106.714,reporter_id=workers[0],reporter_name=roster[3][0],reporter_phone='000106000003',client_request_id='demo-safety',type='SAFETY',status='NEW',description='[DEMO] Đề nghị bổ sung dây bảo hộ trước khi làm việc trên cao.',created_at=now)
    insert('incident_audit',incident_id=incident,actor_id=workers[0],status='NEW',note='[DEMO] Tiếp nhận báo cáo mô phỏng',created_at=now)
    insert('wallet_requests',user_id=workers[1],kind='WITHDRAW',amount=200000,status='PENDING',client_request_id='demo-withdraw',bank_name='DEMO KHONG CHUYEN TIEN',bank_account='0000000000',account_name='DEMO ONLY',created_at=now)
    # Reserve the withdrawal in the same synthetic ledger.
    b=balances[workers[1]];b[0]-=200000;b[2]+=200000
    insert('wallet_entries',user_id=workers[1],kind='WITHDRAW_HOLD',amount=200000,main_delta=-200000,escrow_delta=0,held_delta=200000,main_after=b[0],escrow_after=b[1],held_after=b[2],reference='demo:withdraw-hold',description='[DEMO] Giữ chỗ yêu cầu rút',created_at=now)
    for u,b in balances.items(): q.execute('UPDATE wallet_accounts SET main_balance=%s,escrow_balance=%s,held_balance=%s WHERE user_id=%s',(*b,u))
    # 000000 is intentionally not a receiving-bank configuration. Local demo only.
    q.execute("INSERT INTO receiving_bank_settings(id,enabled,bank_bin,bank_name,account_no,account_name) VALUES(1,true,'000000','DEMO KHONG CHUYEN TIEN','0000000000','DEMO ONLY') ON CONFLICT(id) DO NOTHING")
    insert('receiving_bank_audit',actor_id=admin,enabled=True,bank_bin='000000',bank_name='DEMO KHONG CHUYEN TIEN',account_no='0000000000',account_name='DEMO ONLY',revision=0,changed_at=now)
    output.mkdir(parents=True,exist_ok=True)
    access=['# ThoXay trình diễn cục bộ','', 'Web: http://127.0.0.1:3008', 'Admin: http://127.0.0.1:18083/admin/login','',f'Mật khẩu dùng cho các tài khoản demo: `{password}`','', '| Vai trò | Tên | Số điện thoại |','| --- | --- | --- |']
    for i,(name,role) in enumerate(roster): access.append(f'| {role} | {PREFIX+name} | 000106{i:06d} |')
    access+=['','Không dùng mật khẩu này cho tài khoản thật. Hồ sơ/CCCD/số dư/đánh giá đều mô phỏng. BIN 000000 không dùng thanh toán. Không chuyển tiền theo QR demo.']
    # Write secrets only after the caller successfully commits.
    return '\n'.join(access)+'\n'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',default='.local/demo');args=parser.parse_args()
    output=Path(args.output)
    with psycopg.connect(os.environ.get('THOXAY_DEMO_DSN','host=127.0.0.1 port=55433 user=postgres dbname='+DATABASE)) as conn:
        result=seed(conn,output)
    if result: (output/'access.md').write_text(result,encoding='utf-8')
    print('Demo ready. Local access details: '+str(output/'access.md'))

if __name__=='__main__': main()
