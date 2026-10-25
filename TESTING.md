# Kiểm thử và nghiệm thu

## Backend

```powershell
.\mvnw.cmd -B verify
```

30 kiểm thử JUnit/Spring Boot dùng H2 mặc định, chạy với Spring Security và JWT
thật: đăng ký/đăng nhập, BCrypt, chống đăng ký ADMIN, token giả/thiếu, tài khoản
bị khóa, phân quyền, Haversine, dữ liệu sai, ứng tuyển trùng, lịch sử, duyệt,
hai giao dịch duyệt đồng thời cho một vị trí, render Thymeleaf, CSRF, xác thực
CCCD, khóa/mở tài khoản và xóa công trình có đơn ứng tuyển.

Nâng cấp bao phủ cập nhật CCCD/đưa về chưa xác thực, chặn duyệt ảnh cũ,
đánh giá sai điểm/sai người/sai chủ công trình, tính trung bình qua nhiều
công trình, gửi lại yêu cầu hoàn thành, hoàn thành hai công trình đồng thời
cho cùng thợ, tính lại điểm khi xóa và bộ lọc loại việc/lương.
KYC hai mặt kiểm tra các vai trò kể cả Admin, mặc định chưa xác thực khi insert
SQL, CHECK chống verified=true với ảnh thiếu, cập nhật thiếu/HTTP bị từ chối
nguyên tử, ảnh đổi làm mất xác thực và chống duyệt snapshot cũ của từng mặt.

Để chạy cùng bộ kiểm thử trên PostgreSQL, dùng **database kiểm thử riêng**.
Hibernate `create-drop` và các thao tác dọn dữ liệu trong test sẽ xóa dữ liệu
database được chỉ định. Ví dụ tạo database mới:

```powershell
createdb -U postgres tho_xay_test
.\mvnw.cmd -B verify `
  '-Dspring.datasource.url=jdbc:postgresql://localhost:5432/tho_xay_test' `
  '-Dspring.datasource.username=postgres' `
  '-Dspring.datasource.password=postgres' `
  '-Dspring.test.database.replace=NONE'
```

## Flutter

