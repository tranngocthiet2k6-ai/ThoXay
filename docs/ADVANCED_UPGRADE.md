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
- [x] Tổ đội có mời/xác nhận thành viên và xác nhận công trình; duyệt nguyên nhóm an toàn.
- [x] Chấm công GPS/QR, ảnh cuối ngày, nghiệm thu và kiểm tra ngày công khi thanh toán.
- [x] VietQR nội bộ, ngân hàng do Admin cấu hình, mã đối soát và snapshot tài khoản nhận.
- [x] SOS/sự cố/tranh chấp, cảnh báo Admin ưu tiên, lịch sử xử lý.
- [x] Ảnh portfolio từ thiết bị, kiểm tra ảnh và lưu bền vững.
- [x] Chat ảnh/GPS, hộp thư và số tin chưa đọc thật.
- [x] Thời tiết Open-Meteo, cache và trạng thái mất kết nối.
- [x] Sáng/Tối/Outdoor, hoàn thiện các màn hình Flutter và công cụ Admin.
- [ ] Biểu đồ thu nhập theo ngày từ dữ liệu thanh toán thật, theo kỳ Ngày/Tuần/Tháng.
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

## Checkpoint tuyển tổ đội

- Thợ tạo tổ (tối đa 10 tổ/tổ trưởng), mời tài khoản thợ bằng số điện thoại.
  Người được mời tự xác nhận/từ chối; tổ tối đa 20 thành viên. Lời mời chưa đồng ý
  không được tính vào số thợ ứng tuyển. Roster không trả số điện thoại.
- Tổ trưởng chọn công trình có lịch và xem cam kết trước khi gửi tổ. Backend tạo
  một đơn riêng cho mỗi thành viên đã tham gia; chỉ ghi đồng ý của tổ trưởng.
  Mỗi người còn lại phải mở Đã ứng tuyển để tự xác nhận điều khoản công trình.
- Chủ thầu bấm Nhận/Từ chối toàn tổ, xem danh sách người trước khi xác nhận.
  Khóa job trước rồi toàn bộ workers theo ID; kiểm tra số chỗ/lịch/Online/khóa
  tài khoản/phiên bản cam kết. Một người lỗi thì rollback toàn bộ nhóm.
- Trước duyệt, bất kỳ thành viên nào có thể rút cả tổ mà không trừ điểm. Sau duyệt,
  hủy việc/đánh giá/chấm công tiếp tục theo từng tài khoản và quy định hiện hành.
- Admin xem roster và trạng thái đồng ý tại trang Cam kết công trình.
- API: `GET/POST /api/crews`, `POST /api/crews/{id}/invitations`,
  `PUT /api/crews/{id}/membership`, `POST /api/crews/{id}/applications`,
  `PUT /api/crew-applications/{id}/status`, `DELETE
  /api/crew-applications/{id}/participation`, `GET /api/jobs/{id}/crew-applications`.
- V14 thêm crews/crew_members/crew_batches và FK nullable trên đơn ứng tuyển;
  đơn cá nhân cũ giữ nguyên. Test rollback chạy qua các giao dịch request thật,
  không dùng transaction bao quanh test để che lỗi commit/rollback.

## Checkpoint ảnh tay nghề từ thiết bị

- Hồ sơ Thợ/Chủ thầu có chụp ảnh hoặc chọn từ thư viện, xem trước/phóng to,
  nhập chú thích và xác nhận trước tải. Mỗi hồ sơ tối đa 12 ảnh; chủ ảnh xóa sau
  xác nhận. Thợ có bộ ảnh hiển thị trong hồ sơ cho người dùng đã đăng nhập.
- URL portfolio legacy vẫn giữ nguyên, ảnh tải lên được quản lý riêng; không thay
  đổi danh sách URL khi cập nhật họ tên/kỹ năng hoặc gửi CCCD.
- Tệp thực tế phải JPEG/PNG, đầu vào tối đa 5 MB / 16 triệu pixel / 6000px mỗi cạnh.
  Ảnh portfolio được thu nhỏ tối đa 1800px và mã hóa lại JPEG tối đa 2 MB, bỏ EXIF.
  Bộ xử lý dùng chung cho KYC nhưng giữ giới hạn/độ phân giải KYC cũ.
