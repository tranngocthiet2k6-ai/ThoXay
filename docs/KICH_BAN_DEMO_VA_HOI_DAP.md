# Kịch bản trình diễn và hỏi đáp bảo vệ ThoXay

Tài liệu dành cho người trình bày đồ án. Số liệu chốt ngày 30/10/2026:
30 bảng nghiệp vụ, 256 cột, 28 Controller, 90 endpoint `/api/` và 21 route khác.
Bộ test đã chạy: 125 Backend, 110 Flutter, 12 JS và 6 test bảo vệ seed Python.
Mốc 108 Flutter trước đợt hoàn thiện tăng thêm hai regression test.

## Môi trường đã chuẩn bị

Web demo: http://127.0.0.1:3008. Admin demo:
http://127.0.0.1:18083/admin/login. Tất cả dữ liệu ở database riêng
`thoxay_defense_demo`, mọi tên có nhãn `[DEMO]`. Mật khẩu ngẫu nhiên và danh sách
tài khoản nằm trong `.local/demo/access.md`; không chiếu hoặc đưa mật khẩu vào slide.
Trên máy thực hiện, demo đã được tự build, seed và kiểm chứng qua API/Chrome.

Khi cần khởi động lại, chạy `./scripts/start-demo.ps1 -SkipBuild -OpenBrowser`.
Nếu demo còn chạy, giữ nguyên các tiến trình đó; chỉ dùng `./scripts/stop-demo.ps1`
để dừng đúng instance của demo trước khi khởi động lại. Không dùng reset database,
`git clean` hoặc dừng toàn bộ Java/PostgreSQL chỉ để làm lại buổi trình diễn.

Tài khoản Thợ chính để trình bày là **000106000003**, Chủ thầu là
**000106000001**, Admin là **000106000000**. Chúng không đại diện số điện thoại
người dùng thật. Mở ba phiên trình duyệt riêng để không ghi đè phiên của nhau.
Nếu minh họa trên điện thoại, APK release mặc định dùng Backend Render production,
không tự nối vào database localhost này. Không dùng tài khoản demo local để đăng
nhập production. Web responsive là phương án trình diễn mobile ngay trên máy.

## Trình tự trình bày 15 slide

| Slide | Nội dung cần nói | Thời lượng gợi ý |
| --- | --- | --- |
| 1–3 | Đề tài, bài toán và vai trò | 1 phút 20 giây |
| 4–6 | Kiến trúc, công nghệ, mô hình dữ liệu | 2 phút |
| 7–9 | Bản đồ, tuyển dụng, tổ đội, ca làm | 2 phút |
| 10–13 | Ví, uy tín, chat/SOS, KYC và Admin | 2 phút |
| 14–15 | Kiểm thử, triển khai, giới hạn và hướng phát triển | 1 phút 20 giây |

Speaker Notes có lời dẫn cụ thể ở từng slide. Có thể rút gọn phần nói để dành
7–8 phút thao tác demo; thời lượng là gợi ý luyện tập, không phải số liệu thực nghiệm.

## Kịch bản demo chính khoảng 8 phút

### Bước 1 Mở ứng dụng và phân biệt vai trò

Đăng nhập Thợ ở phiên thứ nhất và Chủ thầu ở phiên thứ hai. Chỉ ra màu Cam và
Xanh lục bảo, khung nội dung cân đối trên desktop. Thu cửa sổ xuống khoảng 390px
để thể hiện thanh điều hướng thích ứng. Chuyển Sáng/Tối/Outdoor rồi trở lại Sáng.
Lời dẫn: “Cùng mã Flutter phục vụ Web và Android. Theme thay đổi cách hiển thị,
không cấp thêm quyền nghiệp vụ.” Không nhập mật khẩu khi màn hình đang được chiếu.

### Bước 2 Tìm việc trên bản đồ

