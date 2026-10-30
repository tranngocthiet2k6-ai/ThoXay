"""Editable 15-slide OOXML deck with real DEMO screenshots and speaker notes.

Uses standard Office parts; PowerPoint renders the deliverable for visual QA.
No python-pptx, rasterized text, private account data or remote authoring service.
"""
import json,zipfile,hashlib,re
from pathlib import Path
from xml.sax.saxutils import escape
from datetime import datetime,timezone
from PIL import Image

ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'.local/final-delivery/slides-draft.pptx'
P='http://schemas.openxmlformats.org/presentationml/2006/main'
A='http://schemas.openxmlformats.org/drawingml/2006/main'
R='http://schemas.openxmlformats.org/officeDocument/2006/relationships'
PKG='http://schemas.openxmlformats.org/package/2006/relationships'
NAVY='0F172A';INK='172033';MUTED='64748B';ORANGE='EA580C';GREEN='059669';WHITE='FFFFFF'
FILES={};MEDIA={};GEOMETRY=[]
def xml(s):return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+s
def rels(items):return '<Relationships xmlns="'+PKG+'">'+''.join(f'<Relationship Id="{i}" Type="{R}/{t}" Target="{escape(p)}"/>' for i,t,p in items)+'</Relationships>'
def group():return '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'
def paragraphs(text,size,color,bold=False):
    result=[]
    for line in text.split('\n'):
        result.append(f'<a:p><a:pPr><a:lnSpc><a:spcPct val="112000"/></a:lnSpc><a:spcAft><a:spcPts val="700"/></a:spcAft></a:pPr><a:r><a:rPr lang="vi-VN" sz="{round(size*75)}" b="{1 if bold else 0}"><a:solidFill><a:srgbClr val="{color}"/></a:solidFill><a:latin typeface="Arial"/><a:ea typeface="Arial"/><a:cs typeface="Arial"/></a:rPr><a:t>{escape(line)}</a:t></a:r><a:endParaRPr lang="vi-VN" sz="{round(size*75)}"/></a:p>')
    return ''.join(result)