- Ảnh lưu BYTEA trong PostgreSQL, không phụ thuộc ổ đĩa Render. API danh sách
  chỉ query metadata, không kéo toàn bộ ảnh vào bộ nhớ khi mở hồ sơ.
- API: `GET /api/users/{id}/portfolio`, `POST /api/users/me/portfolio` (multipart
  photo/caption), `GET /api/portfolio/photos/{uuid}`, `DELETE
  /api/users/me/portfolio/{uuid}`. Đọc ảnh cần JWT header, no-store, không theo
  redirect; không đặt token trên URL. Hồ sơ chủ thầu chỉ chủ ảnh/Admin xem;
  hồ sơ thợ đang hoạt động xem được bởi người dùng đăng nhập như hồ sơ hiện có.
- Admin bấm Ảnh tay nghề tại bảng tài khoản để xem ảnh/chú thích và modal phóng to
  bằng phiên quản trị. Đóng modal xóa src ảnh. Đây là ảnh nghề, độc lập ảnh CCCD.
- V15 chỉ thêm portfolio_photos, FK owner cascade và giới hạn kích thước BYTEA.
- Kiểm thử gồm ảnh giả/quá lớn/quá nhỏ, loại bỏ metadata thừa, resize, quota,
  JWT/khóa tài khoản, quyền xóa, preview/zoom và đọc ảnh bằng phiên Admin.

## Checkpoint chấm công và ảnh nghiệm thu

- Thợ có nút Chấm công & ảnh cuối ngày tại đơn ACCEPTED; chủ thầu có Chấm công &
  nghiệm thu tại từng công trình. GPS đo từ thiết bị (không dùng tọa độ tìm việc
  nhập tay), trong 200m và sai số không quá 100m; có QR/nhập mã khi GPS không tốt.
- QR tạo cục bộ trong Flutter từ mã ngẫu nhiên 256 bit do chủ thầu yêu cầu. Backend
  chỉ lưu SHA-256, hết hạn sau 5 phút; tạo mã mới làm mã cũ mất hiệu lực. Mã thuộc
  đúng job, không phải JWT. DTO debug che token/GPS. QR vẫn cần mạng để xác nhận.
- Ngày công theo Clock Asia/Ho_Chi_Minh. Mỗi đơn/ngày có một bản ghi; check-in/out
  lặp không tạo trùng, checkout cần check-in và thực hiện trong cùng ngày Việt Nam.
  Không cho chọn ngày thiết bị để tự tạo lịch sử chấm công quá khứ.
- Sau checkout, thợ chụp/chọn ảnh, xem trước/zoom, ghi nội dung cuối ngày và gửi.
  Chủ thầu nghiệm thu hoặc yêu cầu bổ sung (phải có phản hồi). Ảnh/ngày đã duyệt
  không thay đổi; phiên bản optimistic lock chặn duyệt nhầm ảnh vừa bị thay.
  Có thể bổ sung/nghiệm thu ảnh sau COMPLETED khi chưa thanh toán, để không bị
  kẹt hồ sơ nếu chủ thầu đóng công trình trước khi duyệt hết ảnh.
- Công trình tạo mới qua API bật attendanceRequired; thanh toán phải khớp toàn bộ
  ngày checkout/ảnh APPROVED. Công trình cũ giữ false; nếu đã ghi chấm công thì
  cũng phải đối soát đủ. Không tạo ngày công hoặc xác nhận giả cho dữ liệu cũ.
- Chủ thầu vẫn chủ động xác nhận trả tiền; không có chuyển tiền tự động từ ảnh.
  Thanh toán gửi lại cùng nội dung không chi lần hai. Giới hạn ngày thanh toán
  tăng từ 365 lên 366 để khớp lịch một năm bao gồm cả ngày bắt đầu/kết thúc.