Ở trang Thợ, chọn “Chọn vị trí tìm việc” và nhập **10.8015, 106.7140** nếu GPS
thực của thiết bị ở ngoài khu vực TP.HCM hoặc không được cấp quyền. Đây là chọn
tâm tìm kiếm, không phải giả mạo vị trí chấm công. Thử bán kính 5/10/20km, loại
Thợ chính/Phụ hồ và sắp xếp lương. Bật bản đồ, chọn ghim lương để xem tóm tắt.
Mở chi tiết, chỉ ra “Chỉ đường”, “Lưu công trình” và QR/link chia sẻ. Giữ dòng
attribution OpenStreetMap trên màn hình. Mức lương/vị trí của mọi tin ở đây là mẫu.

### Bước 3 Thương lượng và cam kết

Chọn một công trình OPEN chưa có đơn của thợ đang đăng nhập. Ứng tuyển với mức
lương đề xuất và ghi chú ngắn. Mở văn bản cam kết, nêu rõ termsVersion và quy định
phạt hủy trước khi xác nhận. Ở phiên Chủ thầu, mở công trình đúng chủ sở hữu,
duyệt đơn và chọn giá đề xuất hoặc giá gốc. Kiểm tra lại mức đã chốt trong cam kết.
Nếu chọn một công trình khác trùng ngày, hệ thống phải từ chối khi duyệt.
Không sửa trực tiếp database để bỏ qua cảnh báo lịch hoặc điều kiện đồng thuận.

### Bước 4 Tổ đội và lịch làm việc

Trong Hồ sơ Thợ, mở “Tổ đội của tôi” để xem tổ mẫu với ba tài khoản đã xác nhận.
Nêu rằng số thành viên được server lấy từ roster thật. Mở “Lịch làm việc”, chỉ
ngày bận và lịch đã được nhận. Nếu demo nhận tổ, các thành viên cần tự đồng ý
phiên bản cam kết trước khi Chủ thầu duyệt nguyên nhóm. Với thời gian ngắn, chỉ
trình bày tổ có sẵn và quy tắc atomic, không mất thời gian đăng nhập cả ba người.

### Bước 5 Chấm công và nghiệm thu ảnh

Ở lịch sử ứng tuyển, mở công trình **[DEMO] Nhà phố ven sông - ca trình diễn**.
Thợ chính có ca đã check-in/out và ảnh chờ nghiệm thu; mở ảnh để phóng to.
Ở Chủ thầu, mở chấm công công trình, chọn đúng ngày Việt Nam rồi duyệt ảnh hoặc
yêu cầu bổ sung. Thợ thứ hai chưa chấm công có thể dùng QR ca làm do Chủ thầu cấp
để minh họa check-in/out mà không cần đứng ở tọa độ mẫu. QR hết hạn sau 5 phút.
Nếu thiết bị không có camera, chỉ ra chức năng và dùng ca mẫu đã chuẩn bị; không
khẳng định đã quét bằng camera vật lý khi chỉ trình diễn trên trình duyệt.

### Bước 6 Ví và thu nhập

Mở Ví của Thợ để thấy số dư, ký quỹ 100.000đ và cảnh báo dưới 200.000đ. Thử ẩn/hiện
số dư. Mở Thu nhập và đổi Ngày/Tuần/Tháng; giải thích các cột lấy từ ledger đã
thanh toán, không chia đều tổng tiền thành ngày giả. Trong “Nạp tiền bằng VietQR”,
tạo yêu cầu 250.000đ, chỉ ra người nhận **DEMO ONLY** và cảnh báo **KHÔNG CHUYỂN TIỀN**.
BIN 000000 chỉ phục vụ dựng payload; không dùng ứng dụng ngân hàng để chuyển tiền.
Admin xem hàng chờ và chứng minh yêu cầu PENDING chưa làm tăng số dư.

### Bước 7 Uy tín, chat và sự cố

Mở bảng xếp hạng để xem Top 3 và hồ sơ thợ Kim Cương có 20 công trình mẫu đã
hoàn thành. Mở hộp thư, vào cuộc trò chuyện công trình đang làm, gửi một tin ngắn
giữa hai phiên và quan sát cập nhật. Có thể xem trước ảnh/vị trí trước khi gửi.
Trong Hồ sơ, mở sự cố mẫu để xem trạng thái/ghi chú. Ở Admin, mở hàng chờ sự cố,
xem báo cáo an toàn và chuyển sang đang xử lý kèm ghi chú demo. SOS là thông báo
nội bộ ưu tiên, không phải cuộc gọi cứu hộ tự động.

