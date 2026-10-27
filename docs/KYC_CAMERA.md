# Chụp CCCD bằng camera

Sau khi đăng ký, Thợ và Chủ thầu mở **Hồ sơ & CCCD**, chụp riêng hai mặt,
xem lại ảnh rồi chọn **Cập nhật CCCD**. Không còn nhập URL trên Flutter.
Hủy camera giữ nguyên ảnh đã chọn; lỗi tải lên giữ hai ảnh để gửi lại.
Ảnh được thu nhỏ tối đa 1800 px trước khi gửi. Android phục hồi kết quả camera
khi hệ điều hành hủy Activity; ảnh phục hồi chỉ gắn với đúng tài khoản đã chụp.
Desktop dùng chọn tệp vì image_picker không có camera mặc định trên desktop.
Flutter Web dùng bộ chọn/chụp do trình duyệt cung cấp; camera trên trình duyệt
có thể yêu cầu HTTPS hoặc localhost, tùy thiết bị. APK dùng camera Android.
iOS có mô tả quyền camera/thư viện trong Info.plist; cần kiểm chứng trên thiết bị thật.

## Backend và quyền riêng tư

- Chạy `migrations/011_kyc_photos.sql` sau các migration trước đó. Script chạy
  lại an toàn; `scripts/start-local.ps1` áp dụng tự động cho PostgreSQL portable.
- `POST /api/users/me/cccd/photos`, Bearer JWT, `multipart/form-data`, hai phần
  **front** và **back**. Chỉ ROLE_WORKER/ROLE_CONTRACTOR đang hoạt động.
- Tối đa 5 MB mỗi ảnh, 11 MB tổng request. Kiểm tra nội dung thực là JPEG/PNG,
  từ 320×200 px (chấp nhận xoay dọc), tối đa 6000 px mỗi cạnh / 16 triệu pixels.
  Hai ảnh giống hệt sau xử lý bị từ chối. Đây là kiểm tra tệp, không phải OCR,
  xác minh giấy tờ thật, kiểm tra khuôn mặt hay đối soát cơ sở dữ liệu dân cư.
- Backend giải mã và mã hóa lại JPEG, loại bỏ metadata; không tin tên tệp,
  đuôi tệp hay MIME do client cung cấp. Hai mặt được thay cùng giao dịch;
  lỗi một mặt không ghi đè hồ sơ cũ. Mỗi lần thay ảnh đặt `is_verified=false`.
- Ảnh lưu dạng BYTEA trong `kyc_images` của PostgreSQL, không nằm trong thư mục
  static và không có URL công khai. Sao lưu và phân quyền database phải bao gồm
  bảng này. Ảnh cũ được xóa khi thay hồ sơ; xóa user sẽ xóa ảnh theo cascade.
- `GET /api/users/me/cccd/images/{uuid}` chỉ chủ hồ sơ hoặc Admin dùng JWT.
  `GET /admin/kyc/images/{uuid}` chỉ Admin có phiên đăng nhập. Trả JPEG,
  `Cache-Control: no-store` và `nosniff`; không đưa JWT vào URL.
- Admin mở modal để xem hai mặt và xác thực thủ công. Snapshot hai URL bảo vệ
  việc duyệt nhầm khi hồ sơ đã thay ảnh. Modal xóa nguồn ảnh khi đóng.
- API JSON `PUT /api/users/me/cccd` dùng URL HTTPS được giữ cho client cũ;
  Flutter mới chỉ dùng ảnh chụp. Tài khoản cũ vẫn giữ ảnh/duyệt hiện có.

Tham khảo chính thức: [image_picker](https://pub.dev/packages/image_picker)
và [Spring multipart](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-methods/multipart-forms.html).
