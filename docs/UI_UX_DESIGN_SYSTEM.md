# Hệ thống giao diện ThoXay

## Quy ước hiển thị

| Thành phần | Quy ước |
| --- | --- |
| Thợ | Cam `#EA580C` |
| Chủ thầu | Xanh lục bảo `#059669` |
| Admin | Nền `#0F172A`, sidebar `#1E293B`, điểm nhấn `#3B82F6` |
| Thông tin phụ Flutter | `#64748B` |
| Khoảng cách | Nhịp 8px; padding 16/24px; gap 8/12/16px |
| Thẻ | Bo góc 16px, bóng nhẹ; thông tin quan trọng in đậm |
| Flutter Web | Navigator căn giữa, tối đa 1120px; MediaQuery khớp khung thực tế |

Trang chủ có lời chào, avatar chữ cái từ tên thật, bậc thợ lấy từ hồ sơ,
công tắc nhận việc và thanh điều hướng 5 mục. Tìm kiếm tên/địa điểm xử lý
trên kết quả hiện có; loại việc, lương và bán kính tiếp tục dùng API cũ.
Bộ lọc ghim khi cuộn, cuộn ngang trên màn hình nhỏ. Chi tiết công trình
giữ vùng hành động ở đáy; quyền liên lạc vẫn theo đơn ACCEPTED.

Chat giữ nguyên REST/WebSocket và quyền truy cập. Nút lời chào chỉ điền
bản nháp. Podium Top 3 giữ thứ tự API; hồ sơ thể hiện các tiêu chí lên hạng,
không tự cấp bậc ở phía client. Skeleton dùng chung tôn trọng chế độ giảm
chuyển động và dừng ở route không hoạt động.

Ví hỗ trợ ẩn cả ba số dư, thao tác nạp/rút cân đối và cảnh báo ký quỹ theo
minimumEscrow/lowEscrow từ server. Biểu đồ thể hiện cơ cấu tiền công, tip,
thưởng trong kỳ Ngày/Tuần/Tháng được chọn; API hiện trả tổng kỳ, không có
chuỗi thu nhập từng ngày. Không suy diễn hoặc chia đều tổng tiền thành số
liệu ngày giả. Màu giao dịch phân biệt tiền cộng, tiền ra và chuyển ký quỹ.

CCCD có khung hướng dẫn tỷ lệ 85.6:53.98 trước khi chụp/chọn ảnh, ảnh xem
trước và cửa sổ phóng to 1–5 lần. Camera vẫn sử dụng image_picker của nền
tảng; khung trong ứng dụng không chèn vào giao diện camera gốc. Kiểm tra
tệp và duyệt danh tính của Admin giữ nguyên.

## Dữ liệu và giới hạn của hợp đồng API hiện có

- Badge điều hướng dùng unreadCount thật của lịch sử thông báo, cập nhật
  khi quay lại, khi ứng dụng hoạt động lại và định kỳ khi trang chủ hiện.
  API chưa có số tin nhắn chưa đọc theo cuộc hội thoại; không gắn số giả.
- JobResponse chưa trả trạng thái KYC của chủ thầu. Thẻ việc không tự gắn
  tích xanh. Hồ sơ và danh sách thợ vẫn hiển thị xác thực từ dữ liệu thật.
- Admin lọc dữ liệu đã render, có tìm kiếm không phân biệt dấu tiếng Việt.
  Hàng chờ ví chỉ chứa yêu cầu PENDING và phân trang theo API cũ; bộ lọc
  áp dụng trên trang hiện tại, không giả lập lịch sử đã duyệt/từ chối.
- Lightbox Admin chỉ mở ảnh đã tải ở modal KYC, phóng to tối đa 400%, hỗ
  trợ Enter/Space, Esc và nút đóng. Đóng/chuyển hồ sơ xóa URL ảnh phóng to.
  Hai snapshot ảnh và điều kiện cho phép duyệt không thay đổi.

## Kiểm chứng

```powershell
.\mvnw.cmd verify
cd mobile_app
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
```

```sh
node --test scripts/deployment.test.mjs scripts/tests/admin-kyc.test.cjs scripts/tests/admin-ui.test.cjs
```

Workflow APK trên main tiếp tục build release với API HTTPS Render.
Kiểm tra giao diện ở điện thoại 320/390px, tablet 768px và desktop rộng;
kiểm tra cả phóng lớn chữ, thao tác bàn phím và trạng thái dữ liệu trống.
Không thay đổi Controller, Service, Entity, schema hoặc URL API trong đợt
nâng cấp giao diện này.

## Redesign Flutter Web/App theo skill web-design (L2)

Phương án đã được người dùng duyệt trong `DESIGN.md` tại thư mục gốc.
Đợt này chỉ đổi frontend Flutter và phần khởi động Flutter Web, giữ nguyên
các tệp Thymeleaf/CSS/JS của Admin, Backend, models và ApiService.

- Canvas trung tính `#F7F8FA`, bề mặt trắng, chữ đậm `#182230`; điểm nhấn
  Thợ `#EA580C`, Chủ thầu `#059669`. Token tập trung tại `AppColors`/`AppTheme`.
- Font Plus Jakarta Sans có hỗ trợ tiếng Việt được đóng gói trong app;
  giấy phép OFL đi kèm trong `mobile_app/assets/fonts/`, không tải font runtime.
- Auth desktop hai cột; mobile thu gọn phần thương hiệu và ưu tiên form.
- Công trình hai cột khi vùng danh sách rộng từ 820px, một cột ở điện thoại.
  Các trang tài chính/hồ sơ/thông báo giới hạn chiều rộng nội dung 840px.
- L2 dùng reveal khi vào viewport, hover spotlight, pill/segmented controls
  và minh họa công trình có parallax giới hạn; tôn trọng disableAnimations.
  Không thêm thư viện animation hoặc ticker nền chạy vô hạn.
- Context công trình trong Chat nằm dưới AppBar, không bị toolbar cắt mất.
- Ví, thu nhập, thông báo, bảng xếp hạng, uy tín, hồ sơ, KYC và các dialog
  dùng chung typography, border, card, trường nhập và trạng thái tương tác.
- Flutter Web có trạng thái khởi động và favicon SVG theo thương hiệu;
  loader tự gỡ khi nhận flutter-first-frame, có chế độ giảm chuyển động.

Kiểm chứng đợt redesign: 66 test Backend tại checkpoint trước thay đổi;
56 test Flutter pass; flutter analyze sạch; build Web release thành công.
Test mới kiểm tra Auth 320/1440px khi chữ phóng 1.4 lần, reveal theo viewport,
giảm chuyển động và lưới công trình một/hai cột. Kiểm tra Chromium headless
ở 390px và 1440px cho Auth, Thợ, Chủ thầu, Ví và Hồ sơ; dữ liệu QA chỉ ở trình duyệt,
không ghi vào database. Ảnh kiểm tra nằm trong `.local/redesign/` (không commit).

Các checkpoint: `02a5a2d` trước redesign, `8024042` hệ thiết kế/Auth,
`cc2081a` trang chủ/công trình, `3db4662` các màn hình và responsive.
Hai chỉnh sửa riêng đang có trong báo cáo Word và application.properties
được giữ nguyên ngoài các commit redesign.