### Bước 8 KYC và kết thúc

Admin mở “Xem CCCD”, xem hai mặt và lightbox. Ảnh phải hiện chữ DEMO, không phải
CCCD người thật. Nêu rõ kiểm tra file diễn ra tự động, còn danh tính cần Admin
duyệt; hồ sơ đã được duyệt sẽ không có thao tác xác thực lại vô nghĩa. Khi upload
hai ảnh mới, trạng thái quay về chưa xác thực. Kết thúc bằng KPI Admin, test và
workflow APK. Không trình bày số tài khoản, KYC, thu nhập hoặc rating mẫu như bằng
chứng người dùng thật hay doanh thu thật.

## Tình huống dự phòng

| Tình huống | Cách xử lý khi bảo vệ |
| --- | --- |
| Render chưa thức dậy | Dùng demo localhost đã khởi động. Production có readiness chờ có giới hạn; không bấm gửi giao dịch nhiều lần |
| GPS ngoài vùng mẫu | Chọn tâm tìm việc thủ công bằng 10.8015, 106.7140; không dùng tọa độ đó để tuyên bố check-in GPS thật |
| OSM/Internet lỗi | Chuyển về danh sách, giữ lọc lương/khoảng cách theo dữ liệu đã trả. Nêu phụ thuộc tile ngoài, không giả bản đồ offline |
| Thời tiết lỗi | Chỉ ra unavailable/stale và thử lại; không báo nhiệt độ 0 như dữ liệu thật |
| Camera hoặc QR không khả dụng | Dùng ca và ảnh tổng hợp có sẵn, giải thích phần cần nghiệm thu trên thiết bị |
| Đơn/QR đã dùng ở buổi trước | Chọn công trình OPEN khác hoặc tạo yêu cầu mới bằng UI. Không xóa lịch sử để che thao tác đã diễn ra |
| Số liệu/phiên bị thay đổi | Dùng “Làm mới”, kiểm tra đúng vai trò và môi trường. Seed lặp không ghi đè tương tác cũ |
| Hội đồng hỏi về thanh toán tự động | Mở trạng thái PENDING/đối soát Admin, phân biệt tạo mã QR và xác nhận giao dịch ngân hàng |

## Hai mươi câu hỏi và gợi ý trả lời

### Câu 1 Vì sao chọn đề tài và sản phẩm giải quyết vấn đề nào

Đề tài tập trung vào việc tuyển lao động gắn với vị trí, lịch và mức lương ngày.
Thợ cần xem cơ hội quanh một khu vực, Chủ thầu cần quản lý ứng viên và bằng chứng
ngày công. Sản phẩm lưu tập trung trạng thái hợp tác từ ứng tuyển đến nghiệm thu,
đánh giá và chi trả nội bộ. Điểm có thể chứng minh là các luồng chạy được và dữ
liệu có ràng buộc, không phải một tỷ lệ tăng năng suất chưa được khảo sát.
Nếu hỏi hiệu quả thị trường, cần trả lời rằng đồ án chưa có nghiên cứu thực địa
đủ mẫu để kết luận định lượng. Nguồn: Chương 1 báo cáo và Job/Application/Attendance services.

### Câu 2 Vì sao dùng Flutter cùng Spring Boot và kiến trúc modular monolith

Flutter giúp dùng chung model, API service và widget cho Android/Web, giữ hành vi
nhất quán theo vai trò. Spring Boot phù hợp với REST, Spring Security, JPA và
transaction trong cùng ứng dụng. Modular monolith phân chia scheduling, crew,
wallet, media, chat và incident theo trách nhiệm nhưng vẫn có một database và
một đơn vị triển khai. Điều này làm các transaction duyệt thợ/ghi sổ dễ kiểm soát
hơn trong phạm vi đồ án. Chưa có bằng chứng cần chi phí vận hành microservice;
nếu mở rộng, đo tải và xác định ranh giới sự kiện trước khi tách dịch vụ.

### Câu 3 Số bảng và API được tính thế nào

