"""Build the report from audited catalog metadata and existing introductory chapters."""
import json,re,subprocess,zipfile
from pathlib import Path
from collections import defaultdict

root=Path(__file__).resolve().parents[1]
catalog=json.loads((root/'docs/PROJECT_INVENTORY.json').read_text(encoding='utf-8'))
tables=catalog['tables'];routes=catalog['routes']
target=root/'docs/BAO_CAO_DO_AN.md'
old=target.read_text(encoding='utf-8')
intro=old[old.index('# Chương 1.'):old.index('<a id="chuong-3">')]
intro=intro.split('### Công nghệ bổ sung trong đợt nâng cấp')[0].rstrip()+'\n'
intro=intro.replace('Lưu 14 bảng','Lưu 30 bảng').replace('ba template dashboard, login và wallet','9 template quản trị và đăng nhập')
intro=intro.replace('GPS dùng làm tâm truy vấn tìm việc; chưa có theo dõi vị trí thợ liên tục hoặc điều phối cuốc việc tự động.','GPS dùng làm tâm tìm việc và kiểm tra chấm công trong bán kính 200m; chưa theo dõi vị trí thợ liên tục hoặc tự điều phối cuốc việc.')
intro=intro.replace('FCM có mã tích hợp nhưng cần Firebase riêng; cấu hình triển khai hiện ghi nhận FCM tắt.','FCM có mã tích hợp nhưng cần Firebase riêng; bản demo tắt FCM.')
intro=intro.replace('Quản lý hồ sơ mở rộng, CCCD hai mặt, điểm uy tín, bậc thợ và lịch sử thông báo.','Quản lý hồ sơ mở rộng, CCCCD hai mặt, điểm uy tín, bậc thợ và lịch sử thông báo.\n- Hỗ trợ tổ đội thực, cam kết điện tử, thương lượng lương, lịch chống trùng, chấm công và nghiệm thu ảnh.\n- Tiếp nhận sự cố/SOS ưu tiên, quản lý bộ sưu tập tay nghề, mục yêu thích, chia sẻ công trình và thời tiết.').replace('CCCCD','CCCD')
# Keep repeat generation stable.
intro=intro.replace('\n- Hỗ trợ tổ đội thực, cam kết điện tử, thương lượng lương, lịch chống trùng, chấm công và nghiệm thu ảnh.\n- Tiếp nhận sự cố/SOS ưu tiên, quản lý bộ sưu tập tay nghề, mục yêu thích, chia sẻ công trình và thời tiết.\n- Hỗ trợ tổ đội thực, cam kết điện tử, thương lượng lương, lịch chống trùng, chấm công và nghiệm thu ảnh.\n- Tiếp nhận sự cố/SOS ưu tiên, quản lý bộ sưu tập tay nghề, mục yêu thích, chia sẻ công trình và thời tiết.','\n- Hỗ trợ tổ đội thực, cam kết điện tử, thương lượng lương, lịch chống trùng, chấm công và nghiệm thu ảnh.\n- Tiếp nhận sự cố/SOS ưu tiên, quản lý bộ sưu tập tay nghề, mục yêu thích, chia sẻ công trình và thời tiết.')
def count(path,pattern):return len(list((root/path).rglob(pattern)))
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
out=[]
def add(s=''):out.append(s.strip()+'\n')
def table(headers,rows):
    def escape(v):return str(v).replace('|','/').replace('\n',' ')
    add('| '+' | '.join(headers)+' |\n| '+' | '.join('---' for _ in headers)+' |\n'+'\n'.join('| '+' | '.join(map(escape,r))+' |' for r in rows))
def diagram(name,code,caption):add(f'<!-- diagram:{name} -->\n```mermaid\n{code.strip()}\n```\n\n*{caption}*')

add('# BÁO CÁO ĐỒ ÁN TỐT NGHIỆP\n\n## Ứng dụng di động kết nối lao động phổ thông và chủ thầu ThoXay')
add(f'Ngày chốt số liệu: **30/10/2026**, múi giờ Việt Nam. Nhánh **main**, checkpoint mã nguồn **{commit}**. Báo cáo mô tả phiên bản đã thực thi và bằng chứng kiểm thử, không sử dụng số liệu người dùng hoặc giao dịch thật để minh họa.')
add('## Tóm tắt\n\nThoXay kết nối Thợ, Chủ thầu và Admin trong quy trình tìm việc theo vị trí, tuyển dụng có cam kết, quản lý ca làm, nghiệm thu ảnh, đánh giá và thanh toán nội bộ. Flutter chia sẻ mã nguồn Android/Web. Spring Boot cung cấp REST/WebSocket và Thymeleaf Admin. PostgreSQL lưu dữ liệu, Flyway quản lý nâng cấp. Vercel phục vụ Web, Render chạy Backend/Admin và database, GitHub Actions kiểm thử và tạo APK.')
table(['Chỉ tiêu kiểm kê','Giá trị'],[
('Bảng nghiệp vụ / cột',f"{len(tables)} / {sum(len(t['columns']) for t in tables.values())}"),
('Bảng kỹ thuật Flyway','1, không tính trong 30 bảng nghiệp vụ'),
('Controller / ánh xạ HTTP',f"{catalog['counts']['controllers']} / {len(routes)}"),
('REST dưới /api/ / route khác',f"{catalog['counts']['rest']} / {catalog['counts']['mvc']}"),
('Tệp Java sản xuất / Dart lib / màn hình Flutter',f"{count('src/main/java','*.java')} / {count('mobile_app/lib','*.dart')} / {count('mobile_app/lib/screens','*.dart')}"),
('Template Thymeleaf',count('src/main/resources/templates','*.html')),
('Kiểm thử thành công','125 Backend + 110 Flutter + 12 JS; thêm 6 test bảo vệ seed Python'),
('Mốc trước đợt hoàn thiện','125 Backend + 108 Flutter + 12 JS; tăng 2 regression test Flutter')])
add('## Phương pháp và giới hạn số liệu\n\nPROJECT_INVENTORY.json được tạo bằng truy vấn chỉ đọc catalog PostgreSQL sau Flyway V21 và quét annotation controller trong Java. Một cặp HTTP method và đường dẫn cụ thể được tính là một endpoint. Alias health được tính riêng. Bộ đếm không tính handler mặc định của Spring, WebSocket hoặc filter đăng nhập form. Bảng user_skills và user_project_images là collection table JPA. Các kiểm thử báo cáo là số test thực chạy, không phải tỷ lệ bao phủ mã nguồn. Các ảnh DEMO và số dư minh họa không chứng minh danh tính hoặc doanh thu thực tế.')
add('## Mục lục\n\n1. Tổng quan đề tài\n2. Công nghệ sử dụng\n3. Phân tích và thiết kế hệ thống\n4. Triển khai và kiểm thử\n5. Kết luận và hướng phát triển\n6. Tài liệu đối chiếu')
add(intro)
add('### Công nghệ bổ sung trong đợt nâng cấp\n\nFlyway Core và Flyway PostgreSQL dùng version do Spring Boot parent quản lý; script đóng gói thực tế kiểm chứng thư viện trong JAR. mobile_scanner hỗ trợ quét mã ca làm, qr_flutter tạo QR phía client từ payload server. Ảnh được chuẩn hóa bằng Java ImageIO, lưu BYTEA và chỉ trả qua endpoint có kiểm tra quyền. Open-Meteo cung cấp thời tiết tham khảo; cache và timeout nằm trong Backend. Plus Jakarta Sans được đóng gói cùng Flutter theo giấy phép OFL.')
jar=root/'.local/advanced-target/tho-xay-1.0.0.jar'
if jar.exists():
    with zipfile.ZipFile(jar) as z:
        libs=[Path(n).name for n in z.namelist() if n.startswith('BOOT-INF/lib/') and re.search(r'(flyway|jjwt-api|spring-security-core|thymeleaf-|postgresql-)',n)]
    add('Các artifact resolve kiểm chứng từ JAR: '+', '.join('`'+n+'`' for n in libs)+'.')

