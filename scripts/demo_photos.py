"""Fill only the isolated synthetic demo album with licensed construction photos."""
from pathlib import Path
import sys,uuid,hashlib
sys.path.insert(0,str(Path(__file__).resolve().parent))
import psycopg
from demo_seed import validate_target,illustration

PHOTOS=[('masonry','Xây tô tường'),('tiling','Thi công lát gạch'),('bathroom','Hoàn thiện WC'),('inspection','Kiểm tra công trình')]
def enrich(conn, directory):
    validate_target(conn)
    data=[(name,label,(directory/(name+'.jpg')).read_bytes()) for name,label in PHOTOS]
    if any(len(blob)>2097152 or not blob.startswith(b'\xff\xd8') for _,_,blob in data):
        raise ValueError('Expected JPEG demo photos below 2MB')
    with conn.cursor() as q:
        q.execute('SELECT pg_advisory_xact_lock(20261103,18083)')
        q.execute("SELECT id FROM users WHERE phone_number LIKE '000106%' ORDER BY id")
        owners=[row[0] for row in q.fetchall()]
        for owner in owners:
            # Replace only the exact illustration created by the original demo seed.
            q.execute("DELETE FROM portfolio_photos WHERE owner_id=%s AND caption=%s",(owner,'Ảnh minh họa tay nghề DEMO, không phải dự án thật'))
            for name,label,blob in data:
                ident=uuid.uuid5(uuid.NAMESPACE_URL,f'thoxay-demo-photo/{owner}/{name}')
                q.execute('INSERT INTO portfolio_photos(id,owner_id,caption,content) VALUES (%s,%s,%s,%s) ON CONFLICT(id) DO NOTHING',(ident,owner,label+' · Ảnh demo',blob))
        # Replace only exact original synthetic illustrations, never a user's
        # replacement photograph or approved evidence. Bump the review version.
        legacy={illustration('NHAT KY THI CONG CUOI NGAY'),illustration('TOAN CANH - DEMO')}
        legacy_detail=illustration('CHI TIET - DEMO')
        q.execute("SELECT id,photo,detail_photo,version FROM work_logs WHERE status='PENDING' AND caption LIKE '[DEMO]%%' AND attendance_id IN (SELECT a.id FROM attendance_records a JOIN job_applications ja ON ja.id=a.application_id JOIN jobs j ON j.id=ja.job_id WHERE j.title LIKE '[DEMO]%%') FOR UPDATE")
        for ident,overview,detail,version in q.fetchall():
            if bytes(overview) not in legacy or (detail is not None and bytes(detail)!=legacy_detail):continue
            q.execute("UPDATE work_logs SET photo=%s, detail_photo=%s,version=version+1 WHERE id=%s AND status='PENDING' AND version=%s",(data[0][2],data[1][2],ident,version))
    return len(owners)

if __name__=='__main__':
    with psycopg.connect('host=127.0.0.1 port=55433 user=postgres dbname=thoxay_defense_demo') as conn:
        count=enrich(conn,Path(__file__).resolve().parents[1]/'docs/demo_photos')
    print(f'Enriched {count} synthetic demo albums; no identities, approved reports, balances or production data changed.')