```powershell
cd mobile_app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

26 kiểm thử Dart/widget: lưu/khôi phục phiên, đính JWT, xóa phiên khi 401,
validation đăng nhập/đăng ký, tìm việc theo vị trí được cấp cho test, ứng tuyển
và lịch sử, duyệt thợ, validation form đăng công trình. Widget test dùng API
và vị trí giả lập, không truy cập GPS thật hay gửi yêu cầu ra mạng.
Nâng cấp kiểm tra thêm ACCOUNT_LOCKED 403, bộ lọc, liên hệ sau ACCEPTED,
URI tel qua launcher giả, cập nhật CCCD và chọn điểm trước khi hoàn thành.
Ba kiểm thử bản đồ dùng MemoryTiles: bắt buộc chọn vị trí trước khi xác nhận,
trả đúng tọa độ đã chọn, chọn đúng công trình qua ghim và cập nhật camera/ghim
khi kết quả tìm kiếm thay đổi. Không gọi tile OpenStreetMap trong test.
KYC kiểm tra nhãn hai ô ảnh, bắt buộc mặt sau, giữ mặt trước đã có và gửi đúng
hai khóa cccdFrontImage/cccdBackImage tới REST API.

## Nhắn tin realtime

`ChatApiTest` dùng cả MockMvc và WebSocket thật tới Tomcat cổng ngẫu nhiên:
gửi hai chiều, giới hạn nội dung, gửi lại không trùng, phân trang/cursor, lịch sử
riêng theo job và cặp người dùng, chặn pending/rejected/admin/người ngoài,
phát tin tới đúng hai kết nối sau commit, chặn JWT sai, khóa tài khoản đang
online, và cascade tin nhắn khi admin xóa job. Cùng bộ test chạy trên H2 và
PostgreSQL bằng lệnh verify ở trên.

Flutter kiểm tra wire format của API, nút chat chỉ hiện ở đơn ACCEPTED, tin
realtime đến trong lúc tải lịch sử, khử trùng, tải bù nhiều trang sau ngắt mạng
kể cả khi ID lớn đã đến trước, tải tin cũ, giữ bản nháp/gửi lại cùng mã khi mất
phản hồi, lỗi quyền và dọn kết nối lúc đóng màn hình/đăng xuất.

Checkpoint chat đã chạy `mvnw verify` thành công với 30 test trên H2 và
PostgreSQL, analyzer không lỗi, 26 test Flutter và Web release build thành công.
Đã kiểm tra thêm chính Flutter HTTP/WebSocket client với Backend JAR và
PostgreSQL đang chạy: đăng ký hai tài khoản tạm, đăng việc/ứng tuyển/duyệt,
gửi hai chiều realtime, gửi lại cùng mã và đọc lại đúng hai tin đã lưu. Migration
004 chạy lại thành công; công trình, tin nhắn và hai tài khoản thử đã được dọn.

Nghiệm thu: dùng hai tài khoản Thầu–Thợ, đăng việc → ứng tuyển → duyệt, mở Chat
ở hai thiết bị và gửi tin qua lại không tải lại trang. Ngắt mạng một thiết bị,
gửi thêm tin từ thiết bị kia, bật lại mạng và kiểm tra tin được tải bù đúng thứ
tự. Khóa một tài khoản trong Admin và kiểm tra socket bị đóng, không gửi được
tin mới. Đóng/mở lại Chat để xác nhận lịch sử đã được lưu.

## Modal Admin

```powershell
node --check src/main/resources/static/js/admin-kyc.js
node --test scripts/tests/admin-kyc.test.cjs
```

4 kiểm thử sự kiện DOM: chỉ duyệt sau khi hai ảnh tải xong, chặn ảnh thiếu/lỗi,
bỏ qua callback ảnh của tài khoản trước, xóa URL khi đóng và chặn gửi lặp.
Modal Bootstrap còn được kiểm tra trực tiếp trên trình duyệt.

Đã kiểm chứng trên Windows, Java 21, Flutter 3.47.8: Maven verify với cả 23 test
trên H2 và PostgreSQL 17.11, Flutter analyzer, 18 test và Web release build.
Schema/seed PostgreSQL mới xác nhận mọi tài khoản mẫu đều chưa xác thực.
Fixture schema legacy xác nhận migration giữ ảnh cũ, hạ xác thực khi thiếu mặt
sau và chạy lại không thay đổi hồ sơ đã được duyệt đủ hai mặt.
Đã kiểm tra trên Chrome: popup hiển thị hai ảnh DEMO song song, duyệt ngay
trong modal thành công, đổi mặt sau qua API đưa verified về false, và popup
của seed Admin không có ảnh giữ nút duyệt bị vô hiệu hóa. Flutter hiển thị
đúng hai trường mặt trước/mặt sau. Tài khoản DEMO đã được xóa sau kiểm tra.
Schema/seed và luồng HTTP đăng nhập →
Haversine → đăng việc → ứng tuyển → nhận thợ → IN_PROGRESS đã chạy trên
PostgreSQL 17.11 thật. Web Admin và Flutter đã được đăng nhập trên Chrome,
kiểm tra dashboard quản trị và danh sách công trình/ứng viên của chủ thầu.
Nâng cấp đã kiểm chứng nền OpenStreetMap tải trên Chrome, chạm đặt ghim và
trả tọa độ về form đăng công trình. Luồng HTTP cập nhật CCCD → nhận thợ →
hoàn thành → điểm trung bình đã chạy trên database local bằng tài khoản tạm,
và dữ liệu kiểm thử đã được dọn sau khi xác nhận.
APK chưa build vì máy kiểm chứng chưa có Android SDK; iOS chưa build vì cần macOS/Xcode.

## Nghiệm thu thủ công

1. Khởi động PostgreSQL, backend và Flutter theo README; đăng nhập tài khoản thầu mẫu.
2. Đăng công trình cần 1 thợ, lương 500000, loại Thợ chính, vị trí `10.7769,106.7009`.
3. Đăng xuất, đăng ký thợ mới. Nếu muốn kiểm tra CCCD, nhập URL HTTPS ảnh thử
   nghiệm mặt trước và mặt sau thuộc quyền sử dụng của bạn; có thể bổ sung cả
   hai trong Hồ sơ & CCCD. Không dùng giấy tờ cá nhân thật cho demo.
4. Lấy GPS hoặc chọn vị trí mẫu, bán kính 10 km; mở chi tiết và bấm Nhận việc.
5. Kiểm tra đơn Chờ duyệt trong lịch sử; thao tác lặp không tạo đơn thứ hai.
6. Đăng nhập thầu, mở Xem & duyệt thợ, bấm Nhận thợ. Công trình chuyển Đang thi công.
7. Đăng nhập lại thợ, làm mới lịch sử để thấy Đã nhận. Công trình đủ thợ biến mất
   khỏi danh sách tìm việc OPEN.
8. Vào Web Admin, bấm Xem CCCD, kiểm tra hai ảnh trong popup và Xác thực danh tính.
   Thiếu một ảnh hoặc ảnh tải lỗi phải không duyệt được. Khóa thợ và kiểm tra
   đăng nhập/JWT bị chặn; mở khóa và thử lại.
9. Đăng công trình thử khác, xóa bằng Admin; xác nhận công trình và đơn liên quan
   không còn trong danh sách sau khi làm mới.

## Kiểm chứng lỗi khởi động PowerShell

Lỗi `Process terminated with exit code: 1` đã được tái hiện bằng
`.\mvnw.cmd spring-boot:run`: PostgreSQL mặc định `localhost:5432` từ chối kết nối.
Sau khi kết nối đúng PostgreSQL local ở cổng 55432, lỗi tiếp theo là thiếu
`JWT_SECRET`. Cổng 8080 trống tại thời điểm chẩn đoán.

Script `scripts/start-local.ps1 -WithFrontend` chuẩn bị cấu hình riêng trong
`.local/`, bật PostgreSQL portable nếu có, build/test và chờ cả backend cùng
frontend trả HTTP 200. Biến môi trường vẫn có thể thay thế các giá trị local.
`scripts/stop-local.ps1` kiểm tra đường dẫn command line trước khi dừng đúng
tiến trình của workspace; giữ PostgreSQL chạy để sử dụng Maven trực tiếp.

Sau sửa, chính lệnh `.\mvnw.cmd spring-boot:run` đã khởi động Tomcat cổng 8080
và trả HTTP 200 tại `/admin/login`. Đã kiểm tra cả khởi động lại sau khi tắt
PostgreSQL, nạp lại cấu hình/khóa JWT đã lưu, đăng nhập tài khoản demo và hai
giao diện HTTP 200. Cơ chế chờ frontend dùng loopback IPv4 để tránh việc
`localhost` trỏ IPv6 trong khi server Web chỉ lắng nghe IPv4.

## Checkpoint Git

Mỗi bước và mỗi màn hình có commit riêng trên `main`, chỉ chuyển bước sau khi
build và push thành công. Xem `git log --oneline` để chọn điểm khôi phục. Dùng
`git revert <commit>` khi cần đảo một thay đổi đã chia sẻ, rồi build và push
checkpoint mới theo AGENTS.md.