add('<a id="chuong-3"></a>\n\n# Chương 3. Phân tích và thiết kế hệ thống')
add('## 3.1. Yêu cầu chức năng theo vai trò')
roles={
'Thợ':['Đăng ký/đăng nhập, khôi phục phiên, đổi Sáng/Tối/Outdoor và nhận việc Online/Offline.','Cập nhật thông tin cá nhân, kinh nghiệm/kỹ năng, chụp CCCD hai mặt, quản lý ảnh tay nghề.','Tìm công trình theo GPS/Haversine, bán kính và loại thợ, sắp xếp lương, xem bản đồ, lưu/chia sẻ và chỉ đường.','Ứng tuyển cá nhân hoặc tổ đội đã xác nhận, đề xuất lương, đọc và xác nhận phiên bản cam kết, quản lý lịch bận.','Liên lạc và chat chữ/ảnh/GPS với chủ thầu khi ACCEPTED, xem hộp thư và tin chưa đọc.','Chấm công GPS hoặc QR ca làm, chốt ca trong ngày Việt Nam, gửi ảnh cuối ca để nghiệm thu.','Xem sao, uy tín, bậc và bảng xếp hạng, thu nhập theo ngày/tuần/tháng; nạp/rút/ký quỹ nội bộ.','Gửi sự cố/SOS, xem phản hồi riêng từ Admin, hủy việc đã nhận với phạt trừ 15 điểm.'],
'Chủ thầu':['Đăng ký/đăng nhập, cập nhật hồ sơ/CCCD và danh mục ảnh của mình.','Đăng/sửa công trình còn tuyển, đặt ngày và tọa độ trên bản đồ, chọn số lượng thợ.','Xem hồ sơ và ảnh tay nghề, lưu thợ quen, quyết định giá gốc/giá thương lượng.','Duyệt cá nhân/tổ đội nguyên nhóm với khóa giao dịch, đủ công suất, đồng thuận và không trùng lịch.','Đọc cam kết chốt, liên lạc/chat với người đã nhận, phát QR ca làm, theo dõi chấm công và nghiệm thu ảnh.','Hoàn thành công trình, chấm sao đúng toàn bộ thợ ACCEPTED, thanh toán ngày công/tip/thưởng từ ví.','Theo dõi công trình/thời tiết, quản lý ví và gửi sự cố của mình.'],
'Admin':['Đăng nhập bằng form và phiên, xem KPI tài khoản/công trình/tỷ lệ KYC.','Lọc/tìm tài khoản, duyệt hai mặt CCCD trong modal và lightbox, chặn duyệt nhầm snapshot đã thay đổi.','Khóa tài khoản thường, chặn thao tác khóa mọi Admin cả frontend và service.','Xem công trình/cam kết/chấm công/ảnh tay nghề theo quyền quản trị, xóa công trình và tính lại sao liên quan.','Đối soát yêu cầu nạp/rút, xem ledger, cấu hình tài khoản nhận VietQR kèm xác nhận/version/audit.','Xem hàng chờ sự cố ưu tiên SOS, xử lý có ghi chú/version và audit, thông báo kết quả cho người báo.']}
for role,features in roles.items(): add('### '+role+'\n\n'+'\n'.join('- '+f for f in features))
add('## 3.2. Sơ đồ Use Case\n\nMermaid không có cú pháp UML Use Case chuyên dụng. Các flowchart dưới đây biểu diễn tác nhân và nhóm ca sử dụng; đường nối chỉ quan hệ sử dụng, không phải luồng dữ liệu hoặc quan hệ kế thừa.')
diagram('use-case','''flowchart LR
 worker["Thợ"] --> discover["Tìm việc và bản đồ"]
 worker --> work["Ứng tuyển, tổ đội và ca làm"]
 worker --> profile["Hồ sơ, KYC và uy tín"]
 worker --> communication["Chat và thông báo"]
 worker --> money["Ví và thu nhập"]
 worker --> safety["Sự cố và SOS"]
 contractor["Chủ thầu"] --> recruiting["Đăng việc và tuyển dụng"]
 contractor --> work
 contractor --> communication
 contractor --> money
 contractor --> safety
 admin["Admin"] --> moderation["Duyệt KYC và quản trị"]
 admin --> reconciliation["Đối soát ví và ngân hàng"]
 admin --> safety
 classDef labor fill:#fff1e8,stroke:#EA580C,color:#172033
 classDef business fill:#ecfdf5,stroke:#059669,color:#172033
 classDef control fill:#e2e8f0,stroke:#0F172A,color:#172033
 class worker labor
 class contractor business
 class admin control''','Hình 3.1. Tác nhân và nhóm chức năng tổng quát')
