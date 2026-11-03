# Bộ 20 màn hình thực thi Xây

Ngày 03/11/2026, bộ 16 PNG thiết kế cũ được thay bằng **20 ảnh chụp ứng dụng
đang chạy** với database DEMO riêng. Tên thư mục lịch sử được giữ để các liên kết
báo cáo và hồ sơ bảo vệ tiếp tục hoạt động. Bản thiết kế cũ khôi phục từ Git trước
checkpoint Commercial UI; các ảnh mới không phải PNG Figma nguyên gốc.

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
19 view Flutter chụp ở viewport mobile; Admin ở viewport desktop. Bản sao nguyên
byte nằm trong `00_BAO_VE_DO_AN/06_ANH_THIET_KE_FIGMA/`.

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
