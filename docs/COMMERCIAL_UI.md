# Giao diện thương mại ThoXay

## Hướng thiết kế ngày 03 11 2026

Nền sáng #F8FAFC được cân bằng bằng hero Navy #0F172A có lưới mờ tại Trang chủ,
Ví và Hồ sơ. Cam #EA580C cho Thợ, Xanh lục bảo #059669 cho Chủ thầu; nút có
bóng nhẹ và màu đủ tương phản. Avatar chỉ hiện chấm Online khi có trạng thái
nhận việc thực tế, không suy từ việc đăng nhập.

Lưới tay nghề có ba ảnh trên mobile, bốn ảnh trên desktop, chú thích phủ ở đáy
ảnh và mở đầy đủ album. Không tạo ô ảnh trống hay gán ảnh stock làm dự án của
người dùng thật. `scripts/demo_photos.py` chỉ bổ sung album tài khoản DEMO trên
localhost, giữ nguyên ảnh đã nghiệm thu và mọi số dư. Nguồn và giấy phép tại
[demo_photos/CREDITS.md](demo_photos/CREDITS.md).

Bản đồ dùng tile OSM mạng, ghim mức lương rút gọn, vòng bán kính 200m quanh
công trình và thẻ xem nhanh tương tác. Vòng này mô tả vùng chấm công; không
thay bộ lọc tìm việc 2/5/10/20km. Khi lỗi tile, phải báo lỗi và cho tải lại,
không thay bằng ảnh bản đồ giả. Attribution OSM luôn hiển thị.

## Bất biến nghiệp vụ

- Không ghi cứng số dư hoặc uy tín trong hình mẫu vào tài khoản thực tế.
- Mức 200.000đ là ngưỡng khuyến nghị của ví; chưa bảo lãnh tiền cọc từng việc.
- Phạt hủy đơn ACCEPTED trừ 15 điểm theo server, không tự thu tiền phạt.
- Chỉ ghi nhận hai bên xác nhận khi dữ liệu cam kết có đủ hai thời điểm.
- GPS chỉ hợp lệ trong 200m, độ chính xác tối đa 100m; QR có hạn 5 phút.
- Album và ảnh ca làm giữ endpoint riêng tư, JWT/phiên Admin và no-store.

## Kiểm tra ảnh thiếu

Vòng tái hiện đọc API portfolio nhận HTTP 200 nhưng chỉ một ảnh minh họa từ
seed cũ. Sau khi bổ sung có bốn ảnh chụp thật dùng minh họa DEMO. Chạy lặp giữ
nguyên UUID của album, không nhân bản ảnh. Flutter không gọi ảnh riêng tư bằng
URL công khai hoặc đính JWT vào query string.

## Bốn màn hình lõi

17. Phiếu cam kết: mã từ ID đơn, lương chốt, tên và trạng thái KYC thực của hai
bên, dấu vết đồng thuận và toàn văn snapshot/hash. Mở từ thẻ ghim trong Chat.
18. Radar chấm công: OSM, vòng 200m, khoảng cách Haversine và sai số GPS;
check-in/out dùng lần đọc cảm biến mới, server quyết định. Đồng hồ bắt đầu từ
giờ check-in server, QR mở camera toàn màn hình và có hạn 5 phút.
19. Trung tâm hỗ trợ: thông báo công việc, giao dịch ví gần nhất, chọn công trình
tham gia, gửi khiếu nại/SOS và ảnh bằng chứng, theo dõi phản hồi Admin.
20. Admin Control Center: sidebar Navy, bốn KPI kèm tỷ lệ thật, xem nhanh lệnh ví
và tranh chấp; các bảng KYC, công trình và modal đối chiếu giữ kiểm soát quyền.
Biểu đồ nhỏ thể hiện tỷ trọng hiện tại, không dựng lịch sử tăng trưởng.

V23 thêm `incident_evidence` riêng để hàng chờ không tải BLOB ảnh. Gửi multipart
`POST /api/jobs/{id}/incidents/with-photo`; đọc ảnh qua
`GET /api/incidents/{id}/evidence` hoặc `/admin/incidents/{id}/evidence`.
Ảnh được chuẩn hóa, tối đa 2MB sau xử lý, chỉ người gửi/Admin xem và no-store.
Retry cùng yêu cầu/ảnh không tạo trùng; ảnh đã gửi không bị thay bằng payload khác.

Kiểm tra: 131 Backend, 119 Flutter, 12 JS và 8 Python pass; analyzer sạch,
JAR và Flutter Web release thành công. QA dùng dữ liệu DEMO riêng và mô phỏng
quyền/vị trí GPS trong trình duyệt, không thay thế nghiệm thu thiết bị vật lý.
