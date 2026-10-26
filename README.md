# Thợ Xây

Đồ án **Ứng dụng Di động Kết nối Lao động Phổ thông & Chủ thầu**.

Backend Java 17+ / Spring Boot 3.5, PostgreSQL, JPA, Spring Security, JWT,
BCrypt và Validation. Web quản trị dùng Thymeleaf / Bootstrap 5. Ứng dụng
Flutter có giao diện tiếng Việt cho thợ và chủ thầu, chạy trên Android, iOS và Web.

## Khởi chạy nhanh trên PowerShell

Từ thư mục gốc của dự án:

```powershell
.\scripts\start-local.ps1 -WithFrontend -OpenBrowser
```

Lệnh này build/test backend, build Flutter Web rồi chạy cả hai ở chế độ nền:

- Web Admin: `http://localhost:8080/admin/login`.
- Giao diện thợ/chủ thầu: `http://localhost:3000`.
- Log khởi động: `.local/backend.log`, `.local/backend-error.log`, `.local/frontend-error.log`.

Script dùng Flutter trong `.tools/flutter` nếu có, hoặc Flutter trong PATH;
Node.js dùng để phục vụ bản Web đã build. Nếu PostgreSQL mặc định ở cổng 5432
chưa chạy, script có thể bật bản portable đã được chuẩn bị trong workspace
(`.tools/postgres`, `.tools/pgdata`) ở cổng **55432**, giữ nguyên dữ liệu hiện có.
Fresh clone chưa có các công cụ này cần cài Flutter/Node và chuẩn bị PostgreSQL
theo phần dưới. `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` vẫn được ưu tiên khi đặt.

Lần đầu, script tạo `.local/application.properties` chứa địa chỉ database local
và khóa JWT ngẫu nhiên. Spring Boot nạp tệp này khi chạy từ thư mục gốc; thư mục
`.local/` bị loại khỏi Git. Khóa được giữ lại qua các lần khởi động.

Sau khi đã build và chưa sửa mã nguồn, khởi động nhanh bằng:

```powershell
.\scripts\start-local.ps1 -WithFrontend -SkipBuild -OpenBrowser
```

Dừng backend và frontend do script quản lý:

```powershell
.\scripts\stop-local.ps1
```

PostgreSQL vẫn chạy để có thể chuyển sang lệnh Maven ở chế độ phát triển:

```powershell
.\mvnw.cmd spring-boot:run
```

Chạy lệnh Maven sau khi đã dừng backend đang chiếm cổng 8080. Cần gõ `mvnw.cmd`
với tiền tố `.\` trên PowerShell. Sau khi khởi động lại Windows, chạy script
khởi động trước để bật lại PostgreSQL portable.

## Chuẩn bị PostgreSQL và chạy riêng backend

Cần JDK 17 trở lên; Maven Wrapper đã có trong repository. Dùng PostgreSQL
có sẵn hoặc Docker Desktop:

```powershell
docker compose up -d db
.\scripts\start-local.ps1
```

Compose tạo database `tho_xay_db`, các bảng và dữ liệu demo từ [schema.sql](schema.sql).
Chỉ nạp script tự động khi volume database được khởi tạo lần đầu. Với PostgreSQL
cài riêng, tạo database rồi nạp:

```powershell
createdb -U postgres tho_xay_db
psql -U postgres -d tho_xay_db -v ON_ERROR_STOP=1 -f schema.sql
.\scripts\start-local.ps1
```

API: `http://localhost:8080/api`. Web quản trị:
`http://localhost:8080/admin/login`.

Script khởi động chạy `mvnw verify` trước khi chạy JAR. Có thể đặt `JWT_SECRET`
bằng khóa Base64 riêng (ít nhất 32 byte ngẫu nhiên) để thay khóa local.
[`.env.example`](.env.example) liệt kê các biến; Spring Boot đọc biến môi trường
của tiến trình và `.local/application.properties`, không tự nạp tệp `.env`.

Chạy thủ công trên PowerShell:

```powershell
$jwtBytes = New-Object byte[] 48
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($jwtBytes)
$env:JWT_SECRET = [Convert]::ToBase64String($jwtBytes)
$env:DB_URL = 'jdbc:postgresql://localhost:5432/tho_xay_db'
$env:DB_USERNAME = 'postgres'
$env:DB_PASSWORD = 'postgres'
.\mvnw.cmd verify
java -jar target/tho-xay-1.0.0.jar
```

