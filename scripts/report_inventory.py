import json,re,os,hashlib
from pathlib import Path
import psycopg
c=psycopg.connect(os.environ.get('THOXAY_REPORT_DSN','host=127.0.0.1 port=55433 user=postgres dbname=thoxay_upgrade_qa'))
c.read_only=True
q=c.cursor()
q.execute("SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename")
tables={}
for (table,) in q.fetchall():
    if table=='flyway_schema_history': continue
    q.execute("""SELECT a.attname,format_type(a.atttypid,a.atttypmod),a.attnotnull,
    pg_get_expr(d.adbin,d.adrelid),col_description(a.attrelid,a.attnum)
    FROM pg_attribute a LEFT JOIN pg_attrdef d ON a.attrelid=d.adrelid AND a.attnum=d.adnum
    WHERE a.attrelid=%s::regclass AND a.attnum>0 AND NOT a.attisdropped ORDER BY a.attnum""",(table,))
    cols=[dict(zip(['name','type','required','default','comment'],r)) for r in q.fetchall()]
    q.execute("SELECT conname,contype,pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=%s::regclass ORDER BY contype,conname",(table,))
    tables[table]={'columns':cols,'constraints':[dict(zip(['name','kind','definition'],r)) for r in q.fetchall()]}
routes=[]
for p in sorted(Path('src/main/java').rglob('*Controller.java')):
    text=p.read_text(encoding='utf-8')
    head=text.split('public class')[0]
    base=re.search(r'@RequestMapping\("([^"]*)"\)',head)
    base=base.group(1) if base else ''
    for m in re.finditer(r'@(Get|Post|Put|Delete|Patch)Mapping(?:\(([^\n]*?)\))?(?=\s|@)',text):
        args=m.group(2) or ''
        # HTTP methods in this project use either a literal or a literal array.
        before=args.split('consumes=')[0].split('produces=')[0]
        paths=re.findall(r'"([^"]*)"',before) or ['']
        method=re.search(r'public\s+[^\n]*?\s+(\w+)\s*\(',text[m.end():])
        for path in paths:
            routes.append({'controller':p.stem,'method':m.group(1).upper(),'path':base+path,'handler':method.group(1) if method else '', 'source':p.as_posix()})
data={'tables':tables,'routes':routes,'counts':{'tables':len(tables),'rest':sum(r['path'].startswith('/api/') for r in routes),'mvc':sum(not r['path'].startswith('/api/') for r in routes)}}
data['schema_sha256']=hashlib.sha256(Path('schema.sql').read_bytes()).hexdigest()
data['controller_sha256']={p.as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(Path('src/main/java').rglob('*Controller.java'))}
data['counts']['columns']=sum(len(t['columns']) for t in tables.values())
data['counts']['controllers']=len(data['controller_sha256'])
Path('docs/PROJECT_INVENTORY.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(data['counts'])