Catalog sau Flyway V21 có 30 bảng nghiệp vụ với 256 cột. Hai collection table
user_skills/user_project_images vẫn được tính vì thực sự tồn tại trong PostgreSQL.
flyway_schema_history là bảng kỹ thuật nên ghi riêng. Quét 28 Controller cho 111
cặp method/path, trong đó 90 dưới `/api/`, 21 route khác gồm Admin, ảnh và health.
Alias health tính riêng vì là đường dẫn riêng. POST form login/logout do filter
Spring Security xử lý và `/ws/chat` được ghi ngoài bộ đếm REST. Không cộng handler
mặc định `/error` như tính năng do nhóm tự xây. Nguồn kiểm toán: PROJECT_INVENTORY.json.

### Câu 4 JWT và phân quyền có chặn được người bị khóa dùng token cũ không

JWT có chữ ký và hạn dùng, nhưng trạng thái active vẫn được đối chiếu ở server.
AuthService từ chối đăng nhập và JwtAuthenticationFilter từ chối request của tài
khoản khóa bằng HTTP 403/ACCOUNT_LOCKED. Không đợi token tự hết hạn. Đăng ký công
khai chỉ nhận Thợ/Chủ thầu. Admin dùng session/form và CSRF; việc ẩn nút khóa Admin
chỉ hỗ trợ UI, service cũng chặn thao tác đó. Ngoài role, mỗi service còn kiểm
tra chủ công trình, chủ hồ sơ hoặc cặp hội thoại. Biết ID hoặc có token của một
tài khoản thường không đủ để đọc dữ liệu riêng của người khác.

### Câu 5 KYC đang tự động đến mức nào và bảo vệ ảnh CCCD ra sao

Tự động ở mức kiểm tra/giải mã ảnh, giới hạn dung lượng/pixel, chuẩn hóa JPEG và
bỏ metadata. Điều đó không xác nhận người trong ảnh hay giấy tờ có thật. Admin
đối chiếu hai mặt và quyết định duyệt. Ảnh lưu riêng dạng BYTEA, endpoint kiểm
tra quyền, không chứa JWT trong URL và không cache công khai. Upload mới đưa
verified về false. Dashboard gửi lại cả hai URL snapshot đã xem; nếu ảnh bị đổi
giữa lúc mở và duyệt thì yêu cầu cũ bị từ chối. Entity/database cũng chặn verified
khi thiếu mặt. Chưa có OCR/eKYC hoặc kết nối cơ sở dữ liệu dân cư.

### Câu 6 Hai Chủ thầu cùng nhận một thợ hoặc nhiều đơn cuối cùng có gây vượt số lượng không

Server khóa ghi công trình khi duyệt rồi khóa các worker theo thứ tự ID. Trong
transaction, server kiểm tra lại số ACCEPTED và lịch, sau đó mới đổi trạng thái.
Các yêu cầu cạnh tranh không chỉ dựa vào danh sách ứng viên đã tải ở giao diện.
Khóa worker khiến hai công trình cùng xét một người phải lần lượt đối chiếu lịch
đã commit. Khóa theo thứ tự giúp giảm vòng chờ khi một thao tác gồm nhiều thợ.
Test cạnh tranh kiểm chứng chỉ một lượt hợp lệ thành công trong tình huống trùng
lịch/công suất. Chưa có test tải để suy ra throughput hoặc thời gian đáp ứng lớn.

### Câu 7 Tổ đội có phải chỉ nhập số người và hệ thống chặn trùng lịch thế nào

Tổ đội gồm các tài khoản thợ thực có lời mời/xác nhận, không tin số lượng tự khai
từ client. Mỗi thành viên có đơn, cam kết, chấm công và đánh giá riêng. Duyệt nguyên
nhóm là một transaction: một người thiếu đồng thuận, bị khóa, không sẵn sàng hoặc
trùng lịch sẽ khiến cả lượt duyệt không hoàn tất. Lịch dùng ngày bắt đầu/kết thúc
bao gồm ngày kết thúc theo Việt Nam và các ngày bận do thợ khai. Công trình legacy
không có cặp ngày được giữ tương thích; không tự bịa lịch lịch sử. Nguồn: CrewService,
WorkerCalendarService và các test tổ đội/lịch.

### Câu 8 Thương lượng và cam kết điện tử có bị sửa sau khi đã nhận việc không