class Slide:
    def __init__(self,index,title,notes,dark=False):
        self.index=index;self.title=title;self.notes=notes;self.dark=dark;self.shapes=[];self.relationships=[];self.sid=1
    def text(self,value,x,y,w,h,size=25,bold=False,color=None):
        self.sid+=1;color=color or (WHITE if self.dark else INK)
        ident=f'text-{self.index}-{self.sid}';GEOMETRY.append(dict(slide=self.index,name=ident,x=x,y=y,w=w,h=h,text=value))
        self.shapes.append(f'<p:sp><p:nvSpPr><p:cNvPr id="{self.sid}" name="{ident}"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="{round(x*9525)}" y="{round(y*9525)}"/><a:ext cx="{round(w*9525)}" cy="{round(h*9525)}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/><a:ln><a:noFill/></a:ln></p:spPr><p:txBody><a:bodyPr wrap="square" lIns="0" rIns="0" tIns="0" bIns="0" anchor="t"><a:noAutofit/></a:bodyPr><a:lstStyle/>{paragraphs(value,size,color,bold)}</p:txBody></p:sp>')
    def image(self,file,x,y,w,h,crop=None):
        file=ROOT/file;data=file.read_bytes()
        with Image.open(file) as im:iw,ih=im.size
        if crop:cx,cy,cw,ch=crop
        else:cx,cy,cw,ch=0,0,iw,ih
        scale=min(w/cw,h/ch);fw,fh=cw*scale,ch*scale;x+=(w-fw)/2;y+=(h-fh)/2
        name=file.name;digest=hashlib.sha256(data).hexdigest()[:12];name=digest+'-'+name;MEDIA[name]=data
        self.sid+=1;rid='rIdImage'+str(self.sid);self.relationships.append((rid,'image','../media/'+name));ident='image-'+str(self.sid)
        GEOMETRY.append(dict(slide=self.index,name=ident,x=x,y=y,w=fw,h=fh))
        rect=f'<a:srcRect l="{round(cx/iw*100000)}" t="{round(cy/ih*100000)}" r="{round((iw-cx-cw)/iw*100000)}" b="{round((ih-cy-ch)/ih*100000)}"/>' if crop else ''
        self.shapes.append(f'<p:pic><p:nvPicPr><p:cNvPr id="{self.sid}" name="{ident}" descr="Ảnh giao diện dữ liệu DEMO hoặc sơ đồ {escape(file.stem)}"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr><p:blipFill><a:blip r:embed="{rid}"/>{rect}<a:stretch><a:fillRect/></a:stretch></p:blipFill><p:spPr><a:xfrm><a:off x="{round(x*9525)}" y="{round(y*9525)}"/><a:ext cx="{round(fw*9525)}" cy="{round(fh*9525)}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr></p:pic>')
    def finish(self):
        if self.index!=1:self.text(self.title,64,48,1152,108,42,True)
        self.text('ThoXay',64,677,1000,24,14,color='CBD5E1' if self.dark else MUTED)
        self.text(f'{self.index:02d}',1170,677,46,24,14,color='CBD5E1' if self.dark else MUTED)
        bg=NAVY if self.dark else WHITE
        FILES[f'ppt/slides/slide{self.index}.xml']=xml(f'<p:sld xmlns:p="{P}" xmlns:a="{A}" xmlns:r="{R}"><p:cSld name="ThoXay {self.index:02d}"><p:bg><p:bgPr><a:solidFill><a:srgbClr val="{bg}"/></a:solidFill><a:effectLst/></p:bgPr></p:bg><p:spTree>{group()}{"".join(self.shapes)}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>')
        FILES[f'ppt/slides/_rels/slide{self.index}.xml.rels']=xml(rels([('rIdLayout','slideLayout','../slideLayouts/slideLayout1.xml'),('rIdNotes','notesSlide',f'../notesSlides/notesSlide{self.index}.xml')]+self.relationships))
        note_shape=f'<p:sp><p:nvSpPr><p:cNvPr id="2" name="Speaker Notes"/><p:cNvSpPr/><p:nvPr><p:ph type="body" idx="1"/></p:nvPr></p:nvSpPr><p:spPr/><p:txBody><a:bodyPr/><a:lstStyle/>{paragraphs(self.notes,18,INK)}</p:txBody></p:sp>'
        FILES[f'ppt/notesSlides/notesSlide{self.index}.xml']=xml(f'<p:notes xmlns:p="{P}" xmlns:a="{A}" xmlns:r="{R}"><p:cSld><p:spTree>{group()}{note_shape}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:notes>')
        FILES[f'ppt/notesSlides/_rels/notesSlide{self.index}.xml.rels']=xml(rels([('rIdSlide','slide',f'../slides/slide{self.index}.xml'),('rIdMaster','notesMaster','../notesMasters/notesMaster1.xml')]))

