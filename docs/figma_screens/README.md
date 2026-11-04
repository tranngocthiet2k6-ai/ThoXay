# Bộ 20 màn hình thực thi Thợ Xây

Ngày 04/11/2026, cập nhật **20 ảnh chụp ứng dụng đang chạy** với thương hiệu
**Thợ Xây** và database DEMO riêng. Đây là ảnh giao diện thực thi, không phải
PNG Figma nguyên gốc. Thư mục hồ sơ bảo vệ và workspace bảo vệ không được tạo lại.

Chạy lại sau `scripts/start-demo.ps1`:

```powershell
node scripts/capture-commercial-ui.mjs --publish
```

Script chỉ truy cập localhost, lấy thông tin đăng nhập từ tệp riêng trong `.local`,
không ghi token/mật khẩu vào ảnh hoặc manifest. Chỉ công bố khi đủ 20 ảnh và không
có lỗi JavaScript chưa xử lý. Nạp ví chỉ tạo yêu cầu DEMO chờ duyệt, không chuyển
tiền. GPS trình duyệt được mô phỏng để kiểm thử Haversine, cách tâm khoảng 35m;
không thay thế kiểm thử GPS điện thoại thật. Đồng hồ chỉ chạy sau check-in server.

[manifest.json](manifest.json) lưu SHA256, kích thước, viewport và thời gian chụp.
19 view Flutter chụp ở viewport mobile; Admin ở viewport desktop.
Các ảnh kiểm tra trang chủ Desktop được giữ riêng trong `.local/commercial/`.

Thẻ tìm việc mở toàn bộ khi bấm, không lặp nút ứng tuyển. Thanh đáy chi tiết
gom chat, thương lượng và ứng tuyển; thương lượng mở bằng Bottom Sheet.
GPS/QR cùng hàng, SOS trên thanh tiêu đề; nghiệm thu có thao tác cố định ở đáy.
Ví dùng thống kê tuần trong thẻ số dư, hồ sơ đã KYC thu gọn trạng thái CCCD.
Các ảnh tay nghề được sắp 3 ảnh vuông mỗi hàng.

16 luồng ban đầu: Đăng nhập; Tìm việc; Chi tiết; Chấm công; Ví; Nạp VietQR;
Hồ sơ Thợ; Chat Thợ; Xếp hạng; Trang chủ Chủ thầu; Tạo công trình; Duyệt ứng viên;
Nghiệm thu; Ví Chủ thầu; Hồ sơ và Thợ quen; Chat Chủ thầu.

Bốn view bổ sung: **17 Phiếu cam kết**, **18 Radar GPS/QR toàn màn hình**,
**19 Trung tâm Thông báo/SOS**, **20 Web Admin Control Center**.

Hero Navy #0F172A, điểm nhấn Cam #EA580C/Xanh #059669, lưới mờ, portfolio đầy ảnh,
OSM có attribution, ghim lương và vòng 200m. Nguồn ảnh công trình thật có nhãn
DEMO tại [CREDITS.md](../demo_photos/CREDITS.md); không chứng minh danh tính hay
tay nghề người dùng thực. Số dư, lương, điểm và KYC lấy từ API demo. Khuyến nghị
ký quỹ 200.000đ không bảo đảm cọc riêng công trình; SOS không tự gọi cứu hộ;
VietQR không tự cộng tiền.
