# Đồng bộ giao diện theo 16 ảnh thiết kế

Ngày cập nhật: 02/11/2026. Bộ PNG gốc được giữ nguyên trong `figma_screens/`,
có hash và bản sao trình chiếu. Đây là tham chiếu thị giác; ứng dụng dựng bằng
widget Flutter thực, không chèn ảnh màn hình làm giao diện tương tác.

## Ánh xạ màn hình và phần đã nối với nghiệp vụ

| Ảnh | Màn hình hoặc thành phần thực thi |
| --- | --- |
| Thợ Đăng nhập & Vai trò | `LoginScreen`, `AuthShell`, `RoleCards`; vai trò chọn trước đổi giao diện, quyền đăng nhập vẫn lấy từ JWT của server |
| Thợ Tìm việc | `WorkerHomeScreen`, tìm kiếm/chips ghim, bộ lọc GPS/bán kính mở rộng, preview OSM và `JobCard` |
| Thợ Chi tiết việc | `showJobDetails`, vị trí/chỉ đường, lương, hướng dẫn thương lượng và CTA cố định mở cam kết hiện có |
| Thợ Việc của tôi & Chấm công | Lịch tuần theo công trình đã nhận, `AttendanceScreen`, GPS/QR, `WorkPhotoReportDialog` hai ảnh và SOS |
| Thợ Ví tiền | `WalletScreen`, ẩn/hiện số dư, ký quỹ, tiền giữ rút, thống kê tuần và ledger |
| Thợ Nạp ví VietQR | `DepositDialog`, mệnh giá nhanh, QR từ payload server, sao chép nội dung và trạng thái chờ đối soát |
| Thợ Hồ sơ | `ProfileSummary`, ba thống kê thực, uy tín, tiến trình lên bậc, portfolio ba cột và KYC hai mặt |
| Thợ Trò chuyện | `ChatScreen`, cam kết ghim chỉ đọc, bong bóng cam nhạt, ảnh/GPS và lịch sử thật |
| Thợ Bảng xếp hạng | `LeaderboardScreen`, podium 2–1–3 màu Bạc/Vàng/Đồng cho thứ hạng, bậc nghề độc lập theo API |
| Chủ thầu Đăng việc | `ContractorHomeScreen`, ba thống kê trạng thái thực, CTA, preview bản đồ và công trình đang làm ở đầu |
| Chủ thầu Tạo công trình mới | Form hiện có, preview chạm chọn tọa độ, bản đồ đầy đủ, lịch và dự toán quỹ lương hữu hạn |
| Chủ thầu Duyệt thợ | Bộ lọc đơn, `ApplicantEvidence`, uy tín/kinh nghiệm/portfolio thực, thương lượng và duyệt có kiểm tra đồng thuận |
| Chủ thầu Nghiệm thu | `AttendanceScreen`, hai ảnh riêng tư, duyệt phiên bản đã xem, đánh giá/hoàn thành và mở thanh toán ngày công |
| Chủ thầu Ví & Quỹ lương | Ví cùng API, ký quỹ tài khoản, thống kê chi trả từ ledger đã tải, nạp/rút và đối soát |
| Chủ thầu Hồ sơ & Thợ ruột | Hồ sơ/KYC, `SavedWorkersPreview`, xem thợ đã lưu và chuẩn bị lời mời qua liên kết công trình |
| Chủ thầu Trò chuyện & Cam kết | Bong bóng xanh, cam kết ghim, ảnh/GPS có ACL và trạng thái kết nối |

## Token và responsive

Nền sáng #F8FAFC, surface #FFFFFF, viền #E2E8F0; card 12–16px, padding 16/20/24px.
Không dùng gradient hoặc shadow trên surface, hero, hồ sơ hay thẻ ví. Cam #EA580C
và Xanh #059669 vẫn là accent theo vai trò; container #FFF7ED/#ECFDF5. CTA chữ trắng
nhỏ dùng sắc đậm #C2410C/#047857 để giữ tương phản đọc; không thay accent vai trò.
Tối/Outdoor và reduced motion vẫn được hỗ trợ bằng palette ngữ nghĩa.

Mobile có bốn mục chính. Màn hình rộng giữ thêm Thông báo/Tin nhắn trực tiếp;
mobile truy cập hai mục này qua toolbar và tiện ích hồ sơ, badge hồ sơ tổng hợp
số chưa đọc. Khung desktop tối đa 1120px, các màn hình đọc dài tối đa 840px.
Bản đồ preview không bắt thao tác kéo, tối đa ba ghim thật; bản đồ đầy đủ giữ
tất cả kết quả lọc, pan/zoom và attribution OSM luôn thấy được.

## Dữ liệu và giới hạn cần phân biệt với bản vẽ

- Không ghi cứng số dư, KYC, tên người, số công trình, điểm uy tín hoặc mức lương mẫu.
- Không có API phần trăm đúng hẹn hay trạng thái đã xem theo từng tin: không tự dựng số.
- Ký quỹ hiện là số dư tài khoản; đăng việc chưa tự khóa ngân sách theo công trình.
  Form ghi **Dự toán quỹ lương**. Chi trả vẫn từ số dư khả dụng sau các điều kiện server.
- Lời mời thợ quen chuẩn bị/copy liên kết để chia sẻ; chưa tự gửi push hay nhận việc thay thợ.
- Mã nạp dùng nội dung đối soát duy nhất do server sinh, không thay thành chuỗi tĩnh `THOXAY NAP`.
- API chỉ có loại `Thợ chính/Phụ hồ`; các nhãn kỹ năng trong PNG không tự trở thành bộ lọc server.
- KYC vẫn do Admin duyệt, GPS 200m/accuracy 100m, QR 5 phút; không dùng con số 100m trong bản vẽ thay quy tắc đã chốt.
- Camera và ngân hàng thật cần thiết bị/dịch vụ tương ứng; ảnh PNG và test giả không chứng minh đã nghiệm thu thiết bị.

## Báo cáo hai ảnh tương thích dữ liệu cũ

Flyway V22 thêm `work_logs.detail_photo` nullable, CHECK tối đa 2MB sau chuẩn hóa.
Upload cũ một ảnh vẫn hợp lệ. Client mới chọn/xem trước đủ hai ảnh rồi gửi chung
một multipart với `photo` và `detailPhoto`, chung caption/ngày/phiên bản. Đọc ảnh
chi tiết bằng tham số `detail=true` trên endpoint ảnh cũ; kiểm tra quyền và no-store
được giữ cho cả JWT lẫn phiên Admin. Thay một trong hai ảnh làm tăng version và
vô hiệu hóa thao tác nghiệm thu bằng phiên bản cũ. Báo cáo đã APPROVED không sửa.

## Kiểm chứng

128 test Backend (thêm ba ca cho ảnh chi tiết), 114 Flutter (thêm bốn ca cho hai
ảnh/role cards/dự toán), 12 JS và 6 Python bảo vệ demo. Map widget test dùng
TileProvider trong bộ nhớ, không gọi tile mạng. Test outbox tự đặt bản ghi đến hạn
để không phụ thuộc làm tròn timestamp/đồng hồ. Analyzer sạch, JAR và Web release
được build trước checkpoint. QA trình duyệt chỉ dùng database demo localhost.

`scripts/refresh-demo-presentation.py` bổ sung kịch bản theo ngày vào database demo
riêng sau V22, gồm ca có hai ảnh và ứng viên chờ duyệt. Chạy lặp không đổi kịch bản
đã có, không sửa số dư, rating, KYC hoặc tài khoản cũ; từ chối database production.