notes=[
'''Em xin trình bày đồ án ThoXay, ứng dụng kết nối lao động phổ thông và Chủ thầu. Phần trình bày tập trung vào quy trình có thể kiểm chứng từ tìm công trình, chốt hợp tác đến ghi nhận ca làm và thanh toán nội bộ. Sản phẩm có Flutter Web/Android và trang Admin. Dữ liệu trong ảnh đều thuộc môi trường DEMO riêng, không đại diện người dùng hay giao dịch thật. Sau phần kiến trúc và kết quả, em sẽ thao tác trực tiếp trên hai vai trò và Admin.
Nguồn: docs/BAO_CAO_DO_AN.md, docs/DEMO.md. Chốt số liệu 30/10/2026.''',
'''Bài toán đặt ra là thông tin tuyển dụng thường gắn chặt với địa điểm, thời gian và mức lương. Thợ cần so sánh cơ hội quanh một khu vực, còn Chủ thầu cần tập hợp ứng viên và biết ngày công đã được nghiệm thu. Đồ án cung cấp cùng một luồng dữ liệu để theo dõi các trạng thái đó. Đây là nhu cầu thiết kế của sản phẩm. Em chưa có khảo sát thị trường đủ mẫu để khẳng định tỷ lệ tăng hiệu quả hay năng suất. Ảnh bên phải minh họa giao diện Chủ thầu trên màn hình nhỏ.
Nguồn: Chương 1 báo cáo; mobile_app/lib/screens/contractor_home_screen.dart.''',
'''Hệ thống có ba vai trò rõ ràng. Thợ tìm việc, ứng tuyển và thực hiện ca. Chủ thầu đăng công trình, quyết định giá và nghiệm thu. Admin duyệt KYC, quản lý và đối soát. Đăng ký công khai chỉ có Thợ và Chủ thầu. Mỗi service vẫn kiểm tra quyền sở hữu dữ liệu hoặc trạng thái ACCEPTED, nên việc biết ID hay có JWT không cho phép đọc toàn bộ hệ thống. Sơ đồ này rút gọn để trình chiếu; sơ đồ chức năng chi tiết nằm trong báo cáo.
Nguồn: SecurityConfig, CurrentUser và docs/diagrams/slide-diagrams.md.''',
'''Flutter Web được phục vụ từ Vercel. APK và Web gọi cùng REST JWT/WebSocket của Spring Boot trên Render. Thymeleaf Admin nằm cùng Backend và dùng phiên đăng nhập. PostgreSQL lưu dữ liệu nghiệp vụ và ảnh riêng tư. Backend là modular monolith, chia package theo trách nhiệm nhưng dùng cùng transaction khi duyệt thợ hoặc ghi sổ. GitHub Actions kiểm tra và tạo APK, trong khi Render/Vercel nhận thay đổi từ main. Cấu hình bí mật nằm ngoài Git.
Nguồn: Dockerfile, render.yaml, vercel.json, .github/workflows và SecurityConfig.''',
'''Phiên bản được đọc từ mã cấu hình và bản build, không suy đoán từ tên sản phẩm. Java target 17, Spring Boot 3.5.16 và PostgreSQL cloud major 17. Flutter ghim 3.47.8. Spring Security cùng JJWT bảo vệ API, còn Admin dùng Thymeleaf/Bootstrap. flutter_map hiển thị OSM, image_picker hỗ trợ ảnh, mobile_scanner đọc QR ca làm và qr_flutter hiển thị payload QR. Các dependency resolve đầy đủ có trong báo cáo và lockfile. Dịch vụ cloud không có một số version ứng dụng được ghim như thư viện.
Nguồn: pom.xml, .flutter-version, mobile_app/pubspec.lock.''',
'''Kiểm kê thực tế có 30 bảng nghiệp vụ và 256 cột, không cộng flyway_schema_history vào bảng nghiệp vụ. Hình chỉ lấy lõi users, jobs và job_applications để thấy quan hệ một-nhiều. Mỗi cặp job/worker có một đơn duy nhất. Những phân hệ mới bổ sung lịch, tổ đội, chấm công, ledger, KYC, chat và sự cố. Báo cáo có đầy đủ từ điển dữ liệu và ERD theo phân hệ, cùng 111 ánh xạ HTTP gồm 90 dưới /api/. Không nhầm route Admin hoặc WebSocket với số REST endpoint.
Nguồn: docs/PROJECT_INVENTORY.json, schema.sql và docs/diagrams/slide-diagrams.md.''',
'''Thợ chọn tâm tìm việc bằng GPS hoặc chọn vị trí tìm kiếm thủ công. Server dùng Haversine để lọc bán kính và có thêm điều kiện loại việc, trạng thái OPEN và sắp xếp lương. Bản đồ hiển thị ghim có lương, chọn ghim xem tóm tắt, lưu và chia sẻ công trình, mở chỉ đường. Ảnh là các công trình DEMO ở khu vực TP.HCM; attribution OSM vẫn hiện. Chọn tâm tìm kiếm không được xem như chứng cứ GPS để chấm công. Khi dữ liệu lớn cần đo truy vấn và cân nhắc PostGIS.
Nguồn: JobRepository, JobsMap, job_utilities.dart. Bản đồ © OpenStreetMap contributors.''',
'''Lương đề xuất và lương đã chốt được lưu riêng. Thợ phải đồng ý đúng termsVersion, Chủ thầu quyết định giá, server giữ snapshot cam kết cùng hash. Khi duyệt, transaction khóa công trình rồi các worker theo thứ tự để kiểm tra công suất và lịch. Tổ đội dùng các tài khoản đã xác nhận, mỗi người có đơn và cam kết riêng; duyệt nguyên nhóm là atomic. Nếu một người không đủ điều kiện, cả lượt duyệt không hoàn tất. Hash không thay thế chữ ký số.
Nguồn: CommitmentService, WorkerCalendarService, CrewService và ApplicationService.''',
'''Chấm công ghi nhận ngày Việt Nam bằng GPS trong 200m, accuracy tối đa 100m hoặc QR ca làm có hạn 5 phút. Server ghi giờ, giới hạn một ca cho mỗi đơn/ngày. Thợ gửi ảnh sau checkout để Chủ thầu duyệt hoặc yêu cầu bổ sung. Công trình mới yêu cầu đủ ca và ảnh APPROVED trước khi trả ngày công tương ứng. QR/GPS chưa chống gian lận tuyệt đối, ca qua đêm chưa hỗ trợ. Ảnh chụp cho thấy ca mẫu đã có dữ liệu, không phải công trình thực tế của người dùng.
Nguồn: AttendanceService, WorkLog, JobPaymentService và docs/DEMO.md.''',
'''Ví chia số dư khả dụng, ký quỹ và tiền giữ chỗ rút. Rút tiền giữ main sang held trước để tránh tiêu trùng. Dưới 200.000đ ký quỹ chỉ cảnh báo, chưa chặn nhận việc. Biểu đồ lấy từ ledger theo ngày Việt Nam và không tính TOP_UP như thu nhập. VietQR điền sẵn người nhận, số tiền và nội dung, nhưng yêu cầu vẫn chờ Admin đối soát. BIN 000000 trong demo không dùng thanh toán, tuyệt đối không chuyển tiền theo QR mẫu. Dự án chưa có ngân hàng tự chuyển tiền.
Nguồn: WalletService, JobPaymentService, DepositService, VietQrPayload và docs/WALLET.md.''',
'''Sao là trung bình điểm công trình hoàn thành, còn uy tín là điểm từ 0 đến 100 có lịch sử sự kiện. GOLD cần ít nhất 5 công trình, sao 4.0 và uy tín 80. DIAMOND cần 20 công trình, sao 4.7, uy tín 95 và KYC. Hủy đơn ACCEPTED trừ 15 điểm một lần rồi tính lại bậc, không tự trừ tiền. Top 3 ở ảnh được truy vấn từ các đơn, sao và công trình DEMO đã hoàn thành. Không trình bày rating mẫu như chứng nhận nghề nghiệp thật.
Nguồn: WorkerTier, WorkerRankingService, WorkerRatingService và ApplicationCancellationService.''',
'''REST lưu tin, WebSocket phát sau commit. ClientMessageId chống tạo thêm tin khi retry cùng payload, history khôi phục khi mất kết nối. Chữ, ảnh và GPS chỉ mở giữa cặp ACCEPTED; ảnh có ACL riêng. Hộp thư dùng read cursor tăng đơn điệu cho số tin chưa đọc. Sự cố/SOS gửi riêng tới Admin và có audit, không tự gọi cứu hộ. Lịch sử thông báo hoạt động trong DB; FCM cần Firebase/service account và token hợp lệ, hiện chưa có cấu hình production để tuyên bố gửi push thật.
Nguồn: MessageService, ChatAccessService, ChatInboxService, IncidentService và notification package.''',
'''KYC tự động kiểm tra tệp, giới hạn kích thước, chuẩn hóa ảnh và bỏ metadata. Admin mới là người duyệt danh tính. Modal tải hai mặt khi mở và có lightbox; cần hai ảnh đầy đủ, khớp snapshot đã xem mới duyệt. Ảnh ở đây có dấu DEMO, không phải CCCD người thật. Giao diện Admin còn có KPI, lọc bảng, đối soát ví và hàng chờ sự cố. Mọi thao tác quản trị được kiểm tra ở Backend, không chỉ phụ thuộc nút ẩn hoặc JavaScript.
Nguồn: KycService, AdminService, admin-dashboard.html, admin-kyc.js và docs/KYC_CAMERA.md.''',
'''Kết quả local đã kiểm chứng: 125 test Backend, 110 Flutter và 12 JavaScript pass, thêm 6 test bảo vệ seed Python. Hai test Flutter mới kiểm tra khung Tổ đội và nhãn QR demo, tăng từ mốc 108. Bộ Backend chạy JVM UTC và có PostgreSQL migration QA riêng. Maven JAR, Flutter Web và workflow APK được kiểm tra. 100% số test này pass không đồng nghĩa coverage 100% hoặc mọi thiết bị đều không lỗi. Chưa có kiểm thử tải lớn hoặc quét QR bằng ứng dụng ngân hàng thật.
Nguồn: src/test/java, mobile_app/test, scripts/tests và GitHub Actions của repository.''',
'''Đồ án đã khép kín luồng kết nối, ca làm, đánh giá và sổ ví trong phạm vi đã kiểm chứng. Những đóng góp có thể mở mã để chứng minh gồm khóa transaction theo thứ tự, snapshot cam kết/ngân hàng, ảnh riêng tư, idempotency và kiểm thử timezone. Bước tiếp theo ưu tiên thiết bị Android thật, ca qua đêm, quan trắc và backup. eKYC, FCM production và đối soát ngân hàng chỉ triển khai khi có cấu hình/dịch vụ phù hợp. Em xin chuyển sang phần demo và tiếp nhận câu hỏi của Hội đồng.
Nguồn: Chương 5 báo cáo và docs/KICH_BAN_DEMO_VA_HOI_DAP.md.'''
]
titles=['ThoXay','Công việc gắn với vị trí và ngày công','Ba vai trò trong cùng quy trình','Kiến trúc triển khai Web và APK','Công nghệ được cấu hình trong dự án','Mô hình dữ liệu giữ các ràng buộc','Tìm công trình trên bản đồ','Chốt hợp tác theo lịch và cam kết','Ca làm có bằng chứng nghiệm thu','Ví và thu nhập có sổ đối soát','Sao và uy tín quyết định bậc thợ','Trao đổi realtime và báo cáo sự cố','Admin duyệt KYC bằng hai mặt ảnh','Kết quả kiểm thử và phát hành','Kết quả và hướng phát triển']
slides=[Slide(i+1,t,notes[i],dark=i in (0,3,9,13,14)) for i,t in enumerate(titles)]
s=slides[0];s.text('ĐỒ ÁN TỐT NGHIỆP',72,64,1100,40,22,color='CBD5E1');s.text('ThoXay',72,166,1100,138,112,True);s.text('Kết nối lao động phổ thông\nvà Chủ thầu',78,332,1090,120,40,True);s.text('Flutter Mobile/Web và Spring Boot\n30/10/2026',80,520,1100,84,25,color='CBD5E1')
s=slides[1];s.text('Thợ cần so sánh cơ hội quanh mình',64,200,750,50,30,True,color=ORANGE);s.text('Địa điểm, mức lương và lịch phải rõ trước khi ứng tuyển.',64,262,710,100,28);s.text('Chủ thầu cần theo dõi hợp tác',64,386,750,50,30,True,color=GREEN);s.text('Ứng viên, ngày công, nghiệm thu và chi trả cùng một lịch sử.',64,448,710,130,28);s.image('docs/presentation-assets/contractor-mobile.png',850,180,340,460,crop=(0,70,390,850))
s=slides[2];s.image('docs/diagrams/slide-use-case.png',64,180,600,440);s.text('Vai trò gắn với quyền sở hữu dữ liệu',730,204,470,90,32,True);s.text('Chỉ Thợ và Chủ thầu đăng ký công khai.\nAdmin dùng phiên và CSRF.\nService kiểm tra quyền ở từng thao tác.',730,334,470,220,27)
s=slides[3];s.image('docs/diagrams/slide-architecture.png',110,178,1060,410);s.text('REST JWT và WebSocket dùng chung Backend. Admin đi cùng Spring Boot.',64,607,1152,48,23,color='CBD5E1')
s=slides[4];s.text('Backend và dữ liệu',64,190,520,54,32,True,color=GREEN);s.text('Java 17\nSpring Boot 3.5.16\nSpring Security và JJWT 0.12.6\nPostgreSQL 17 và Flyway',64,270,545,250,29);s.text('Giao diện và phát hành',690,190,530,54,32,True,color=ORANGE);s.text('Flutter 3.47.8\nThymeleaf và Bootstrap 5.3.8\nOpenStreetMap, camera và QR\nDocker và GitHub Actions',690,270,530,250,29);s.text('Version thư viện được đối chiếu từ cấu hình, lockfile và JAR.',64,585,1152,50,23,color=MUTED)
s=slides[5];s.text('30 bảng nghiệp vụ     256 cột     90 REST endpoint dưới /api/',64,174,1152,54,29,True,color=GREEN);s.image('docs/diagrams/slide-erd.png',64,260,1152,330);s.text('Lõi tuyển dụng trong sơ đồ. Từ điển đủ 30 bảng và 111 route HTTP nằm trong báo cáo.',64,614,1152,45,21,color=MUTED)
s=slides[6];s.image('docs/presentation-assets/map.png',64,190,1152,405,crop=(176,270,1088,610));s.text('Bán kính Haversine   ·   Ghim có lương   ·   Lưu và chia sẻ   ·   Chỉ đường',64,615,1152,40,23,color=ORANGE)
s=slides[7];s.text('Lương được chốt theo phiên bản',64,190,540,76,31,True,color=GREEN);s.text('Đề xuất và giá gốc tách biệt.\nSnapshot cam kết có SHA256.\nChặn nhận trùng lịch khi duyệt.',64,285,520,190,28);s.text('Tổ đội gồm các tài khoản đã xác nhận. Mỗi người vẫn có ca và đánh giá riêng.',64,510,520,125,26);s.image('docs/presentation-assets/crew.png',646,188,570,452,crop=(316,90,808,680))
s=slides[8];s.text('200 m',64,205,370,100,76,True,color=ORANGE);s.text('Bán kính chấm công GPS',64,315,420,58,27);s.text('5 phút',64,408,370,90,64,True,color=ORANGE);s.text('Thời hạn mã QR ca làm',64,502,430,56,27);s.image('docs/presentation-assets/attendance.png',520,180,696,458,crop=(316,90,808,780))
s=slides[9];s.text('Main, ký quỹ và tiền giữ chỗ rút tách biệt. Ngưỡng cảnh báo ký quỹ 200.000đ.',64,161,1152,62,25,color='CBD5E1');s.image('docs/presentation-assets/wallet-mobile.png',64,242,270,380,crop=(0,205,390,620));s.text('Tiền công, tip và thưởng đã thanh toán',370,238,846,44,24,color='CBD5E1');s.image('docs/presentation-assets/earnings.png',370,290,846,327,crop=(316,376,808,312));s.text('VietQR mẫu không nhận tiền thật. Nạp/rút vẫn chờ Admin đối soát.',64,637,1152,32,21,color='FDE68A')
s=slides[10];s.text('1–5 sao',64,198,360,82,58,True,color=ORANGE);s.text('Điểm từ công trình hoàn thành',64,292,350,95,26);s.text('−15 điểm',64,414,350,80,48,True,color=ORANGE);s.text('Hủy việc đã nhận và tính lại bậc',64,505,350,100,26);s.image('docs/presentation-assets/leaderboard.png',440,190,776,440,crop=(316,350,808,350))
s=slides[11];s.text('Chat chỉ mở sau ACCEPTED',64,194,520,80,31,True,color=GREEN);s.text('Chữ, ảnh và vị trí GPS.\nLưu tin trước, phát sau commit.\nHộp thư có số tin chưa đọc.',64,300,510,180,28);s.text('SOS ưu tiên tới Admin và có lịch sử xử lý. FCM cần cấu hình Firebase riêng.',64,520,520,118,25,color=MUTED);s.image('docs/presentation-assets/chat.png',640,190,576,95,crop=(256,80,928,125));s.image('docs/presentation-assets/chat.png',640,316,576,300,crop=(256,670,928,305))
s=slides[12];s.text('Kiểm tra ảnh tự động, Admin duyệt danh tính. Ảnh dưới đây có dấu DEMO.',64,162,1152,64,25,color=MUTED);s.image('docs/presentation-assets/kyc-admin.png',64,226,1152,436,crop=(150,171,1140,658))
s=slides[13];s.text('125',64,205,340,120,88,True);s.text('Backend',64,337,340,50,28,color='CBD5E1');s.text('110',472,205,340,120,88,True,color='FDBA74');s.text('Flutter',472,337,340,50,28,color='CBD5E1');s.text('12',880,205,330,120,88,True,color='6EE7B7');s.text('JavaScript',880,337,330,50,28,color='CBD5E1');s.text('Toàn bộ test trên pass. Thêm 6 test Python bảo vệ seed.',64,442,1152,70,29);s.text('JAR và Web release đã build. GitHub Actions kiểm tra cloud và tạo APK.',64,546,1152,80,26,color='CBD5E1')
s=slides[14];s.text('Quy trình hợp tác có dữ liệu kiểm chứng',64,195,1152,70,36,True);s.text('Tìm việc, cam kết, ca làm, đánh giá và sổ ví đã kết nối.',64,300,1110,90,30,color='CBD5E1');s.text('Tiếp theo',64,433,1110,48,28,True,color='FDBA74');s.text('Nghiệm thu thiết bị, ca qua đêm, quan trắc và backup.\nFCM, eKYC và ngân hàng thật khi có dịch vụ phù hợp.',64,501,1110,110,28,color='CBD5E1')