- Lịch sử thợ phân trang 60 ngày; chủ thầu/Admin xem theo ngày, 100 người/trang.
  Ảnh lưu PostgreSQL, cần JWT hoặc phiên Admin đúng quyền; outsider nhận 404.
  Admin có trang đọc/đối chiếu và popup ảnh, không nghiệm thu thay chủ thầu.
- API: `GET /api/applications/{id}/attendance?beforeDay=...`, `GET
  /api/jobs/{id}/attendance?day=...&page=0`, `POST
  /api/jobs/{id}/attendance/shift-code`, `POST
  /api/applications/{id}/attendance/check-in|check-out`, `POST
  /api/applications/{id}/work-logs` (photo/day/caption), `PUT
  /api/work-logs/{id}/review` (approved/feedback/version), `GET
  /api/work-logs/{id}/photo`.
- V16 thêm attendance_records, attendance_shift_codes, work_logs và cờ job
  nullable-compatibility bằng default FALSE; mở rộng CHECK ngày thanh toán.
- Kiểm chứng: 98 test Backend, 76 test Flutter pass; analyze, JAR/Web release và
  production-profile QA/Flyway V16/JPA validate thành công. UI có ảnh QA mobile/
  desktop với fixture. Camera quét QR cần kiểm tra thêm trên thiết bị thật.