Đơn lưu giá đề xuất, ghi chú và giá đã chốt riêng. Người thợ đồng ý termsVersion
cụ thể, Chủ thầu chọn giá gốc hoặc giá đề xuất. Khi duyệt, server lưu văn bản
snapshot cùng SHA256 và thời điểm xác nhận hai phía. Sửa tin tuyển trước khi có
người được nhận sẽ tăng version, buộc đối chiếu lại đồng thuận. Snapshot đã chốt
không được tính lại theo nội dung hiện tại. SHA256 giúp phát hiện thay đổi nội dung
đã lưu nhưng không phải chữ ký số hay bằng chứng tự thân về giá trị pháp lý của
hợp đồng. Đồ án không tuyên bố đã tích hợp tổ chức chứng thực chữ ký số.

### Câu 9 Vì sao dùng Haversine và OpenStreetMap thay vì dịch vụ bản đồ trả phí

Haversine tính khoảng cách gần đúng giữa hai tọa độ trên bề mặt cầu, đủ để lọc
bán kính quanh tâm tìm kiếm trong phạm vi đồ án. JobRepository chỉ trả công trình
đang tuyển theo điều kiện, hỗ trợ loại thợ và sắp lương. flutter_map hiển thị tile
OpenStreetMap, ghim và điểm chọn. Attribution và user agent riêng được giữ; test
bản đồ dùng tile provider trong bộ nhớ để không tạo tải tile mạng. Khi dữ liệu lớn
cần đo kế hoạch truy vấn, cân nhắc PostGIS/index không gian. Không khẳng định truy
vấn lượng lớn đã tối ưu chỉ vì có Haversine. Chỉ đường mở ứng dụng bản đồ ngoài.

### Câu 10 Chấm công GPS và QR có chống gian lận tuyệt đối không

GPS yêu cầu cách công trình tối đa 200m và accuracy tối đa 100m; server quyết định
thời điểm/ngày công. QR ca làm do đúng Chủ thầu cấp, lưu hash, hết hạn sau 5 phút
và đổi mã sẽ vô hiệu mã trước. Mỗi đơn/ngày chỉ có một bản ghi. Tuy vậy GPS có thể
bị giả hoặc kém chính xác, QR có thể được người khác chia sẻ. Đây là các chứng cứ
hỗ trợ, chưa chống gian lận tuyệt đối. Ảnh cuối ca và duyệt của Chủ thầu bổ sung
bước kiểm tra trước trả công. Checkout hiện cùng ngày Việt Nam; ca qua đêm và điều
chỉnh công có audit là phần phát triển tiếp, không tự sửa giờ bằng client.

### Câu 11 Ví có ba số dư để làm gì và 200.000đ có tự chặn nhận việc không

Main là tiền khả dụng, escrow là ký quỹ, held giữ chỗ cho yêu cầu rút đang chờ.
Rút chuyển main sang held để ngăn gửi nhiều yêu cầu cùng tiêu số dư; từ chối trả
tiền về main. Mỗi biến động ghi ledger với delta từng ngăn và số dư sau. Ký quỹ
dưới 200.000đ chỉ cảnh báo, chưa chặn nhận việc và chưa thu phạt tiền tự động.
Sổ ví dùng BIGINT VND nguyên để tránh sai số tiền lẻ; trường lương tuyển gốc trong
jobs vẫn là DOUBLE PRECISION theo thiết kế legacy, còn đơn giá chốt/chi trả dùng
VND nguyên. Cần phân biệt điều đó khi giải thích kiểu tiền của toàn bộ hệ thống.

### Câu 12 Sinh VietQR có đồng nghĩa tích hợp thanh toán ngân hàng tự động không

Không. Server tạo chuỗi TLV theo QRIBFTTA với số tiền, BIN/tài khoản và nội dung
đối soát, tính CRC16 để kiểm tra cấu trúc. Điều này giúp điền sẵn thông tin, không
chứng minh tiền đã vào tài khoản. Yêu cầu PENDING chỉ được ghi có sau đối soát Admin.
Thông tin người nhận được snapshot theo yêu cầu, nên đổi cấu hình không đổi QR cũ.
Trong demo, BIN 000000 và DEMO ONLY cố ý không dùng để nhận tiền; UI cảnh báo rõ.
Muốn tự đối soát thật cần cổng/ngân hàng, webhook xác thực, khóa idempotency và
đối chiếu giao dịch ngoài. Dự án hiện chưa có kết nối chuyển tiền tự động đó.