for s in slides:s.finish()
master=f'<p:sldMaster xmlns:p="{P}" xmlns:a="{A}" xmlns:r="{R}"><p:cSld name="ThoXay"><p:spTree>{group()}</p:spTree></p:cSld><p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/><p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rIdLayout"/></p:sldLayoutIdLst><p:txStyles><p:titleStyle/><p:bodyStyle/><p:otherStyle/></p:txStyles></p:sldMaster>'
FILES['ppt/slideMasters/slideMaster1.xml']=xml(master)
FILES['ppt/slideMasters/_rels/slideMaster1.xml.rels']=xml(rels([('rIdLayout','slideLayout','../slideLayouts/slideLayout1.xml'),('rIdTheme','theme','../theme/theme1.xml')]))
FILES['ppt/slideLayouts/slideLayout1.xml']=xml(f'<p:sldLayout xmlns:p="{P}" xmlns:a="{A}" xmlns:r="{R}" type="blank" preserve="1"><p:cSld name="Blank"><p:spTree>{group()}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>')
FILES['ppt/slideLayouts/_rels/slideLayout1.xml.rels']=xml(rels([('rIdMaster','slideMaster','../slideMasters/slideMaster1.xml')]))
FILES['ppt/notesMasters/notesMaster1.xml']=xml(f'<p:notesMaster xmlns:p="{P}" xmlns:a="{A}" xmlns:r="{R}"><p:cSld name="Notes"><p:spTree>{group()}</p:spTree></p:cSld><p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/><p:notesStyle/></p:notesMaster>')
FILES['ppt/notesMasters/_rels/notesMaster1.xml.rels']=xml(rels([('rIdTheme','theme','../theme/theme1.xml')]))
colors={'dk1':NAVY,'lt1':WHITE,'dk2':INK,'lt2':'F1F5F9','accent1':ORANGE,'accent2':GREEN,'accent3':'3B82F6','accent4':'64748B','accent5':'FBBF24','accent6':'0F172A','hlink':'2563EB','folHlink':'7C3AED'}
fill='<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
FILES['ppt/theme/theme1.xml']=xml(f'<a:theme xmlns:a="{A}" name="ThoXay"><a:themeElements><a:clrScheme name="ThoXay">'+''.join(f'<a:{k}><a:srgbClr val="{v}"/></a:{k}>' for k,v in colors.items())+'</a:clrScheme><a:fontScheme name="Arial"><a:majorFont><a:latin typeface="Arial"/><a:ea typeface="Arial"/><a:cs typeface="Arial"/></a:majorFont><a:minorFont><a:latin typeface="Arial"/><a:ea typeface="Arial"/><a:cs typeface="Arial"/></a:minorFont></a:fontScheme><a:fmtScheme name="ThoXay"><a:fillStyleLst>'+fill*3+'</a:fillStyleLst><a:lnStyleLst>'+(' <a:ln w="9525">'+fill+'<a:prstDash val="solid"/></a:ln>')*3+'</a:lnStyleLst><a:effectStyleLst>'+'<a:effectStyle><a:effectLst/></a:effectStyle>'*3+'</a:effectStyleLst><a:bgFillStyleLst>'+fill*3+'</a:bgFillStyleLst></a:fmtScheme></a:themeElements></a:theme>')
FILES['ppt/presentation.xml']=xml(f'<p:presentation xmlns:p="{P}" xmlns:a="{A}" xmlns:r="{R}"><p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rIdMaster"/></p:sldMasterIdLst><p:notesMasterIdLst><p:notesMasterId r:id="rIdNotesMaster"/></p:notesMasterIdLst><p:sldIdLst>'+''.join(f'<p:sldId id="{255+i}" r:id="rIdSlide{i}"/>' for i in range(1,16))+'</p:sldIdLst><p:sldSz cx="12192000" cy="6858000" type="screen16x9"/><p:notesSz cx="6858000" cy="9144000"/><p:defaultTextStyle/></p:presentation>')
FILES['ppt/_rels/presentation.xml.rels']=xml(rels([('rIdMaster','slideMaster','slideMasters/slideMaster1.xml'),('rIdNotesMaster','notesMaster','notesMasters/notesMaster1.xml')]+[(f'rIdSlide{i}','slide',f'slides/slide{i}.xml') for i in range(1,16)]))
FILES['_rels/.rels']=xml(rels([('rIdPresentation','officeDocument','ppt/presentation.xml')]))
types='<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="xml" ContentType="application/xml"/><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="png" ContentType="image/png"/>'
for name in FILES:
    if name.endswith('.rels'):continue
    if name=='ppt/presentation.xml':kind='presentation.main'
    elif '/slideMasters/' in name:kind='slideMaster'
    elif '/slideLayouts/' in name:kind='slideLayout'
    elif '/notesMasters/' in name:kind='notesMaster'
    elif '/notesSlides/' in name:kind='notesSlide'
    elif '/slides/' in name:kind='slide'
    elif '/theme/' in name:
        types+=f'<Override PartName="/{name}" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>';continue
    else:continue
    types+=f'<Override PartName="/{name}" ContentType="application/vnd.openxmlformats-officedocument.presentationml.{kind}+xml"/>'