for slug,role in [('tho','Thợ'),('chu-thau','Chủ thầu'),('admin','Admin')]:
    labels={
    'tho':['Hồ sơ và hai ảnh CCCD','GPS, bản đồ, bán kính và lưu việc','Thương lượng và cam kết','Tổ đội và lịch làm việc','Chấm công, QR và ảnh cuối ca','Chat ảnh và vị trí','Sao, bậc và bảng xếp hạng','Ví, ký quỹ và thu nhập','Hủy việc, sự cố và SOS'],
    'chu-thau':['Đăng và sửa công trình trên bản đồ','Hồ sơ và hai ảnh CCCD','Duyệt thợ hoặc nguyên tổ','Chốt lương và cam kết','Phát QR và nghiệm thu ảnh','Chat với thợ đã được nhận','Hoàn thành và đánh giá','Thanh toán công, tip và thưởng','Ví, thợ quen và sự cố'],
    'admin':['Dashboard và KPI','KYC modal và lightbox','Khóa tài khoản thường','Quản lý công trình và cam kết','Xem chấm công và ảnh','Đối soát nạp rút','Cấu hình ngân hàng VietQR','Xử lý SOS và tranh chấp']}
    code='flowchart LR\n actor["'+role+'"]\n'+'\n'.join(f' actor --> case{i}["{v}"]' for i,v in enumerate(labels[slug]))
    diagram('use-case-'+slug,code,'Sơ đồ chức năng của '+role)

add('## 3.3. Mô hình dữ liệu và ERD\n\nDatabase có 30 bảng nghiệp vụ. Flyway tạo thêm flyway_schema_history để theo dõi migration, không phải entity nghiệp vụ. Sơ đồ tổng quan giữ toàn bộ bảng và khóa ngoại. Các sơ đồ theo phân hệ trình bày cột khóa/chính yếu để dễ đọc; từ điển ở mục 3.4 liệt kê đầy đủ cột, kiểu và ràng buộc. Ký hiệu FK rỗng thể hiện quan hệ có thể không tồn tại sau xóa theo SET NULL.')
groups={
'ho-so':['users','kyc_images','user_skills','user_project_images','portfolio_photos'],
'tuyen-dung':['jobs','job_applications','worker_calendar_blocks','crews','crew_members','crew_batches','saved_jobs','saved_workers'],
'tai-chinh':['wallet_accounts','wallet_requests','job_payments','wallet_entries','receiving_bank_settings','receiving_bank_audit'],
'van-hanh':['attendance_records','attendance_shift_codes','work_logs'],
'thong-bao':['messages','message_attachments','chat_read_states','notifications','device_tokens'],
'uy-tin':['reputation_events','incidents','incident_audit']}
def relationships(selected):
    lines=[]
    for name in selected:
        for con in tables[name]['constraints']:
            if con['kind']!='f':continue
            m=re.search(r'FOREIGN KEY \(([^)]+)\) REFERENCES (\w+)\(([^)]+)\)',con['definition'])
            if not m:continue
            col,parent,_=m.groups()
            if parent not in tables:continue
            required=next(c['required'] for c in tables[name]['columns'] if c['name']==col)
            # One attachment per message, one wallet per user; other children can have many.
            singular=any(c['kind'] in ('p','u') and re.search(r'\('+re.escape(col)+r'\)',c['definition']) for c in tables[name]['constraints'])
            lines.append(f' {parent} '+('||' if required else '|o')+'--'+('o|' if singular else 'o{')+f' {name} : "{col}"')
    return lines
overview=[]
def er_type(column):
    t=column['type']
    if t.startswith('character varying'):return 'varchar'
    return {'double precision':'float8','timestamp with time zone':'timestamptz','timestamp without time zone':'timestamp'}.get(t,t.split('(')[0].replace(' ','_'))
for name,t in tables.items():
    primary=next(c['definition'] for c in t['constraints'] if c['kind']=='p')
    fields=re.search(r'\(([^)]+)\)',primary).group(1).split(', ')
    overview.append(' '+name+' {\n'+'\n'.join('  '+er_type(next(c for c in t['columns'] if c['name']==f))+' '+f+' PK' for f in fields)+'\n }')
diagram('erd','erDiagram\n'+'\n'.join(overview)+'\n'+'\n'.join(relationships(list(tables))),'ERD tổng quan 30 bảng. Ảnh PNG gốc trong docs/diagrams/erd.png có thể phóng to khi tra cứu.')
for group,names in groups.items():
    refs=set(names)
    for name in names:
        for con in tables[name]['constraints']:
            if con['kind']=='f':
                m=re.search(r'REFERENCES (\w+)\(',con['definition'])
                if m:refs.add(m.group(1))
    code=['erDiagram']
    for name in sorted(refs):
        fields=[c for c in tables[name]['columns'] if c['name']=='id' or c['name'].endswith('_id') or c['name'] in ('status','kind','amount','rating','worker_tier','work_day','main_balance','is_verified','enabled')]
        code.append(' '+name+' {')
        for c in fields[:8]:
            typ=er_type(c)
            code.append('  '+typ+' '+c['name'])
        code.append(' }')
    code+=relationships(names)
    diagram('erd-'+group,'\n'.join(code),'ERD phân hệ '+group.replace('-',' '))