### Câu 13 Làm sao tránh thanh toán một công trình hai lần hoặc trả ngày công không được duyệt

job_payments có application_id duy nhất. Service đối chiếu công trình hoàn thành,
đúng Chủ thầu, giá chốt và số ca trước khi tạo payment. Với công trình mới yêu cầu
chấm công, mọi ngày được trả phải checkout và ảnh APPROVED; workDays khớp số ca
hợp lệ. Payment, trừ ví Chủ thầu, cộng công/tip/thưởng cho Thợ và ledger cùng một
transaction; khóa ví và reference duy nhất chống ghi sổ lặp. Tip/thưởng là khoản
Chủ thầu xác nhận, không tự ước lượng. Một job legacy không có yêu cầu chấm công
được xử lý theo nhánh tương thích đã tài liệu hóa, không tự tạo bằng chứng ca cũ.

### Câu 14 Điểm sao, uy tín và bậc thợ khác nhau thế nào

Sao là trung bình các điểm 1–5 từ công trình COMPLETED, chưa có sao giữ 5.0. Uy tín
là điểm 0–100 và có lịch sử sự kiện. Hủy ACCEPTED trừ 15 điểm một lần rồi tính lại
bậc, không phải tự trừ tiền. GOLD cần ≥80 uy tín, ≥4.0 sao, ≥5 công trình. DIAMOND
cần ≥95, ≥4.7, ≥20 công trình và KYC. Các trường hợp khác SILVER. Tính sao khóa
worker và lấy lại điểm thực tế, không lấy trung bình của các trung bình. Khi xóa
công trình có đánh giá, hệ thống tính lại dữ liệu liên quan. Top 3 demo được tạo
từ đơn/công trình có sao thật trong database mẫu, không chỉ gán số ở giao diện.

### Câu 15 Chat realtime có an toàn và có mất tin khi mạng chập chờn không

REST là nguồn lưu trữ chính; WebSocket đưa sự kiện sau commit. History và ID giúp
khôi phục, khử trùng khi kết nối lại. clientMessageId ổn định cho lần gửi lại giúp
server không tạo thêm tin cho cùng nội dung; dùng cùng ID với payload khác bị từ
chối. Chat chỉ cho cặp đã ACCEPTED, kể cả API đọc ảnh phải kiểm tra lại quyền và
trạng thái tài khoản. Admin không được dùng quyền quản trị để đọc tùy ý chat riêng.
Read cursor tăng đơn điệu, chỉ đánh dấu khi màn hình chat đang hoạt động và ở cuối.
Không hứa exactly-once delivery ở tầng mạng; mục tiêu là tác động lưu trữ idempotent.

### Câu 16 Thông báo, SOS và thời tiết xử lý dịch vụ ngoài lỗi ra sao

Thông báo có lịch sử DB và outbox, nên FCM không cấu hình không làm mất mục lịch
sử. Push thật cần Firebase, service account và token thiết bị; chưa tuyên bố đã
gửi push production. SOS lưu báo cáo riêng tư và audit, ưu tiên hàng chờ Admin,
không tự liên hệ cứu hộ. Thời tiết gọi cố định Open-Meteo với tọa độ làm tròn, cache,
timeout và single-flight; khi lỗi trả unavailable hoặc dữ liệu cũ có nhãn. Không
đặt nhiệt độ giả bằng 0 hoặc khóa nhận việc vì weather provider lỗi. Các dịch vụ
ngoài phục vụ hỗ trợ, không quyết định sai lệch dữ liệu ví/công trình khi gián đoạn.

### Câu 17 Nâng cấp database cũ có mất dữ liệu và rollback bằng Git có đủ không

