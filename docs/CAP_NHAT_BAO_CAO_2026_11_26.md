# Cập nhật báo cáo và thuyết trình ngày 26 tháng 11 năm 2026

Báo cáo Word và PowerPoint được chỉnh thủ công theo yêu cầu trực tiếp của
người dùng, đối chiếu ứng dụng tại checkpoint `8a7949c`. Tác vụ này không thay
đổi mã nguồn ứng dụng hoặc quy trình build.

- Word: 72 trang, 44 bảng; logo theo `mobile_app/assets/branding/app_icon.png`.
- PowerPoint: giữ 13 slide, bố cục và các đối tượng có thể chỉnh sửa.
- Kiến trúc hiện tại: Flutter Web trên Vercel; API/Admin trên EC2 t4g.small,
  Ubuntu 24.04 ARM64, 2 vCPU, 2 GiB RAM, gp3 30 GB tại Sydney.
- Spring Boot chạy Java 17 bằng systemd; PostgreSQL 17 chạy trong Docker;
  Nginx cung cấp HTTPS/HTTP/2. Cấu hình triển khai tham chiếu `deploy/aws/`.
- Từ điển bổ sung bốn cột tài khoản và ba bảng của migration V24–V27.
  Mô hình sau nâng cấp có 34 bảng nghiệp vụ và 273 cột, tính từ catalog V23
  cộng các migration này. ERD cũ được ghi rõ phạm vi 31 bảng cốt lõi.
- Số bảng vật lý của bản sao vận hành được phân biệt với số bảng nghiệp vụ.

## Kiểm chứng

Nhật ký Maven verify ngày 25/11/2026 ghi nhận 159 bài: 156 đạt, 3 bỏ qua,
không thất bại hoặc lỗi. Ba bài bỏ qua thuộc kiểm thử tích hợp PostgreSQL.
Lần chạy đầy đủ `flutter test` ngày 26/11/2026 có 281 đạt và 2 chưa đạt;
hai trường hợp nằm trong `server_warmup_test.dart`. Word và slide trình bày
các kết quả này, không khẳng định toàn bộ kiểm thử đều đạt.

Word đã cập nhật mục lục bằng Microsoft Word và kết xuất để kiểm tra bố cục.
PowerPoint đã kết xuất đủ 13 slide; 11 slide không sửa có ảnh kết xuất giống
bản gốc. Gói OOXML, liên kết mục lục, logo và hình học của slide đã kiểm tra.
Đây là thay đổi tài liệu; không có mã mới để biên dịch. Chạy `git diff --check`
cho phần ghi nhận trong kho mã.

## Dấu vân tay bản bàn giao

| Tệp | SHA-256 |
| --- | --- |
| `Mo_ta_de_tai_Tho_Xay_cap_nhat.docx` | `08fff8928e391529a790385a82e5d44f2adf01489b0b4cf5f004596b7de810cf` |
| `Thoxay_thuyet_trinh_cap_nhat.pptx` | `d749df44b63125788d3bae26f4da563c856c2aac59aeb63f81669993ee6939a8` |

Bản gốc được giữ dự phòng trước khi thay nội dung tại vị trí người dùng đang
sử dụng. Các script biên soạn và kiểm tra chỉ chạy thủ công cho tác vụ này.