Trên Linux/macOS dùng `bash ./mvnw verify`, export các biến tương ứng rồi chạy JAR.
Mặc định Hibernate dùng `update`; DDL ràng buộc và seed được quản lý trong
`schema.sql`, không chạy lại mỗi lần khởi động ứng dụng.

## Tài khoản demo

Các tài khoản sau chỉ có khi đã nạp `schema.sql`. Mật khẩu chung: `password`.
Hash BCrypt được kiểm thử đối chiếu với mật khẩu này.

| Vai trò | Số điện thoại | Giao diện |
| --- | --- | --- |
| Quản trị | 0900000001 | Web Admin |
| Chủ thầu | 0900000002 | Flutter: công trình, đăng việc, duyệt thợ |
| Thợ | 0900000003 | Flutter: tìm GPS, nhận việc, lịch sử |

Công trình mẫu ở `10.7769, 106.7009` (Quận 1, TP.HCM). Thợ mẫu đã có một
đơn PENDING. Có thể đăng ký thợ mới để kiểm tra luồng ứng tuyển từ đầu.

## Chạy Flutter

Dùng Flutter stable **3.47.8** (phiên bản đã kiểm chứng), có trong
[kho SDK chính thức](https://docs.flutter.dev/install/archive).

```powershell
cd mobile_app
flutter pub get
flutter run -d chrome --web-port=3000
```

API mặc định của Flutter và APK từ GitHub Actions là `http://192.168.1.16:8080`.
Các endpoint đã có tiền tố `/api`, nên không thêm `/api` vào Base URL.
Điện thoại cần cùng mạng LAN với máy backend và truy cập được cổng 8080.
Có thể thay địa chỉ lúc chạy hoặc build:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

Thay URL minh họa bằng API đang chạy của bạn. Android cho phép HTTP tới riêng
`192.168.1.16` trong `network_security_config.xml`. Android cần Android SDK và thiết bị/emulator.
iOS cần macOS, Xcode và cấu hình ký ứng dụng. Android release trong repo dùng
debug key để demo; cấu hình upload key riêng khi phát hành Play Store.

Quyền GPS đã khai báo trong AndroidManifest và Info.plist. Trên Web dùng
localhost hoặc HTTPS và cho phép vị trí. Khi GPS không khả dụng, nút chọn vị trí
cho phép nhập tọa độ thực tế để tiếp tục tìm/đăng công trình. Có thể nhập tọa độ
công trình mẫu để kiểm tra trên máy tính.

## Luồng nghiệp vụ

- Đăng ký chỉ nhận `ROLE_WORKER` hoặc `ROLE_CONTRACTOR`; mật khẩu được băm BCrypt.
- Chủ thầu đăng loại `Thợ chính` hoặc `Phụ hồ`, lương/ngày, địa chỉ, GPS, số thợ.
- Thợ tìm công trình OPEN theo Haversine, tăng/giảm bán kính, xem mô tả và ứng tuyển.
- UNIQUE(job_id, worker_id) và kiểm tra giao dịch chặn ứng tuyển trùng.
- Chủ thầu xem thông tin thợ, số điện thoại, đánh giá và trạng thái xác thực CCCD,
  rồi nhận hoặc từ chối. Quyết định đã xử lý không bị thay đổi; gửi lại cùng
  quyết định trả kết quả hiện tại.
- Khóa công trình trong giao dịch duyệt; đủ số ACCEPTED thì chuyển IN_PROGRESS.
  Các đơn PENDING còn lại có thể bị từ chối; không thể nhận vượt số thợ.
- Admin kiểm tra liên kết ảnh CCCD đã cung cấp khi đăng ký, xác thực, khóa/mở
  tài khoản hoặc xóa bài vi phạm. Xóa công trình xóa đơn ứng tuyển liên quan.
  Admin không thể tự khóa tài khoản đang dùng.

CCCD dùng hai trường `cccdFrontImage` và `cccdBackImage`, tương ứng cột
`cccd_front_image` / `cccd_back_image` (VARCHAR(500)). Trong **Hồ sơ & CCCD**,
thợ và chủ thầu nhập hai liên kết HTTPS riêng cho mặt trước, mặt sau. Cập nhật
hồ sơ yêu cầu đủ hai ảnh; mỗi lần cập nhật đều cần được xác thực lại.

Admin bấm **Xem CCCD** để mở Bootstrap 5 Modal trong trang, xem hai ảnh lớn
song song và bấm **Xác thực danh tính** ngay trong popup. Thiếu ảnh hoặc ảnh
không tải được thì nút duyệt bị vô hiệu hóa. Form gửi kèm cả hai URL đã xem;
nếu một mặt vừa bị đổi, hệ thống yêu cầu tải lại trước khi duyệt. Modal xóa
URL ảnh khi đóng. Bootstrap CSS/JS được lưu cục bộ kèm giấy phép, không phụ
thuộc CDN để mở popup; ảnh HTTPS vẫn cần truy cập được từ trình duyệt Admin.

Tài khoản mới và seed đều chưa xác thực. Ràng buộc database và Entity không
cho giữ `is_verified=true` khi thiếu mặt trước hoặc mặt sau, áp dụng mọi vai
trò. `ROLE_ADMIN` vẫn đăng nhập quản trị bằng vai trò dù chưa xác thực CCCD.

Chủ thầu bấm **Hoàn thành công trình** khi công trình đang thi công, chọn 1–5
sao cho từng thợ đã được nhận, rồi xác nhận. Điểm được lưu tại
`job_applications.worker_rating`; `users.rating` là trung bình các điểm thực tế
từ công trình đã hoàn thành, không cộng điểm khởi tạo 5.0 vào mẫu số.
Gửi lại cùng yêu cầu không tính điểm hai lần. Xóa công trình có đánh giá sẽ
tính lại trung bình. Các đơn chờ còn lại được từ chối khi công trình hoàn thành.

Đơn ACCEPTED hiển thị điện thoại và nút gọi qua `tel:` trên Flutter bằng
[url_launcher](https://pub.dev/packages/url_launcher). Máy tính cần ứng dụng
xử lý cuộc gọi; nếu không có, ứng dụng hiển thị số để liên hệ. API tìm việc và
đơn chưa được nhận không trả số liên hệ của bên còn lại.

Màn hình thợ có bộ lọc **Thợ chính / Phụ hồ / Tất cả** và sắp xếp **Gần nhất /
Lương cao nhất**, áp dụng cùng bán kính GPS.

## Bản đồ OpenStreetMap

Trong form đăng công trình, chọn **Chọn trên bản đồ**, chạm đúng vị trí rồi bấm
**Dùng vị trí đã chọn**. Có thể lấy GPS hoặc nhập tọa độ như trước; địa chỉ mô
tả và tọa độ được gửi chung khi đăng việc.

Ở màn hình thợ, chuyển sang **Bản đồ** để xem các ghim công trình trong bán
kính và bộ lọc hiện tại. Chạm ghim để xem công trình và Nhận việc. Nút phóng to,
thu nhỏ và về vùng đang tìm hỗ trợ điều hướng. Ghim xanh dương là tâm tìm kiếm.

Ứng dụng dùng [flutter_map](https://pub.dev/packages/flutter_map) với tile HTTPS
OpenStreetMap, attribution luôn hiển thị và định danh ứng dụng riêng. Giữ cơ
chế [cache mặc định của flutter_map](https://docs.fleaflet.dev/layers/tile-layer/caching)
và trình duyệt; chỉ tải vùng đang xem, không có chức năng tải hàng loạt/offline,
theo [chính sách tile OpenStreetMap](https://operations.osmfoundation.org/policies/tiles/).
Nền bản đồ cần mạng; khi tải lỗi vẫn có ghim, lựa chọn tọa độ và danh sách.
Có thể chuyển sang dịch vụ tile dựa trên OSM của bạn bằng build option
`--dart-define=MAP_TILE_URL=https://your-host/{z}/{x}/{y}.png`; giữ attribution
và bổ sung điều kiện/giấy phép của nhà cung cấp khi triển khai.

## Nâng cấp database đã tồn tại

Chạy migration giữ nguyên dữ liệu:

```powershell
psql -U postgres -d tho_xay_db -v ON_ERROR_STOP=1 -f migrations/002_worker_ratings.sql
psql -U postgres -d tho_xay_db -v ON_ERROR_STOP=1 -f migrations/003_cccd_front_back.sql
psql -U postgres -d tho_xay_db -v ON_ERROR_STOP=1 -f migrations/004_messages.sql
psql -U postgres -d tho_xay_db -v ON_ERROR_STOP=1 -f migrations/005_notifications.sql
psql -U postgres -d tho_xay_db -v ON_ERROR_STOP=1 -f migrations/006_extended_profiles.sql
```

Script khởi động local tự áp dụng các migration này khi sử dụng PostgreSQL portable
của workspace ở cổng 55432. PostgreSQL/Docker riêng cần chạy lệnh trên với cấu
hình kết nối của bạn. Database mới đã có cột và ràng buộc trong `schema.sql`.
Migration 003 giữ cột `cccd_image` cũ và chuyển ảnh cũ sang mặt trước nếu trống;
không coi một ảnh là đủ hai mặt. Tài khoản cũ thiếu ảnh được chuyển về chưa xác
thực, cần bổ sung mặt sau rồi Admin duyệt lại. Chạy lại migration giữ nguyên
trạng thái những hồ sơ đã được duyệt đủ hai ảnh.

## REST API

Request và response dùng JSON camelCase. Gửi `Authorization: Bearer <token>`
cho các API nghiệp vụ. ID người thực hiện được lấy từ tài khoản đã xác thực.

| Method | Endpoint | Quyền / kết quả |
| --- | --- | --- |
| POST | `/api/auth/register` | Công khai; tạo tài khoản và JWT, 201 |
| POST | `/api/auth/login` | Công khai; JWT và thông tin tài khoản, 200 |
| GET | `/api/users/me` | Hồ sơ, xác thực và đánh giá của chính người đăng nhập |
| PUT | `/api/users/me/cccd` | Body gồm `cccdFrontImage` và `cccdBackImage` HTTPS; lưu cả hai, verified=false |
| POST | `/api/jobs` | Chủ thầu; tạo công trình, 201 |
| GET | `/api/jobs/nearby?lat=10.7769&lng=106.7009&radius=10` | Thợ; công trình gần nhất trước, kèm distanceKm |
| GET | `/api/jobs/contractor/{contractorId}` | Chủ thầu xem công trình của mình |
| PUT | `/api/jobs/{id}/complete` | Chủ công trình; body `{"ratings":[{"workerId":3,"stars":5}]}` |
| POST | `/api/applications/apply` | Thợ; body `{"jobId":1}`, 201 |
| GET | `/api/applications/job/{jobId}` | Chủ thầu sở hữu công trình |
| GET | `/api/applications/worker/{workerId}` | Thợ xem lịch sử của mình |
| PUT | `/api/applications/{id}/status` | Chủ thầu; body `{"status":"ACCEPTED"}` hoặc `REJECTED` |

Ví dụ body đăng ký:

```json
{"phoneNumber":"0912345678","password":"password123","fullName":"Nguyễn Văn A","role":"ROLE_WORKER","cccdFrontImage":null,"cccdBackImage":null}
```

Ví dụ body cập nhật CCCD:

```json
{"cccdFrontImage":"https://example.com/cccd-front.jpg","cccdBackImage":"https://example.com/cccd-back.jpg"}
```

Thay URL minh họa bằng ảnh của bạn. Đăng ký cho phép bổ sung ảnh sau, nhưng
API cập nhật CCCD trong hồ sơ yêu cầu cả hai URL cùng lúc.

Ví dụ body đăng công trình:

```json
{"title":"Xây nhà phố","description":"7h–17h, bao cơm trưa","jobType":"Thợ chính","salaryPerDay":500000,"address":"Quận 1, TP.HCM","latitude":10.7769,"longitude":106.7009,"requiredWorkers":3}
```

AuthResponse gồm `token`, `tokenType`, `expiresIn` (giây), `userId`, `phoneNumber`,
`fullName`, `role`. Lỗi API có `status`, `message`: 400 dữ liệu không hợp lệ,
401 chưa đăng nhập/token hết hạn, 403 sai quyền hoặc tài khoản bị khóa, 404 không
tìm thấy, 409 trùng hoặc xung đột nghiệp vụ. Bán kính từ 0.1 đến 200 km.
Mật khẩu từ 8 ký tự và tối đa 72 byte UTF-8.
`/api/jobs/nearby` nhận thêm `jobType` (Thợ chính/Phụ hồ, tùy chọn) và
`sort=DISTANCE|SALARY_DESC` (mặc định DISTANCE). Tài khoản bị khóa trả
403 cùng `code=ACCOUNT_LOCKED`; Flutter xóa phiên khi gặp mã này.

## Nhắn tin trực tiếp realtime

Thợ vào **Lịch sử ứng tuyển → Nhắn tin** ở đơn `ACCEPTED`. Chủ thầu vào
**Xem & duyệt thợ → Nhắn tin** ở dòng thợ đã nhận. Mỗi công việc và mỗi cặp
Thầu–Thợ có lịch sử riêng; chỉ hai tài khoản đang hoạt động được đọc/gửi.
Đơn chưa duyệt hoặc bị từ chối không mở được chat, kể cả gọi API trực tiếp.
Các cuộc trò chuyện đã được duyệt vẫn dùng được khi công việc hoàn thành.

Tin được lưu trong `messages` với `sender_id`, `recipient_id`, `job_id`,
`content`, `created_at` (UTC) và `client_message_id` chống trùng khi gửi lại.
Xóa công trình sẽ xóa tin nhắn của công trình đó. Database cũ cần chạy
`migrations/004_messages.sql`; script local tự áp dụng khi dùng PostgreSQL portable.

API dùng JWT Bearer:

| Phương thức | Đường dẫn | Nội dung |
| --- | --- | --- |
| POST | `/api/jobs/{jobId}/messages` | Gửi tin tới `recipientId` |
| GET | `/api/jobs/{jobId}/messages?peerId={userId}` | 50 tin gần nhất, thứ tự ID tăng dần |

Ví dụ body gửi tin:

```json
{"recipientId":3,"content":"Ngày mai bắt đầu lúc 7 giờ nhé","clientMessageId":"unique-retry-id"}
```

Nội dung tối đa 2000 ký tự, không được trống. `clientMessageId` là chuỗi 1–64 ký
tự chữ/số/`_`/`-`, duy nhất theo người gửi. Gửi lại cùng mã và nội dung trả lại
tin đã lưu; dùng mã đó cho nội dung hoặc người nhận khác trả 409. Server lấy
người gửi từ JWT. Lịch sử trả `{messages, hasMore}`, hỗ trợ `limit=1..100`,
`beforeId` để tải tin cũ hoặc `afterId` để đồng bộ tin bỏ lỡ (không dùng cùng lúc).

WebSocket ở `/ws/chat`, ví dụ `ws://192.168.1.16:8080/ws/chat`. Sau khi kết nối,
gửi frame JSON đầu tiên:

```json
{"type":"subscribe","token":"JWT_TOKEN","jobId":1,"peerId":3}
```

Server kiểm tra JWT và đơn ACCEPTED trước khi trả `{"type":"ready"}`. Tin mới
được đẩy dưới dạng `{"type":"message","message":{...}}` sau khi giao dịch lưu
thành công. Token không nằm trong URL. Heartbeat kiểm tra lại tài khoản/quyền
mỗi 10 giây; token hết hạn hoặc tài khoản bị khóa sẽ nhận frame `error` rồi
đóng kết nối. WebSocket của trình duyệt dùng cùng danh sách origin cấu hình
`CORS_ORIGINS` với REST; native mobile không cần header Origin.

Flutter tự nối lại, đồng bộ lịch sử khi mạng trở lại hoặc ứng dụng được mở lại,
khử trùng theo ID và giữ nội dung chưa được xác nhận để gửi lại. URL `ws/wss`
được suy ra từ `API_BASE_URL`. Đóng màn hình hoặc đăng xuất sẽ đóng kết nối.
Realtime hiện chạy trong một tiến trình Backend; triển khai nhiều instance cần
thêm broker dùng chung để chuyển tiếp sự kiện giữa các instance.

## Bảo mật quản trị

`/admin/**` không đòi JWT ở lớp HTTP như đặc tả. Các phương thức dashboard
và thay đổi dữ liệu kiểm tra `ROLE_ADMIN` bằng method security, đăng nhập phiên
bằng form và kiểm tra tài khoản còn hoạt động mỗi request. Form POST có CSRF.
Tài khoản bị khóa không đăng nhập được; JWT đã phát cũng bị chặn ở request kế tiếp.
Response không trả hash mật khẩu hoặc liên kết CCCD cho API tìm việc/ứng tuyển.

## Thông báo

Thợ và chủ thầu mở biểu tượng chuông để xem lịch sử, phân trang, đánh dấu đã đọc
hoặc đọc tất cả. Sự kiện ứng tuyển, duyệt/từ chối, hoàn thành, KYC và chat tạo
thông báo trong cùng transaction. Backend có outbox FCM gửi lại có giới hạn;
không có Firebase vẫn lưu/xem lịch sử bình thường. Hướng dẫn cấu hình Firebase
cho Backend và APK, CI secret, quyền thiết bị: [docs/FIREBASE.md](docs/FIREBASE.md).

## Hồ sơ mở rộng

Trong **Hồ sơ & CCCD**, mở **Thông tin cá nhân & kinh nghiệm** để cập nhật họ tên,
ngày sinh không bắt buộc, số năm kinh nghiệm (0–60), mô tả kinh nghiệm, tối đa
20 kỹ năng và 10 liên kết ảnh dự án HTTPS. Album hỗ trợ xem ảnh lớn/phóng to và
hiển thị trạng thái tải/lỗi. Ảnh dự án dùng URL HTTPS, không tải file lên server.
Đổi họ tên/ngày sinh đưa CCCD về chưa xác thực; chỉ sửa kinh nghiệm/kỹ năng/album
giữ nguyên xác thực. Không dùng ảnh CCCD trong album công khai.

`PUT /api/users/me` chỉ cập nhật hồ sơ của JWT hiện tại, không cho sửa vai trò,
sao hay trạng thái xác thực. Body gồm `fullName`, `dateOfBirth` (`yyyy-MM-dd`
hoặc null), `experienceYears`, `experienceSummary`, `skills`, `projectImages`.
`GET /api/workers/{id}/profile` cho người đã đăng nhập xem hồ sơ nghề nghiệp của
thợ đang hoạt động; không trả ngày sinh, điện thoại hoặc ảnh CCCD. Chủ thầu mở
**Xem hồ sơ thợ** trong danh sách ứng viên. Migration: `006_extended_profiles.sql`.

## Uy tín và xếp hạng

Áp dụng `migrations/007_reputation.sql` sau migration 006 (script local tự chạy).
Thợ khởi đầu 100 điểm; hoàn thành công trình cộng 2, tối đa 100. Điểm sao 1–5
do chủ công trình chốt khi hoàn thành, lấy trung bình từ các đánh giá thực tế.
Gửi lại cùng đánh giá không cộng điểm lần nữa. Dữ liệu cũ được tính lại số
công trình và sao; không cộng thưởng ngược cho công trình đã hoàn thành.

| Bậc | Điều kiện |
| --- | --- |
| Bạc | Bậc khởi đầu hoặc chưa đủ điều kiện bậc cao hơn |
| Vàng | Uy tín ≥80, sao ≥4.0, ít nhất 5 công trình đã được đánh giá |
| Kim Cương | Uy tín ≥95, sao ≥4.7, ít nhất 20 công trình và CCCD đã xác thực |

`GET /api/workers/leaderboard?limit=20` xếp thợ đang hoạt động, đã có đánh giá,
theo bậc, uy tín, sao, số công trình và ID. `GET /api/workers/{id}/reviews`
có phân trang `beforeId/limit`; `GET /api/users/me/reputation` là lịch sử
điểm của chính tài khoản. Flutter mở các mục này từ Hồ sơ. Thay đổi danh tính
làm mất KYC và tính lại bậc; xóa công trình tính lại số công trình/sao/bậc,
nhưng nhật ký điểm đã ghi vẫn được giữ với tên công trình tại thời điểm phát sinh.

## Hủy việc đang làm

Áp dụng `migrations/008_application_cancellation.sql` sau migration 007;
`scripts/start-local.ps1` áp dụng các migration theo thứ tự và có thể chạy lại.
Thợ dùng `PUT /api/applications/{id}/cancel` với `{"reason":"Lý do hủy"}`
(1–500 ký tự) cho đơn ACCEPTED của chính mình thuộc công trình IN_PROGRESS.
Không cho hủy đơn chờ, bị từ chối hoặc công trình đã hoàn thành.

Flutter: **Đã ứng tuyển → Hủy việc đang làm → nhập lý do → Xác nhận hủy việc**.
Hộp thoại nêu rõ trừ 15 điểm (tối thiểu 0), tính lại bậc và không thể khôi phục
đơn. Lý do, thời điểm và điểm thực trừ được lưu; gửi lại không bị phạt thêm.
Thợ và chủ thầu nhận thông báo trong lịch sử (push khi Firebase đã cấu hình).
Sau hủy, đơn không còn hiển thị số liên lạc và không còn quyền chat, kể cả
JWT/đường dẫn cũ; kết nối realtime kiểm tra lại quyền tại heartbeat tiếp theo.

Công trình giữ IN_PROGRESS. Khi thiếu người, kết quả tìm việc gần hiển thị
công trình để thợ khác ứng tuyển, chủ thầu có thể nhận người thay thế. Hoàn
thành chỉ chấm điểm những thợ ACCEPTED còn lại; thợ đã hủy không được thưởng
hay nhận sao công trình. Khóa công trình rồi khóa thợ bảo đảm hủy, duyệt và
hoàn thành đồng thời không vượt số người, trừ/cộng điểm hai lần hoặc chốt cả
hai kết quả trái ngược. Hủy đơn giữ bản ghi nên cùng thợ không ứng tuyển lại
vào chính công trình đã hủy.

Các mức điểm/ngưỡng là quy tắc mặc định của phiên bản đồ án, định nghĩa tại
`ReputationService` và `WorkerTier`, hiển thị trong ứng dụng để người dùng biết.

## Trạng thái nhận việc

Migration `009_worker_availability.sql` lưu `users.is_available`. Tài khoản cũ
giữ Online để không gián đoạn; đăng ký mới bắt đầu Offline. Thợ bật/tắt bằng
`GET/PUT /api/users/me/availability` (body `{"available":true}`), chỉ thay đổi
chính tài khoản thợ đang đăng nhập. Flutter đồng bộ trạng thái trước khi tìm
GPS; Offline không tìm việc quanh đây và Backend chặn ứng tuyển/duyệt mới.
Đơn đã nhận, nhắn tin và lịch sử được giữ. Bật Online thể hiện sẵn sàng nhận
việc, không tự nhận đơn hoặc theo dõi vị trí nền. Các thao tác duyệt/ứng tuyển
và đổi trạng thái được khóa để tránh dùng dữ liệu trạng thái cũ.

## Thu nhập, Ví và Ký quỹ

Menu ví trên Flutter mở Thu nhập theo Ngày/Tuần/Tháng hoặc Ví điện tử.
Chủ thầu thanh toán tiền công, tip và thưởng sau khi hoàn thành công trình;
Admin đối soát nạp/rút tại `/admin/wallet`. Chi tiết quy tắc, API, hạn mức và
migration 010 trong [docs/WALLET.md](docs/WALLET.md). Chưa có cổng thanh toán
ngân hàng tự động; nạp/rút là yêu cầu chờ đối soát thực tế.

## Giao diện trình bày đồ án

Flutter dùng theme xanh ngọc thống nhất cho form, nút, điều hướng và chat.
Card công trình phân biệt Thợ chính/Phụ hồ bằng icon, nhãn và màu, nhấn rõ mức
lương, khoảng cách và trạng thái. Danh sách và tile bản đồ có shimmer trong
lúc tải; animation dừng khi route không hoạt động hoặc bật giảm chuyển động.
Kết quả trống có minh họa vector được vẽ tại ứng dụng và nút đổi vị trí/khám phá
việc/đăng công trình. Lỗi kết nối được hiển thị riêng để không nhầm với hết việc.

Admin có thanh điều hướng, bảng cuộn ngang khi màn hình hẹp, avatar, icon SVG
local và badge xanh/đỏ/vàng kèm chữ. Bốn thẻ thống kê lấy dữ liệu thật: tổng tài
khoản, công trình OPEN, tỷ lệ KYC và hồ sơ đủ ảnh chờ duyệt. Tỷ lệ KYC bằng số
tài khoản đã xác thực chia tổng tài khoản (kể cả admin), làm tròn phần trăm;
không có tài khoản thì hiển thị 0%. Không dùng font/icon/ảnh CDN cho trang trí.

## Cấu trúc và kiểm chứng

- `src/main/java/vn/thoxay/`: entity, repository, DTO, security, service, controller, admin.
- `src/main/resources/`: cấu hình, template quản trị, CSS.
- `mobile_app/lib/`: models, services, screens và widgets.
- `schema.sql`: các bảng PostgreSQL, constraints, indexes và seed.
- [AGENTS.md](AGENTS.md): kiến trúc và quy trình build → commit → push cho mỗi hạng mục.
- [TESTING.md](TESTING.md): lệnh kiểm thử, phạm vi đã kiểm chứng và kịch bản nghiệm thu.