descriptions={
'users':'Tài khoản, vai trò, trạng thái, hồ sơ, KYC và thông số uy tín.',
'jobs':'Công trình, chủ thầu, mức lương, tọa độ, lịch và yêu cầu chấm công.',
'job_applications':'Đơn ứng tuyển cá nhân, thương lượng, đồng thuận, cam kết chốt, sao và hủy việc.',
'kyc_images':'Ảnh CCCD riêng tư đã được chuẩn hóa, truy cập có kiểm tra quyền.',
'user_skills':'Danh sách kỹ năng có thứ tự của tài khoản.',
'user_project_images':'URL ảnh dự án legacy có thứ tự, giữ tương thích dữ liệu cũ.',
'portfolio_photos':'Ảnh tay nghề upload riêng tư, tối đa 12 ảnh mỗi chủ hồ sơ.',
'worker_calendar_blocks':'Ngày bận do thợ tự khai, khóa duy nhất theo thợ/ngày.',
'crews':'Tổ đội do một thợ làm tổ trưởng.',
'crew_members':'Lời mời và trạng thái xác nhận của các tài khoản thợ thực.',
'crew_batches':'Một đợt ứng tuyển nguyên tổ vào công trình.',
'saved_jobs':'Công trình yêu thích riêng của thợ.',
'saved_workers':'Thợ quen riêng của chủ thầu.',
'attendance_records':'Một ca/ngày theo đơn, check-in/out và chứng cứ GPS/QR.',
'attendance_shift_codes':'Hash mã ca làm đang còn hiệu lực cho một công trình.',
'work_logs':'Ảnh báo cáo cuối ca, phản hồi nghiệm thu và version chống ghi đè.',
'receiving_bank_settings':'Cấu hình ngân hàng nhận tiền duy nhất, mặc định không bật QR.',
'receiving_bank_audit':'Lịch sử cấu hình nhận tiền và người thực hiện.',
'wallet_accounts':'Số dư chính, ký quỹ và tiền giữ chỗ rút của từng tài khoản.',
'wallet_requests':'Yêu cầu nạp/rút, trạng thái Admin và snapshot VietQR.',
'wallet_entries':'Sổ giao dịch với delta từng ngăn tiền, số dư sau và khóa tham chiếu chống lặp.',
'job_payments':'Thanh toán công trình một lần cho mỗi đơn, công/tip/thưởng đã chốt.',
'messages':'Tin chữ/ảnh/GPS giữa hai người gắn với công trình.',
'message_attachments':'Nội dung ảnh tin nhắn, cùng giao dịch với message và xóa cascade.',
'chat_read_states':'Con trỏ tin đã đọc tăng đơn điệu theo người/công trình/đối tác.',
'notifications':'Lịch sử thông báo và outbox thử gửi FCM.',
'device_tokens':'FCM token thiết bị, hash để định danh và last-seen.',
'reputation_events':'Sự kiện hoàn thành/hủy việc và điểm uy tín sau thay đổi.',
'incidents':'Báo cáo riêng tư với snapshot công trình/người báo và độ ưu tiên.',
'incident_audit':'Lịch sử trạng thái xử lý sự cố và ghi chú của Admin.'}
column_desc={
'id':'Khóa định danh bản ghi.','user_id':'Tài khoản sở hữu hoặc nhận dữ liệu.','owner_id':'Chủ sở hữu dữ liệu.','worker_id':'Tài khoản thợ liên quan.','contractor_id':'Chủ thầu liên quan.','job_id':'Công trình liên quan.','application_id':'Đơn ứng tuyển liên quan.','recipient_id':'Người nhận.','sender_id':'Người gửi.',
'full_name':'Họ tên hiển thị.','phone_number':'Số điện thoại dùng đăng nhập, duy nhất.','password':'Mật khẩu băm BCrypt, không trả cho client.','role':'ROLE_WORKER, ROLE_CONTRACTOR hoặc ROLE_ADMIN.','is_active':'Cờ hoạt động; false chặn cả JWT cũ.','is_available':'Cờ thợ sẵn sàng nhận việc.','is_verified':'KYC được Admin duyệt, yêu cầu đủ hai ảnh.','cccd_image':'Liên kết ảnh CCCD legacy.','cccd_front_image':'Tham chiếu ảnh CCCD mặt trước.','cccd_back_image':'Tham chiếu ảnh CCCD mặt sau.',
'rating':'Trung bình sao từ công trình COMPLETED; mặc định 5.0 nếu chưa có sao.','reputation_score':'Điểm uy tín từ 0 đến 100.','worker_tier':'Bậc SILVER, GOLD hoặc DIAMOND.','completed_jobs':'Số công trình hoàn thành được ghi nhận.','cancelled_jobs':'Số lần hủy việc đã nhận.','date_of_birth':'Ngày sinh.','experience_years':'Số năm kinh nghiệm.','experience_summary':'Mô tả kinh nghiệm.','sort_order':'Thứ tự trong collection.','skill':'Tên kỹ năng.','image_url':'URL ảnh dự án legacy.',
'content':'Nội dung tin nhắn hoặc byte ảnh tùy bảng.','photo':'Byte ảnh công việc chuẩn hóa JPEG.','caption':'Chú thích ảnh.','title':'Tiêu đề hiển thị.','description':'Nội dung mô tả.','job_title':'Snapshot tên công trình.','job_type':'Thợ chính hoặc Phụ hồ.','salary_per_day':'Lương tuyển dụng gốc, VND/ngày.','address':'Địa chỉ công trình.','latitude':'Vĩ độ theo WGS84.','longitude':'Kinh độ theo WGS84.','required_workers':'Số thợ cần tuyển.','status':'Trạng thái nghiệp vụ theo CHECK ở dưới bảng.','created_at':'Thời điểm tạo.','updated_at':'Thời điểm cập nhật.','starts_on':'Ngày bắt đầu lịch công trình.','ends_on':'Ngày kết thúc, bao gồm ngày này.','terms_version':'Phiên bản điều khoản công trình.','attendance_required':'Yêu cầu ngày công phải qua chấm công/nghiệm thu trước khi trả.',
'worker_rating':'Điểm sao 1–5, chỉ đơn ACCEPTED; chốt khi COMPLETED.','reviewed_at':'Thời điểm đánh giá hoặc nghiệm thu.','proposed_daily_rate':'Lương thợ đề xuất, VND/ngày.','agreed_daily_rate':'Lương được hai bên chốt.','wage_note':'Ghi chú thương lượng.','consent_version':'Phiên bản điều khoản thợ đã đồng ý.','accepted_terms_at':'Thời điểm thợ xác nhận.','contractor_confirmed_at':'Thời điểm chủ thầu xác nhận.','contract_snapshot':'Văn bản cam kết bất biến sau duyệt.','contract_hash':'SHA256 của snapshot cam kết.','cancellation_reason':'Lý do hủy việc.','cancellation_penalty':'Điểm phạt khi hủy.','cancelled_at':'Thời điểm hủy.','applied_at':'Thời điểm ứng tuyển.','crew_batch_id':'Đợt ứng tuyển tổ đội, nếu có.','leader_id':'Thợ làm tổ trưởng.','name':'Tên hiển thị.','confirmed_at':'Thời điểm xác nhận tham gia.','work_day':'Ngày công theo giờ Việt Nam.',
'amount':'Số tiền nguyên VND.','main_balance':'Số dư khả dụng.','escrow_balance':'Tiền ký quỹ.','held_balance':'Tiền đang giữ chỗ rút.','kind':'Loại giao dịch hoặc loại tin nhắn tùy bảng.','reference':'Khóa tham chiếu chống ghi sổ trùng.','client_request_id':'Khóa idempotency từ client.','client_message_id':'Khóa idempotency tin nhắn theo người gửi.','request_id':'Yêu cầu nạp/rút liên quan.','payment_id':'Thanh toán công trình liên quan.','bank_bin':'BIN ngân hàng nhận tiền.','bank_name':'Tên ngân hàng tại thời điểm lưu.','account_no':'Số tài khoản nhận tiền.','bank_account':'Số tài khoản của yêu cầu.','account_name':'Tên chủ tài khoản.','enabled':'Bật/tắt tạo yêu cầu QR mới.','version':'Phiên bản optimistic locking.','revision':'Phiên bản cấu hình được audit.','actor_id':'Người thao tác.','changed_at':'Thời điểm thay cấu hình.','receiving_bank_bin':'Snapshot BIN khi tạo yêu cầu.','deposit_reference':'Nội dung đối soát VietQR duy nhất.','qr_payload':'Chuỗi TLV QRIBFTTA có CRC16.','transfer_reference':'Nội dung chuyển khoản.','external_reference':'Mã đối soát thực tế duy nhất do Admin ghi.','note':'Ghi chú nghiệp vụ.','processed_by':'Admin xử lý yêu cầu.','processed_at':'Thời điểm Admin chốt yêu cầu.',
'daily_rate':'Lương ngày công đã chốt.','work_days':'Ngày công được thanh toán.','base':'Tiền công bằng ngày công nhân đơn giá.','tip':'Tiền tip đã xác nhận.','bonus':'Thưởng đã xác nhận.','total':'Tổng công, tip và thưởng.','delta':'Thay đổi điểm uy tín.','score_after':'Điểm uy tín sau sự kiện.','type':'Loại sự kiện hoặc báo cáo.','read_at':'Thời điểm thông báo được đọc.','event_key':'Khóa sự kiện duy nhất chống thông báo lặp.','push_status':'Trạng thái outbox FCM.','push_attempts':'Số lần thử gửi push.','next_attempt_at':'Thời điểm đủ điều kiện thử lại.','token_hash':'Hash định danh token thiết bị/ca làm.','token':'FCM token, không phải JWT.','last_seen_at':'Thời điểm thiết bị cập nhật token.','expires_at':'Hết hạn QR ca làm.','feedback':'Phản hồi nghiệm thu.','image_hash':'SHA256 ảnh tin nhắn chuẩn hóa.','message_id':'Tin nhắn sở hữu ảnh.','peer_id':'Đối tác trong cuộc hội thoại.','last_read_message_id':'Con trỏ message đã đọc gần nhất, không giảm.',
'incident_id':'Báo cáo sự cố liên quan.','original_job_id':'ID gốc được giữ ngay cả khi công trình bị xóa.','job_address':'Snapshot địa chỉ.','job_latitude':'Snapshot vĩ độ công trình.','job_longitude':'Snapshot kinh độ công trình.','reporter_id':'Tài khoản người báo, có thể SET NULL khi xóa.','reporter_name':'Snapshot tên người báo.','reporter_phone':'Snapshot số liên lạc người báo.','reported_latitude':'Vĩ độ do người báo tự nguyện gửi.','reported_longitude':'Kinh độ do người báo tự nguyện gửi.','admin_note':'Phản hồi/kết quả xử lý từ Admin.'}
add('## 3.4. Từ điển dữ liệu đầy đủ\n\nKiểu dữ liệu dưới đây là kiểu PostgreSQL thực tế. PK: khóa chính; FK: khóa ngoại; NULL/NOT NULL: cho phép/bắt buộc có giá trị. Unique, CHECK và hành vi xóa được ghi nguyên văn từ catalog; default được nêu ở cột quy tắc. TIMESTAMP là thời gian không kèm múi giờ, TIMESTAMPTZ là thời điểm có ngữ nghĩa UTC; ngày công/thu nhập luôn được quy đổi bằng Asia/Ho_Chi_Minh ở tầng nghiệp vụ.')
for n,(name,t) in enumerate(tables.items(),1):
    add(f'### 3.4.{n}. Bảng {name}\n\n'+descriptions[name])
    rows=[]
    for c in t['columns']:
        rules=['NOT NULL' if c['required'] else 'NULL']
        for con in t['constraints']:
            if con['kind'] in ('p','f','u') and re.search(r'\b'+re.escape(c['name'])+r'\b',con['definition'].split('REFERENCES')[0]):
                key={'p':'PK','f':'FK','u':'UNIQUE'}[con['kind']]
                if con['kind'] in ('p','u') and ',' in con['definition']:key+=' nhóm'
                rules.append(key)
        if c['default'] is not None:
            default='tự tăng (sequence)' if c['default'].startswith('nextval(') else re.sub(r'::[a-z ]+(?:\[\])?$','',c['default'])
            rules.append('default '+default)
        desc=column_desc.get(c['name'])
        if desc is None:
            if c['name'].startswith('checkin_') or c['name'].startswith('checkout_'):
                desc=('Chứng cứ lúc vào ca: ' if c['name'].startswith('checkin_') else 'Chứng cứ lúc ra ca: ')+{'method':'GPS hoặc QR.','latitude':'vĩ độ.','longitude':'kinh độ.','accuracy':'độ chính xác GPS, mét.'}.get(c['name'].split('_',1)[1],c['name'])
            elif c['name'] in ('checked_in_at','checked_out_at'):desc='Thời điểm check-in/out được server ghi nhận.'
            elif c['name'].endswith('_delta'):desc='Mức thay đổi của ngăn tiền '+c['name'].replace('_delta','')+', có dấu.'
            elif c['name'].endswith('_after'):desc='Số dư ngăn '+c['name'].replace('_after','')+' sau giao dịch.'
            elif c['name']=='crew_id':desc='Tổ đội liên quan.'
            else:desc='Thuộc tính '+c['name']+' của '+name+'.'
        rows.append((c['name'],c['type'],'; '.join(rules),desc))
    table(['Cột','Kiểu PostgreSQL','Khóa và quy tắc','Ý nghĩa'],rows)
    constraints=[c['definition'] for c in t['constraints'] if c['kind'] in ('f','c','u')]
    if constraints:add('Ràng buộc tham chiếu và kiểm tra:\n\n'+'\n'.join('- `'+v+'`' for v in constraints))