Tham khảo tích hợp camera QR: [mobile_scanner](https://pub.dev/packages/mobile_scanner).

## Checkpoint nạp tiền VietQR

- Admin vào **Đối soát ví > Ngân hàng nhận tiền VietQR** (`/admin/wallet/bank-settings`),
  nhập BIN 6 chữ số, tên ngân hàng, tài khoản nhận (giữ số 0 đầu, tối đa 19 ký tự
  chữ/số), tên chủ tài khoản, đối chiếu và chọn Bật. Mặc định chưa có cấu hình/bị tắt.
  Tất cả giá trị thử nghiệm chỉ ở test/QA, không seed tài khoản ngân hàng nhận tiền.
- Mỗi lần đổi lưu audit và kiểm tra version, chặn ghi đè cấu hình vừa bị Admin
  khác thay. Tắt cấu hình ngừng tạo QR mới. Yêu cầu đã tạo vẫn giữ thông tin gốc
  để đối soát, kể cả sau đổi/tắt cấu hình.
- Flutter Ví có **Nạp tiền bằng VietQR**, tạo yêu cầu với số tiền và idempotency key.
  Backend sinh nội dung `TX{requestId base36}` duy nhất, snapshot ngân hàng và payload
  NAPAS QRIBFTTA; Flutter vẽ QR bằng qr_flutter. Không cộng số dư khi tạo/xem/quét QR.
- Lịch sử yêu cầu cho xem lại mã, số tiền và ngân hàng snapshot. Yêu cầu đã xử lý
  ẩn QR/chỉ dẫn chuyển tiền. Dòng yêu cầu trong Admin hiển thị nội dung đối soát
  do server sinh và ngân hàng nhận tại lúc tạo.
- Quy trình nạp/rút thủ công hiện có giữ nguyên. Admin vẫn xác nhận tiền thực nhận,
  đúng tài khoản/số tiền/nội dung và nhập mã giao dịch ngân hàng không dùng lại.
  Gửi lại cùng yêu cầu không cộng hai lần; thay số tiền với cùng key bị chặn.
- API: `POST /api/wallet/deposits` (amount/clientRequestId), `GET
  /api/wallet/deposits/{id}` (chỉ chủ yêu cầu hoặc Admin), `GET/PUT
  /api/admin/wallet/bank-settings` (chỉ Admin).
- V17 thêm cấu hình/audit và các cột nullable receiving_bank_bin, deposit_reference,
  qr_payload của wallet_requests. Dữ liệu ví và giao dịch cũ giữ nguyên.
- Kiểm chứng: 104 test Backend, 79 test Flutter; JAR/Web release/analyze pass,
  production-profile QA health UP với V17. Payload mẫu QA được giải mã độc lập
  bằng @viet-qr/core 1.4.0: CRC, BIN/tài khoản, số tiền, nội dung đều khớp. Cần Admin
  nhập ngân hàng thật và thử quét đối chiếu người nhận bằng ứng dụng ngân hàng trước
  khi dùng trong vận hành; tác vụ này chưa cấu hình/chuyển tiền thực tế.

Nguồn định dạng: [VietQR account/BIN](https://www.vietqr.io/qr-dong),
[field definitions của vietqr_core](https://github.com/iamv4g/vietqr.dart/blob/main/packages/vietqr_core/vietqr_field_definitions_en.md).
Tên người nhận được hiển thị để đối chiếu, không phải trường xác minh chủ tài khoản
trong payload chuyển khoản QRIBFTTA.

## Checkpoint SOS, sự cố và tranh chấp

- Thợ đã được nhận (kể cả đã hủy) và chủ công trình có **SOS tới Admin** / **Sự cố,
  tranh chấp**. SOS mở form có nội dung sẵn, chỉ gửi sau khi người dùng bấm xác nhận.
  GPS tùy chọn; có thể bỏ qua/không cấp quyền mà vẫn gửi. Tọa độ công trình được
  giữ riêng với GPS người báo cáo, Admin biết rõ nguồn vị trí.
- Báo cáo riêng tư: chỉ người gửi và Admin đọc được. Chủ thầu không tự xem báo cáo
  của thợ chỉ vì sở hữu công trình. Lịch sử cá nhân ở Hồ sơ > Sự cố đã gửi.
- Gửi lại giữ clientRequestId/nội dung ban đầu để tránh tạo trùng báo cáo, audit
  hoặc thông báo. Chặn người ngoài công trình, không yêu cầu trạng thái Online
  để thợ đang làm vẫn gửi sự cố khi đã tắt nhận việc mới.
- Mọi Admin đang hoạt động nhận thông báo lưu DB/FCM khi đã cấu hình Firebase;
  outbox ưu tiên INCIDENT_SOS. Web Admin có hàng đợi SOS trước, bộ lọc trạng thái/
  loại/từ khóa và badge/cảnh báo kiểm tra mỗi 20 giây khi tab đang hiển thị.
  Mất kết nối giữ số đếm đã xác nhận gần nhất, không tự đổi về 0.
- Admin tiếp nhận/đang xử lý/ghi kết quả. Kiểm tra version chặn ghi đè thao tác của
  Admin khác, ghi audit và thông báo người gửi. Cần kết quả trước khi kết thúc;
  lịch sử đã kết thúc giữ nguyên. Module không tự điều chỉnh giao dịch ví.
- Báo cáo chụp snapshot tên/địa chỉ/vị trí công trình và người gửi, vẫn còn khi gỡ
  công trình. Xử lý dùng khóa job trước incident để không đảo khóa với thao tác gỡ bài.
- API: `POST /api/jobs/{id}/incidents`, `GET /api/incidents/me?jobId=&beforeId=`,
  `GET /api/incidents/{id}`, `GET /api/admin/incidents?status=&type=&q=&page=`,
  `PUT /api/admin/incidents/{id}` (status/note/version). Web `/admin/incidents`,
  `/admin/incidents/{id}`, `/admin/incidents/counts` dùng phiên Admin/CSRF.
- V18 thêm incidents/incident_audit với FK job/reporter SET NULL để giữ lịch sử.
- Kiểm chứng: 110 test Backend và 82 test Flutter pass; 12 test JS/triển khai pass;
  JAR/Web release/analyze, Flyway V18/JPA validate/health UP trên QA. Chrome QA đã
  thực hiện đăng nhập Admin, xem SOS và cập nhật qua CSRF trên DB QA riêng, sau đó
  xóa đúng dữ liệu giả của lượt kiểm tra. Chưa phát thông báo tới tài khoản thật.

## Checkpoint ảnh và GPS trong chat

- Giữ endpoint chat text/clientMessageId cũ, thêm `POST /api/jobs/{id}/messages/photo`
  (multipart photo/recipientId/caption/clientMessageId) và `/messages/location`
  (recipientId/clientMessageId/latitude/longitude). Lịch sử/WebSocket thêm kind,
  imagePath hoặc tọa độ; content vẫn có tóm tắt để tương thích client cũ.
- Ảnh JPEG/PNG tối đa 5 MB đầu vào, kiểm tra điểm ảnh, đổi thành JPEG bỏ EXIF,
  thu cạnh dài tối đa 1800px và lưu tối đa 2 MB trong PostgreSQL. Tệp gắn trực tiếp
  với tin nhắn trong cùng giao dịch, xóa theo công trình/tin nhắn, không tạo tệp mồ côi.
- `GET /api/jobs/{id}/messages/{messageId}/photo` dùng JWT/no-store. Chỉ cặp chat
  đã được duyệt đọc được; Admin hoặc thợ khác cùng công trình không được đọc ảnh.
  Khi khóa tài khoản/hủy tham gia, quyền chat/ảnh bị thu hồi như chat text.
- Flutter chọn camera/thư viện hoặc GPS, xem trước rồi xác nhận. Không tự gửi khi
  cấp quyền hoặc chọn ảnh; GPS bị từ chối không tạo tin. Chạm ảnh phóng to, chạm
  vị trí mở chỉ đường. Khung chat desktop giới hạn 960px.
- Gửi lại giữ nguyên mã, ảnh/tọa độ/chú thích; backend so sánh loại/nội dung/hash
  ảnh đã xử lý, trả lại tin cũ khi trùng và 409 khi mã được dùng cho nội dung khác.
- V19 thêm payload nullable cho messages và message_attachments. Chat cũ mặc định
  TEXT, giữ nguyên nội dung và thời điểm; kiểm thử nâng cấp có tin nhắn legacy.
- Kiểm chứng: 112 test Backend (gồm PostgreSQL migration), 85 test Flutter pass;
  analyze không lỗi và JAR/Web release build thành công. Hộp thư/số chưa đọc là
  checkpoint kế tiếp, chưa đánh dấu hoàn tất nhóm chat tổng thể.

## Checkpoint hộp thư và tin chưa đọc

- `GET /api/messages/inbox?beforeId=` trả tối đa 30 cuộc trò chuyện theo tin mới
  nhất, kèm công trình, tên người trao đổi, tóm tắt và số tin chưa đọc. Không trả
  điện thoại trong metadata hộp thư. Chỉ cặp ACCEPTED/tài khoản hoạt động được tính.
- `GET /api/messages/unread` đếm tin gửi đến sau con trỏ đọc của chính tài khoản.
  Badge thông báo và badge chat dùng hai nguồn độc lập. REST polling mỗi 20 giây
  khi app/tab đang hiển thị; chat mở vẫn nhận tin trực tiếp qua WebSocket.
- `PUT /api/jobs/{id}/messages/read` nhận peerId/lastReadMessageId. Con trỏ phải là
  tin thực thuộc đúng cặp và công trình; không chấp nhận ID tương lai hoặc tin của
  người/công trình khác. Khóa job và cập nhật max bảo đảm không lùi khi nhiều thiết
  bị ghi nhận đọc. V20 tạo chat_read_states, không sửa nội dung/lịch sử chat cũ.
- Flutter chỉ xác nhận đọc khi màn hình chat đang hiện, app foreground và ở cuối
  danh sách. Cuộn xem tin cũ không tự đọc tin vừa đến. Hộp thư có empty state/CTA,
  skeleton, kéo làm mới, phân trang và giữ dữ liệu đã thấy khi mất mạng.
- Navigation thêm Tin nhắn với badge thực; màn hình nhỏ chỉ hiện nhãn mục đang
  chọn để sáu biểu tượng không chen chúc, desktop hiện đầy đủ nhãn.
- Kiểm chứng: 114 test Backend, 89 test Flutter pass; analyze/JAR/Web release pass.
  PostgreSQL QA kiểm thử cả truy vấn SQL và REST production profile: V20 migrate,
  projection hộp thư, quyền metadata và con trỏ/số chưa đọc chính xác. Fixture tạm
  đã xóa, không tạo tài khoản/tin nhắn trên production.

## Checkpoint thời tiết khu vực công trình

- `GET /api/weather?latitude=&longitude=` yêu cầu JWT, kiểm tra tọa độ hữu hạn và
  phạm vi. Backend làm tròn 2 chữ số thập phân trước khi gọi host HTTPS cố định
  Open-Meteo, không gửi JWT hoặc GPS chính xác của người dùng tới provider.
- Dữ liệu hiện tại gồm nhiệt độ/cảm giác, mã thời tiết, mưa, gió, ngày/đêm và thời
  điểm. Flutter có nhãn/thông tin gợi ý theo điều kiện, kể cả mã dông 97; không
  xem dữ liệu mô hình là kết luận an toàn thay thế quan sát công trường.
- Cache LRU tối đa 128 khu vực/15 phút; gộp yêu cầu cùng khu vực, tối đa 8 lượt gọi
  provider đồng thời. Kết nối 2 giây/request 3 giây; lỗi được cache 30 giây. Dữ liệu
  trước đó còn dưới 3 giờ được đánh dấu stale, quá hạn trả unavailable/current=null.
  Không mở giao dịch DB khi gọi dịch vụ thời tiết.
- Thợ xem khu vực GPS/vị trí đang tìm việc; chủ thầu chọn công trình cần xem, mặc
  định ưu tiên công trình đang tuyển/đang làm. API thời tiết độc lập nên không cản
  tải công trình. Có skeleton, thử lại, ngày giờ dữ liệu, mở rộng chi tiết và link
  attribution Open-Meteo/CC BY 4.0. Dùng dịch vụ miễn phí cho phạm vi đồ án phi thương mại.
- Kiểm chứng: 122 test Backend, 92 test Flutter pass; analyze/JAR/Web release pass.
  REST QA production profile đã nhận dữ liệu provider thật tại khu vực công khai,
  đồng thời xác nhận các module chat/V20 vẫn hoạt động. Đã xóa fixture QA tạm.

Tham khảo thông số và mã WMO: [Open-Meteo Forecast API](https://open-meteo.com/en/docs).

## Checkpoint Sáng/Tối/Outdoor

- AppPalette cung cấp màu nền/chữ/viền/trạng thái theo mode. Màu nhấn vai trò giữ
  nguyên #EA580C/#059669; các card, chat, ví, hồ sơ, bộ lọc, KYC, skeleton và bảng
  xếp hạng lấy màu ngữ nghĩa. Các nền QR/ảnh và chữ trắng trên card thương hiệu
  được giữ phù hợp với nội dung, không đảo màu toàn bộ cây widget.
- Nút chọn giao diện ở Auth/trang chủ/Hồ sơ. Lựa chọn lưu trên thiết bị, phục hồi
  trước khung hình đầu; thay đổi áp dụng cả route đang mở, không đăng xuất.
  Ghi preference nối tiếp để thao tác chọn nhanh vẫn giữ lựa chọn cuối cùng.
- Outdoor: nền trắng/chữ đen, chữ phụ đậm, body 16px, viền 2px và nút đen/trắng
  tối thiểu 48px; bớt gradient/shadow trang trí trên card sáng. Card dùng radius16.
- Kiểm thử tự động kiểm tra tương phản chữ chính >=7:1, chữ phụ/trạng thái >=4.5:1,
  màu vai trò, nhãn chip/navigation và phục hồi/chuyển mode trên route đang mở.
- 95 test Flutter pass, analyze sạch, Web release build thành công. Chrome QA dùng
  API chặn/mô phỏng cục bộ: 390/1440px, Thợ/Chủ thầu, Sáng/Tối/Outdoor, các trang
  chủ/ví/hồ sơ/hộp thư/thông báo; đã xem ảnh và sửa nhãn bộ lọc/chú thích ví thiếu
  tương phản rồi chạy lại. Không gửi fixture hoặc thao tác tới production.
  Backend không đổi trong checkpoint này; 122 test/JAR đã pass ở nhóm thời tiết.
