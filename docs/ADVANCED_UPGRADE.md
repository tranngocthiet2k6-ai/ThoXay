# Nâng cấp nghiệp vụ ThoXay — kế hoạch và quy tắc

Phạm vi: Spring Boot, PostgreSQL, Flutter Mobile/Web và Thymeleaf Admin.
Giữ màu Thợ Cam, Chủ thầu Xanh lục bảo, Admin Navy và các quyền hiện có.
Hai chỉnh sửa riêng trong báo cáo Word/application.properties không nằm trong checkpoint.

## Những phần đang có

Responsive 1120px, thẻ việc hai cột desktop, shimmer, empty states, snackbar,
pull-to-refresh, hero, công tắc nhận việc, lọc việc, KYC hai mặt và zoom,
podium, ví/ký quỹ, biểu đồ cơ cấu thu nhập, portfolio URL, chat text,
lightbox/bộ lọc/KPI Admin. Các phần này được mở rộng, không tạo dữ liệu giả.

## Thứ tự checkpoint

- [x] Tự động migration: baseline dữ liệu cũ, migrate trước JPA validate, kiểm chứng PostgreSQL.
- [x] Lịch công trình, thương lượng lương, cam kết có phiên bản và khóa giao dịch chống trùng lịch.
- [x] Bản đồ ghim lương, 2km, sửa vị trí, chỉ đường, link/QR công trình; lưu việc/thợ quen.
- [ ] Tổ đội có mời/xác nhận thành viên và xác nhận công trình; duyệt nguyên nhóm an toàn.
- [ ] Chấm công GPS/QR, ảnh cuối ngày, nghiệm thu và kiểm tra ngày công khi thanh toán.
- [ ] VietQR nội bộ, ngân hàng do Admin cấu hình, mã đối soát và snapshot tài khoản nhận.
- [ ] SOS/sự cố/tranh chấp, cảnh báo Admin ưu tiên, lịch sử xử lý.
- [ ] Ảnh portfolio từ thiết bị, chat ảnh/GPS, hộp thư và số tin chưa đọc thật.
- [ ] Thời tiết Open-Meteo, cache và trạng thái mất kết nối.
- [ ] Sáng/Tối/Outdoor, hoàn thiện các màn hình Flutter và công cụ Admin.
- [ ] Toàn bộ test, build Web/APK, kiểm tra UI, migration lặp an toàn và push cuối.

Mỗi nhóm chỉ đánh dấu xong sau khi code thực thi, kiểm thử/build và push thành công.

## Quy tắc được người dùng xác nhận

- Admin cấu hình ngân hàng trước khi bật VietQR. Không dùng tài khoản nhận mẫu.
- GPS trong 200m; mã ca làm QR hết hạn sau 5 phút.
- Ngày công theo Asia/Ho_Chi_Minh, không lấy ngày từ thiết bị làm căn cứ duy nhất.
- Công trình có ngày bắt đầu/kết thúc; chặn lịch giao nhau khi duyệt dưới khóa worker.
- Tổ đội gồm tài khoản thợ thực, được mời và xác nhận; chấm công/đánh giá riêng từng người.

## Ràng buộc dữ liệu và giao dịch

1. Flyway baseline 11 cho database cũ chưa có lịch sử. Database mới chạy schema
   nền không seed người dùng; migration mới dùng số phiên bản từ 12, không sửa migration đã phát hành.
2. Công trình cũ không có khoảng ngày giữ dữ liệu gốc. Công trình tạo trên UI mới
   có khoảng ngày; thay đổi điều khoản tăng phiên bản, thợ phải xác nhận lại trước duyệt.
3. Lương đề xuất là lựa chọn; chủ thầu nhận mức đề xuất hoặc giá gốc. Lương đã
   chốt được lưu riêng theo đơn, thanh toán không lấy giá mới từ công trình.
4. Cam kết lưu nội dung, phiên bản và thời điểm xác nhận. Không hiển thị đã xác nhận
   thay người dùng. Dữ liệu cũ được phân biệt với xác nhận được ghi nhận từ UI mới.
5. Khóa job trước, khóa workers theo ID, sau đó mới khóa ví; các luồng dùng cùng thứ tự.
6. Duyệt tổ đội kiểm tra đủ chỗ/lịch/đồng ý của toàn bộ thành viên; lỗi một người rollback cả nhóm.
7. Check-in/out không được ghi trùng cho cùng đơn/ngày. Check-out cần check-in;
   QR chỉ dùng cho đúng công trình, đúng phiên và còn hạn. GPS/QR là dữ liệu ghi nhận,
   GPS thiết bị không được coi là bằng chứng chống giả mạo tuyệt đối.
8. Ảnh cuối ngày chờ chủ thầu nghiệm thu. Với đơn có dữ liệu chấm công, ngày chi trả
   phải khớp số ngày có check-out và nghiệm thu; không tự động chuyển tiền.
9. Tệp ảnh lưu trong PostgreSQL, bỏ metadata và giới hạn kích thước. Mỗi ảnh có quyền
   đọc theo chủ sở hữu/công trình/cặp chat; không đưa JWT vào URL ảnh hoặc QR chia sẻ.