add('## 3.5. Danh mục endpoint theo Controller\n\nDanh mục có 111 cặp method/path: 90 dưới /api/ và 21 route khác, gồm giao diện Admin, tài nguyên ảnh riêng tư, trang gốc và readiness /health. Phân quyền tiếp tục được service kiểm tra quyền sở hữu, trạng thái ACCEPTED và trạng thái tài khoản; biết URL không cấp quyền đọc dữ liệu. Các mutation Admin sử dụng phiên/form cần CSRF. Annotation dưới đây được đối chiếu từ Controller.java; hash tệp nguồn nằm trong PROJECT_INVENTORY.json.')
by_controller=defaultdict(list)
for r in routes:by_controller[r['controller']].append(r)
for controller,items in by_controller.items():
    add('### '+controller)
    table(['HTTP','Đường dẫn','Handler và quyền truy cập'],[(r['method'],r['path'],r['handler']+'; '+('công khai' if r['path'] in ('/','/health','/api/auth/health','/api/auth/register','/api/auth/login','/admin/login') else 'Admin, phiên/CSRF' if r['path'].startswith('/admin/') else 'JWT Admin' if r['path'].startswith('/api/admin/') else 'JWT, kiểm tra vai trò/chủ sở hữu tại service')) for r in items])
add('Các endpoint do Spring Security xử lý ngoài Controller: POST /admin/login và POST /admin/logout. WebSocket /ws/chat nâng cấp HTTP sau xác thực, kiểm tra lại quyền hội thoại; không tính như REST endpoint. Ảnh CCCD/portfolio/chat/nhật ký có ACL riêng và Cache-Control: no-store; không nhúng JWT vào URL ảnh.')
add('## 3.6. Kiến trúc module và giao dịch\n\nBackend là modular monolith: controller nhận DTO và Jakarta Validation, service kiểm tra actor/quyền và transaction, repository truy cập PostgreSQL. Các package scheduling, crew, attendance, wallet, media, incident, chat và weather tạo các ranh giới nghiệp vụ. Flutter tách model/service/screen/widget/theme; ApiService tập trung xác thực, lỗi, multipart và URL. Thymeleaf render Admin, JavaScript quản lý bộ lọc và modal nhưng quyền cuối cùng nằm trên server.')
add('Duyệt đơn khóa công trình và các worker theo thứ tự ID, ngăn vượt số lượng và nhận trùng lịch. Duyệt tổ đội xử lý nguyên nhóm trong một transaction. Chốt sao khóa các worker trước khi tính trung bình. Thanh toán khóa ví, ghi payment/ledger/số dư cùng transaction và tham chiếu duy nhất. Retry idempotent không tự đổi số tiền, ảnh hoặc nội dung; payload khác với cùng khóa bị từ chối 409. QR ca làm chỉ lưu hash và hết hạn sau 5 phút. Snapshot ngân hàng/cam kết không đổi khi thông tin nguồn thay đổi về sau.')