Flyway nhận database legacy bằng baseline 11 rồi chạy V12–V21 theo thứ tự. Database
mới chạy V1 và các phiên bản tiếp theo. V1 và migration đã phát hành giữ bất biến,
clean bị tắt, JPA production validate. Migration thêm trường/backfill với quy tắc
bảo toàn, ví dụ không tự tạo đồng thuận cho đơn cũ. Test dùng schema PostgreSQL
riêng để kiểm tra khởi tạo mới, nâng cấp legacy và chạy lại không đổi dữ liệu.
Git rollback chỉ khôi phục mã nguồn, không đảo ngược dữ liệu đã ghi. Triển khai
thật cần backup, thử restore và đánh giá tương thích schema trước khi quay lại phiên bản.

### Câu 18 Tại sao 100 phần trăm test pass chưa chứng minh ứng dụng không còn lỗi

125 Backend, 110 Flutter, 12 JS và 6 Python đều pass ở lần kiểm chứng được ghi nhận,
nhưng đó là tập ca đã viết, không phải mọi đầu vào hoặc độ bao phủ 100%. Backend
có test ACL, giao dịch, ảnh, concurrent acceptance và migration PostgreSQL riêng.
Flutter kiểm tra API/widget/theme, map dùng fake tile, camera/QR dùng mô phỏng khi
test. Chrome demo gọi API thật bổ sung bằng chứng UI. Chưa có nghiệm thu mọi thiết
bị Android, ngân hàng thật hoặc thử tải quy mô lớn. Một regression đã sửa là ngày
thu nhập khác giữa H2/UTC và Windows; JVM test mặc định UTC để giữ ca này được kiểm tra.

### Câu 19 Vì sao triển khai Vercel cộng Render và lỗi timeout được xử lý thế nào

Vercel phục vụ Flutter Web tĩnh, còn Spring Boot/Admin cần tiến trình Java lâu dài
nên chạy Docker trên Render cùng PostgreSQL managed. APK dùng HTTPS Render như Web.
Render Free có cold start; client chờ GET readiness với thời gian giới hạn, chia sẻ
một lượt chờ và cho hủy khi dispose. Chỉ health retry, không tự lặp POST nạp tiền,
ứng tuyển hoặc gửi ảnh. CORS giới hạn origin Web được cấu hình nhưng không thay
JWT/ACL. GitHub Actions kiểm tra trước build Docker/Web/APK và lưu APK artifact;
chỉ kết luận đã triển khai khi đối chiếu run/deploy thật, không chỉ thấy git push thành công.

### Câu 20 Hạn chế lớn nhất và hướng phát triển ưu tiên là gì

Ưu tiên tiếp theo là nghiệm thu camera/GPS/QR trên thiết bị thật, ca qua đêm và
quy trình sửa công có audit, quan trắc lỗi/backup và kiểm thử tải. Khi có cấu hình
và dịch vụ phù hợp mới tích hợp FCM production, eKYC và đối soát ngân hàng có
webhook xác thực. Nếu mở rộng nhiều instance cần phát sự kiện qua broker và xem
xét object storage riêng tư/PostGIS sau đo đạc. Đồ án hiện chứng minh luồng phần
mềm và tính nhất quán dữ liệu trong phạm vi test, chưa chứng minh danh tính thật,
giá trị pháp lý chữ ký số hay hiệu quả kinh tế bằng khảo sát. Trình bày rõ giới hạn
giúp Hội đồng kiểm chứng đúng phần thực hiện thay vì kỳ vọng khả năng chưa có.

## Danh mục đối chiếu nhanh

- Báo cáo đầy đủ: `BAO_CAO_DO_AN.md` và `BAO_CAO_DO_AN.docx`.
- Số liệu schema/API: `PROJECT_INVENTORY.json`.
- Quy tắc triển khai: `ADVANCED_UPGRADE.md`, `DATABASE_MIGRATIONS.md`.
- Dữ liệu và cấu hình demo: `DEMO.md`; các script seed từ chối database thật.
- Slide có thể chỉnh sửa và xem Notes: `SLIDE_BAO_VE_DO_AN.pptx`.

Không đọc nguyên văn toàn bộ câu trả lời khi bảo vệ. Trả lời kết luận trước,
sau đó mở đúng service/test hoặc màn hình để chứng minh nếu Hội đồng yêu cầu.
