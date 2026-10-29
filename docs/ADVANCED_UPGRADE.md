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

- [ ] Tự động migration: baseline dữ liệu cũ, migrate trước JPA validate, kiểm chứng PostgreSQL.
- [ ] Lịch công trình, thương lượng lương, cam kết có phiên bản và khóa giao dịch chống trùng lịch.
- [ ] Bản đồ ghim lương, 2km, sửa vị trí, chỉ đường, link/QR công trình; lưu việc/thợ quen.
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