add('# Chương 4. Triển khai và kiểm thử\n\n## 4.1. Kiến trúc triển khai thực tế')
diagram('kien-truc','''flowchart TB
 github["GitHub main"] --> ci["GitHub Actions: test, Web, Docker, APK"]
 github --> vercel["Vercel: Flutter Web"]
 github --> render["Render: Spring Boot và Thymeleaf Admin"]
 ci --> apk["Artifact APK release"]
 browser["Trình duyệt"] --> vercel
 browser --> render
 apk --> api["REST JWT và WebSocket"]
 vercel --> api
 api --> render
 render --> postgres[("Render PostgreSQL 17")]
 render --> weather["Open-Meteo: thời tiết tham khảo"]
 render -. "cần cấu hình Firebase" .-> fcm["FCM"]
 vercel --> osm["OpenStreetMap tiles"]
 apk --> osm
 classDef platform fill:#e2e8f0,stroke:#0F172A,color:#0F172A
 class github,ci,render,postgres platform''','Kiến trúc triển khai Vercel, Render và APK. Các tích hợp ngoài được ghi đúng trạng thái cấu hình.')
add('Web production: https://thoxay.vercel.app. Backend/Admin: https://thoxay-api.onrender.com. APK release mặc định dùng HTTPS Backend, không hard-code địa chỉ LAN. Vercel build script tự chuẩn bị Flutter theo version ghim. Render Docker multi-stage chạy kiểm thử trước khi đóng gói, ứng dụng dùng user không phải root, datasource/khóa JWT nhận qua môi trường hoặc secret files. Không đưa mật khẩu, token, service account hay ảnh người dùng thật vào Git.')
add('Flyway dùng baseline 11 khi nhận database legacy đã có bảng và chạy V12–V21 theo thứ tự. Database mới chạy V1 rồi các migration tiếp theo. V1 được giữ bất biến; clean bị vô hiệu hóa. Production tắt SQL init và JPA dùng validate. Script migrations/ phục vụ đối chiếu/chạy thủ công an toàn lặp; không chạy lại seed như migration. Các chỉ mục mới hỗ trợ lịch, hàng chờ, unread và tổng hợp thu nhập.')
add('Render Free có thể cần thời gian khởi động lại. Client kiểm tra GET readiness trước thao tác nghiệp vụ, chia sẻ cùng một lượt chờ và hủy request chờ khi dispose. Chỉ health được retry có giới hạn; các POST/PUT/DELETE không tự gửi lặp. Alias /api/auth/health có CORS cho Web. Không diễn giải cold start thành tỷ lệ sẵn sàng đã được kiểm định.')
add('## 4.2. Các luồng nghiệp vụ chính')
flows=[
('KYC hai mặt','Người dùng chụp/chọn hai ảnh bằng image_picker, xem trước/phóng to và gửi multipart. Server giải mã, giới hạn kích thước/pixel, chuẩn hóa JPEG và bỏ metadata; hồ sơ quay về chưa xác thực. Admin chỉ tải ảnh khi mở modal, xem hai mặt, phóng to đối chiếu và xác nhận kèm snapshot URL đã xem. Ảnh thay đổi sau khi mở dashboard sẽ làm lượt duyệt cũ không hợp lệ. Kiểm tra ảnh tự động không thay thế xác minh danh tính bằng con người.'),
('Ví và ký quỹ 200.000đ','Ví chia main/escrow/held. Nạp tạo yêu cầu PENDING; QR chụp snapshot người nhận/số tiền/nội dung, Admin đối soát giao dịch thực tế mới cộng sổ. Rút giữ tiền ở held trước, Admin duyệt hoặc trả lại khi từ chối. Chuyển ký quỹ chỉ chuyển giữa các ngăn tiền, không tạo thu nhập. Dưới 200.000đ hiển thị cảnh báo, chưa chặn nhận việc. VietQR demo dùng BIN 000000 riêng trên database demo, không chuyển tiền thật.'),
('Đánh giá và bậc thợ','Chủ thầu của công trình IN_PROGRESS gửi sao 1–5 cho đúng toàn bộ thợ ACCEPTED, server lưu và hoàn thành cùng giao dịch. Điểm trung bình chỉ tính đánh giá từ COMPLETED, chưa được đánh giá mặc định 5.0. GOLD cần uy tín ≥80, sao ≥4.0 và ≥5 công trình. DIAMOND cần uy tín ≥95, sao ≥4.7, ≥20 công trình và KYC. Các trường hợp khác là SILVER. Bảng xếp hạng sắp bậc rồi uy tín, sao, số công trình và ID ổn định.'),
('Hủy việc và phạt 15 điểm','Thợ hủy đơn ACCEPTED phải cung cấp lý do. Server ghi CANCELLED, sự kiện uy tín, trừ 15 điểm trong giới hạn 0–100, tính lại bậc và cập nhật công suất/trạng thái công trình trong transaction. Gửi lại không trừ hai lần. Chưa có cơ chế tự trừ tiền ký quỹ khi hủy.'),
('Tuyển dụng có lịch, lương và cam kết','Chủ thầu đặt cặp ngày bắt đầu/kết thúc; thợ chọn lương đề xuất và đồng thuận đúng termsVersion. Chủ thầu quyết định giá đề xuất hoặc giá gốc. Server chặn lịch giao nhau và ngày bận trước khi nhận, lưu agreedDailyRate, bản cam kết và SHA256 bất biến. Đơn legacy được giữ tương thích, không tự tạo bằng chứng đồng thuận lịch sử.'),
('Chấm công và nghiệm thu','Thợ trong đơn ACCEPTED check-in/out bằng GPS trong 200m, độ chính xác tối đa 100m hoặc bằng mã QR ca làm hạn 5 phút. Mỗi đơn/ngày có một bản ghi. Checkout trong cùng ngày Việt Nam; ca qua đêm chưa được hỗ trợ. Thợ gửi ảnh cuối ca, chủ thầu duyệt hoặc yêu cầu bổ sung với version. Công trình mới yêu cầu đủ ca đã checkout và ảnh APPROVED trước khi thanh toán ngày công đúng số ca.'),
('Chat và thông báo','Tin nhắn chỉ mở cho cặp thợ/chủ thầu của đơn ACCEPTED. REST lưu tin, WebSocket phát sự kiện sau commit, client khử trùng theo ID. Ảnh/GPS dùng xác nhận trước khi gửi; ảnh riêng tư cùng transaction với message. Read cursor tăng đơn điệu, chỉ cập nhật khi người dùng thực sự ở cuối chat đang hiện. Thông báo lưu trong DB; FCM cần cấu hình Firebase và token thiết bị hợp lệ.'),
('SOS và thời tiết','Người dùng gửi SOS hoặc sự cố với mô tả và vị trí tự nguyện. Server lưu snapshot công trình/người báo, Admin nhận hàng chờ ưu tiên và ghi nhận xử lý/audit, người báo đọc phản hồi riêng. SOS không gọi lực lượng cứu hộ tự động. Widget thời tiết chỉ tham khảo từ Open-Meteo, có cache/stale/timeout và không khóa việc khi provider lỗi.')]
for i,(title,body) in enumerate(flows,1):add(f'### 4.2.{i}. {title}\n\n{body}')
add('## 4.3. Ma trận 18 hạng mục nâng cao\n\nĐề bài nhóm một số khả năng chung trong cùng mục. Bảng dưới tách thành 18 hạng mục nghiệm thu để đối chiếu, không coi chúng là 18 microservice.')
features=[('Bản đồ công trình','Ghim có lương, chọn ghim mở tóm tắt.','jobs, JobController, JobsMap'),('Bán kính Haversine','Lọc 2/5/10/20km và sắp xếp khoảng cách/lương.','JobRepository, WorkerHome'),('Chọn tọa độ đăng/sửa','Map Pin Picker lưu latitude/longitude.','JobController, LocationPicker'),('Chỉ đường','Mở điều hướng ngoài từ tọa độ công trình.','job_links, job_utilities'),('Chấm công GPS/QR','Bán kính 200m, QR hạn 5 phút, check-in/out.','AttendanceController, attendance_records'),('Nhật ký ảnh cuối ca','Upload ảnh, duyệt/bổ sung, điều kiện thanh toán.','work_logs, AttendanceScreen'),('Tổ đội thực','Mời/xác nhận, ứng tuyển và duyệt nguyên nhóm.','CrewController, crews, crew_members, crew_batches'),('VietQR','TLV/CRC, snapshot ngân hàng, Admin bật.','DepositController, receiving_bank_settings'),('Thương lượng lương','Proposed/agreed rate, lựa chọn giá gốc.','ApplicationController, CommitmentService'),('Lịch chống trùng','Ngày bận và kiểm tra lịch khi duyệt.','CalendarController, worker_calendar_blocks'),('Cam kết điện tử','Phiên bản đồng thuận, snapshot và SHA256.','CommitmentController, job_applications'),('SOS/sự cố','Ưu tiên, riêng tư, version và audit.','IncidentController, incidents'),('Portfolio tay nghề','Ảnh upload, caption, xem hồ sơ có quyền.','PortfolioController, portfolio_photos'),('Thời tiết','Open-Meteo, cache, dữ liệu cũ có nhãn.','WeatherController, WeatherCard'),('Lưu công trình','Danh sách yêu thích riêng của thợ.','FavoriteController, saved_jobs'),('Lưu thợ quen','Danh sách riêng của chủ thầu.','FavoriteController, saved_workers'),('Chat ảnh và GPS','Multipart/LOCATION, preview, ACL ảnh.','MessageController, message_attachments'),('Chia sẻ công trình','QR/link Web và mở sau đăng nhập.','SharedJobScreen, job_links')]
table(['STT','Tính năng','Hành vi đã thực thi','Điểm đối chiếu'],[(i,*v) for i,v in enumerate(features,1)])
add('## 4.4. Kết quả kiểm thử và build')
table(['Lớp kiểm chứng','Kết quả chốt','Phạm vi và giới hạn'],[
('Backend Maven verify','125 test pass, 0 lỗi, 0 bỏ qua','H2/MockMvc, PostgreSQL migration riêng, cạnh tranh duyệt đơn, ACL, ví, ảnh và giờ Việt Nam. JVM test mặc định UTC.'),
('Flutter','110 test pass, analyze sạch','Mốc 108 được tăng bằng test khung Tổ đội 320/1440 và test QR demo không mời chuyển tiền thật.'),
('JavaScript Node','12 test pass','Schema/build config, bộ lọc Admin, KYC/lightbox và sự cố.'),
('Python demo','6 test pass','Chặn host/database/sự hiện diện dữ liệu thật, yêu cầu migration, chạy lặp không ghi đè.'),
('JAR / Web release','Build thành công','Maven Spring Boot repackage và Flutter build web --release.'),
('APK / CI','Workflow tự build khi push main','Chỉ tuyên bố run thành công sau khi đối chiếu trạng thái Actions; không có Android SDK local.'),
('Chrome demo thật','390/1440px, hai vai trò, Admin','Dùng API localhost và dữ liệu tổng hợp, đã kiểm tra ví/Top 3/chat/công trình và bốn template Admin.'),
('Đối soát demo','Số dư/ledger/sao khớp','QR CRC, idempotency, earnings theo ngày, inbox dùng API thật.')])
add('Lỗi lịch thu nhập khác nhau giữa Windows và CI UTC đã được tái hiện, thu nhỏ đến truy vấn ngày và sửa bằng TO_CHAR theo múi giờ Việt Nam trước khi parse LocalDate. Backend kiểm thử dưới UTC và đối chiếu thêm PostgreSQL thực tế, tránh việc H2 CAST DATE vô tình phụ thuộc timezone JVM. Không suy ra hiệu năng hoặc tỷ lệ bao phủ từ việc test pass.')
add('Lệnh kiểm chứng có thể chạy lại:\n\n```powershell\n$env:THOXAY_PG_TEST_URL="jdbc:postgresql://127.0.0.1:55433/thoxay_upgrade_qa"\n.\\mvnw.cmd -B "-Dthoxay.build.directory=.local/advanced-target" verify\ncd mobile_app\nflutter analyze\nflutter test\nflutter build web --release --no-wasm-dry-run\ncd ..\nnode --test scripts/deployment.test.mjs scripts/tests/*.test.cjs\n```')
add('## 4.5. Dữ liệu và quy trình bảo vệ\n\nDemo chạy riêng trên thoxay_defense_demo, Backend loopback:18083 và Web loopback:3008, không dùng dữ liệu thật trên Render. Seed tạo 8 tài khoản có tiền tố DEMO, 8 việc OPEN, 39 việc COMPLETED với payment và sao thực sự được lưu trong database demo, 1 việc đang làm cùng chat/ảnh ca/nhóm/SOS. Số dư được đối soát từ ledger; ngày công quá khứ rải theo ngày để biểu đồ có ý nghĩa. Mật khẩu ngẫu nhiên chỉ lưu trong .local/demo/access.md, không được đưa vào báo cáo hoặc slide. Xem DEMO.md và KICH_BAN_DEMO_VA_HOI_DAP.md để chạy lại.')
add('# Chương 5. Kết luận và hướng phát triển\n\n## 5.1. Kết quả đạt được\n\nĐồ án đã thực hiện một quy trình kết nối lao động có phân quyền, dữ liệu địa lý, lịch đồng thuận, bằng chứng ca làm và sổ tài chính có đối soát. Giao diện dùng role palette nhất quán, khung responsive, skeleton, empty states, tương phản Outdoor và hỗ trợ giảm chuyển động. Những ràng buộc quan trọng được thực thi trên server và database, thay vì chỉ ẩn nút ở giao diện. Migration, test, Docker và CI giúp tái lập, kiểm chứng và triển khai cùng mã nguồn cho Web/APK/Admin.')
add('## 5.2. Hạn chế\n\nĐây là sản phẩm đồ án, chưa được nghiệm thu khai thác thương mại hoặc kiểm thử tải quy mô lớn. KYC là kiểm tra ảnh và duyệt thủ công, không chứng minh danh tính bằng cơ sở dữ liệu dân cư. Ví không tự chuyển tiền ngân hàng, chưa là dịch vụ trung gian thanh toán. VietQR demo không có ngân hàng nhận thật. FCM cần tài khoản Firebase riêng. Cam kết là chứng cứ đồng thuận trong ứng dụng, chưa có chữ ký số của nhà cung cấp chứng thực. Check-in GPS có thể chịu sai số/giả vị trí, QR có thể bị chia sẻ; chưa coi đây là chống gian lận tuyệt đối. Ca qua đêm, thiết bị camera thực, QR ngân hàng thực, đánh giá pháp lý và kiểm thử khả năng tiếp cận với người dùng thực cần giai đoạn nghiệm thu tiếp theo.')
add('## 5.3. Hướng phát triển\n\nBước tiếp theo ưu tiên quan trắc lỗi/hiệu năng và backup phục hồi database, kiểm thử thiết bị Android đa cấu hình, hoàn thiện xử lý ca qua đêm và quy trình điều chỉnh công có audit. Khi có hợp đồng dịch vụ phù hợp, có thể tích hợp eKYC, thông báo FCM production và đối soát ngân hàng tự động bằng webhook có chữ ký/idempotency. Khi lưu lượng tăng, cần đánh giá PostGIS/chỉ mục địa lý, object storage ảnh riêng tư có URL ngắn hạn và phát sự kiện nhiều instance qua broker. Mọi mở rộng phải giữ phân quyền, bảo vệ dữ liệu cá nhân và các bất biến ledger.')
add('## 5.4. Đóng góp kỹ thuật của đồ án\n\nĐiểm thực hiện có thể bảo vệ bằng mã gồm khóa giao dịch theo thứ tự để chống nhận vượt/trùng lịch; chốt cam kết theo version và hash; xử lý ảnh riêng tư và bỏ metadata; sổ ví có ba ngăn cùng khóa idempotency; snapshot dữ liệu quan trọng trước thay đổi/xóa; và kiểm thử calendar/timezone dưới cả môi trường local và CI. Chưa thực hiện nghiên cứu so sánh định lượng, do đó không gán tỷ lệ cải thiện hiệu quả tuyển dụng hoặc năng suất lao động.')
add('# Tài liệu và mã nguồn đối chiếu\n\n- pom.xml, .flutter-version, mobile_app/pubspec.yaml và pubspec.lock: công nghệ/phiên bản.\n- schema.sql, src/main/java, src/main/resources/db/migration: mô hình và nghiệp vụ.\n- docs/PROJECT_INVENTORY.json: 30 bảng, toàn bộ cột/ràng buộc và ánh xạ controller.\n- docs/ADVANCED_UPGRADE.md, DATABASE_MIGRATIONS.md, UI_UX_DESIGN_SYSTEM.md: đặc tả đã thực thi.\n- docs/DEMO.md, FIREBASE.md, WALLET.md, KYC_CAMERA.md: cấu hình và giới hạn.\n- .github/workflows, Dockerfile, render.yaml, vercel.json, scripts/build-vercel.mjs: CI và triển khai.\n- src/test/java, mobile_app/test, scripts/tests: ca kiểm thử.\n- docs/diagrams: ảnh sơ đồ render từ mọi khối Mermaid trong báo cáo.\n- docs/KICH_BAN_DEMO_VA_HOI_DAP.md: trình diễn và câu hỏi bảo vệ.\n\nCác tệp .local chứa log, ảnh QA và thông tin truy cập demo không được commit. Không trích dữ liệu cá nhân, khóa hoặc mật khẩu thật vào tài liệu bảo vệ.')
target.write_text('\n'.join(out).rstrip()+'\n',encoding='utf-8')
print('Report generated:',catalog['counts'])