10. QR nạp tiền chứa số tiền và mã tham chiếu của yêu cầu, chụp snapshot ngân hàng nhận;
    QR không đồng nghĩa đã thanh toán. Admin vẫn đối soát và chống mã giao dịch trùng.
11. SOS được lưu và đẩy cảnh báo Admin, có trạng thái/xử lý/audit. Không tự gọi hoặc
    nhắn đến số điện thoại bên ngoài hệ thống.
12. Badge tin nhắn tính từ cursor đọc thực tế. Chat text và clientMessageId cũ vẫn tương thích.
13. Thời tiết làm tròn tọa độ khu vực, cache có giới hạn, có attribution; lỗi provider không chặn tìm việc.

## Kiểm chứng

Maven verify, Flutter analyze/test/build web, PostgreSQL fresh + upgrade + migrate
lần hai, luồng quyền sở hữu/khóa tài khoản/đua giao dịch, asset ACL, QR sai/hết hạn,
lịch trùng, lương chốt, nhóm thợ, day-count khi chi trả và công tắc theme lưu lại.
Ảnh QA chỉ dùng fixture riêng; không ghi tài khoản demo vào database production.

## Checkpoint lịch, lương và cam kết

- API công trình hỗ trợ `startsOn`, `endsOn`, `termsVersion`; chủ thầu sửa công trình
  còn OPEN/chưa nhận thợ bằng `PUT /api/jobs/{id}`. Thay đổi tăng phiên bản,
  gửi thông báo và yêu cầu thợ đọc lại cam kết.
- `GET /api/jobs/{id}/terms` và `GET/PUT /api/applications/{id}/commitment`
  cung cấp nội dung/xác nhận. Admin có trang `/admin/jobs/{id}/commitments`.
- Khi ứng tuyển gửi `proposedDailyRate`, `wageNote`, `acceptedTerms`, `termsVersion`.
  Khi duyệt gửi `acceptCounterOffer`, `acceptedTerms`, `termsVersion`. Mặc định
  giữ giá gốc; lương chốt và snapshot SHA-256 không sửa sau khi duyệt.
- `GET/POST /api/users/me/calendar`, `DELETE /api/users/me/calendar/{id}` quản lý
  lịch riêng của thợ. Khóa worker ngăn hai chủ thầu duyệt trùng ngày đồng thời.
- Flutter có chọn ngày công trình, hộp cam kết, đề xuất lương, màn hình lịch/ngày
  bận và tính tiền theo lương đã chốt. Công trình legacy thiếu ngày vẫn tương thích;
  không tạo xác nhận giả cho các đơn cũ.
- Kiểm chứng: PostgreSQL fresh/upgrade/repeat, production profile health UP/JPA
  validate, giao dịch duyệt đồng thời và thanh toán idempotent; kiểm thử Flutter
  cam kết, lịch, tiền xem trước. Không thay đổi database production trong QA.

## Checkpoint bản đồ và mục đã lưu

- Ghim bản đồ hiển thị lương/ngày, chạm mở tóm tắt và ứng tuyển; thêm bán kính 2km
  vào các lựa chọn Haversine hiện có. OSM attribution và test tile trong bộ nhớ giữ nguyên.
- Chủ thầu bấm **Sửa công trình**, chỉnh nội dung/lịch và ghim bản đồ. Backend vẫn
  chặn sửa sau khi nhận thợ; thay điều khoản yêu cầu xác nhận lại như V12.
- Chi tiết có **Chỉ đường** mở Google Maps URL (không cần API key), **Chia sẻ** tạo
  QR cục bộ và sao chép `https://thoxay.vercel.app/?job={id}`. Link mở đúng công
  trình sau đăng nhập trên Web; không chứa JWT/điện thoại. APK có nút chia sẻ cùng link Web.
- Hồ sơ có **Công trình yêu thích** cho thợ / **Thợ quen** cho chủ thầu. Lưu/bỏ lưu
  nằm trong chi tiết công trình/hồ sơ thợ. Tối đa 300 mục/tài khoản; PUT và DELETE
  idempotent, ẩn tài khoản bị khóa, không mở quyền liên hệ khi chỉ lưu mục.
- API: `GET /api/users/me/saved/jobs|workers`, `PUT/DELETE
  /api/users/me/saved/jobs/{id}`, `PUT/DELETE /api/users/me/saved/workers/{id}`.
- Migration V13 chỉ thêm `saved_jobs`, `saved_workers`; FK cascade dọn bookmark
  khi xóa đối tượng. Không sửa V1/V12 đã phát hành.
- Kiểm chứng checkpoint: 81 test Backend, 66 test Flutter, analyze không lỗi,
  JAR/Web release build thành công, production-profile QA health UP sau V13.

Tài liệu tích hợp: [qr_flutter](https://pub.dev/documentation/qr_flutter/latest/),
[Google Maps URLs](https://developers.google.com/maps/documentation/urls/get-started).