FILES['[Content_Types].xml']=xml(types+'</Types>')
# Native PowerPoint materializes Notes pages for exact Office interoperability.
# A hand-built notes master passed structural checks but Office rejected it.
OUT.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(OUT,'w',zipfile.ZIP_DEFLATED) as z:
    for name,value in FILES.items():
        if '/notesSlides/' in name or '/notesMasters/' in name:continue
        value=re.sub(r'<p:notesMasterIdLst>.*?</p:notesMasterIdLst>','',value)
        value=re.sub(r'<Relationship\b[^>]*Type="[^"]*/notes(?:Slide|Master)"[^>]*/>','',value)
        value=re.sub(r'<Override\b[^>]*PartName="/ppt/notes(?:Slides|Masters)/[^>]*/>','',value)
        z.writestr(name,value)
    for name,data in MEDIA.items():z.writestr('ppt/media/'+name,data)
private=ROOT/'.local/final-delivery';private.mkdir(parents=True,exist_ok=True)
(private/'slide-geometry.json').write_text(json.dumps(GEOMETRY,ensure_ascii=False,indent=2),encoding='utf-8')
(private/'speaker-notes.json').write_text(json.dumps(notes,ensure_ascii=False,indent=2),encoding='utf-8')
print('PPTX draft exported: 15 editable slides,',len(MEDIA),'embedded images; notes ready for native finalization')
