# Thợ Xây

Đồ án **Ứng dụng Di động Kết nối Lao động Phổ thông & Chủ thầu**.

Backend Java 17+ / Spring Boot 3.5, PostgreSQL, JPA, Spring Security, JWT,
BCrypt và Validation. Web quản trị dùng Thymeleaf / Bootstrap 5. Ứng dụng
Flutter có giao diện tiếng Việt cho thợ và chủ thầu, chạy trên Android, iOS và Web.

## Chạy backend và Web Admin

Cần JDK 17 trở lên; Maven Wrapper đã có trong repository. Dùng PostgreSQL
có sẵn hoặc Docker Desktop:

```powershell
docker compose up -d db
.\scripts\start-local.ps1
```

Compose tạo database `tho_xay_db`, ba bảng và dữ liệu demo từ [schema.sql](schema.sql).
Chỉ nạp script tự động khi volume database được khởi tạo lần đầu. Với PostgreSQL
cài riêng, tạo database rồi nạp:

```powershell
createdb -U postgres tho_xay_db
psql -U postgres -d tho_xay_db -v ON_ERROR_STOP=1 -f schema.sql
.\scripts\start-local.ps1
```

API: `http://localhost:8080/api`. Web quản trị:
`http://localhost:8080/admin/login`.

Script khởi động chạy `mvnw verify` trước khi chạy JAR. Nếu chưa đặt `JWT_SECRET`,
script tạo khóa ngẫu nhiên cho phiên chạy local; token cũ sẽ hết hiệu lực sau
khi khởi động lại với khóa mới. Đặt khóa Base64 riêng (ít nhất 32 byte ngẫu nhiên)
để giữ phiên qua các lần khởi động. [`.env.example`](.env.example) liệt kê các biến;
Spring Boot đọc biến môi trường của tiến trình, không tự nạp tệp `.env`.

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

API mặc định: Android emulator dùng `http://10.0.2.2:8080`; Web và iOS simulator
dùng `http://localhost:8080`. Đổi địa chỉ cho điện thoại thật bằng địa chỉ LAN
của máy backend:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

Thay URL minh họa bằng API đang chạy của bạn. Android debug cho phép HTTP để
test local; bản phát hành dùng HTTPS. Android cần Android SDK và thiết bị/emulator.
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

Trường `cccdImage` là liên kết ảnh HTTPS, đúng kiểu VARCHAR trong đặc tả.
Liên kết tùy chọn được nhập khi đăng ký; chưa có ảnh thì chưa thể xác thực.
Đánh giá khởi tạo 5.0; chức năng chấm điểm sau công việc không thuộc đặc tả này.

## REST API

Request và response dùng JSON camelCase. Gửi `Authorization: Bearer <token>`
cho các API nghiệp vụ. ID người thực hiện được lấy từ tài khoản đã xác thực.

| Method | Endpoint | Quyền / kết quả |
| --- | --- | --- |
| POST | `/api/auth/register` | Công khai; tạo tài khoản và JWT, 201 |
| POST | `/api/auth/login` | Công khai; JWT và thông tin tài khoản, 200 |
| POST | `/api/jobs` | Chủ thầu; tạo công trình, 201 |
| GET | `/api/jobs/nearby?lat=10.7769&lng=106.7009&radius=10` | Thợ; công trình gần nhất trước, kèm distanceKm |
| GET | `/api/jobs/contractor/{contractorId}` | Chủ thầu xem công trình của mình |
| POST | `/api/applications/apply` | Thợ; body `{"jobId":1}`, 201 |
| GET | `/api/applications/job/{jobId}` | Chủ thầu sở hữu công trình |
| GET | `/api/applications/worker/{workerId}` | Thợ xem lịch sử của mình |
| PUT | `/api/applications/{id}/status` | Chủ thầu; body `{"status":"ACCEPTED"}` hoặc `REJECTED` |

Ví dụ body đăng ký:

```json
{"phoneNumber":"0912345678","password":"password123","fullName":"Nguyễn Văn A","role":"ROLE_WORKER","cccdImage":null}
```

Ví dụ body đăng công trình:

```json
{"title":"Xây nhà phố","description":"7h–17h, bao cơm trưa","jobType":"Thợ chính","salaryPerDay":500000,"address":"Quận 1, TP.HCM","latitude":10.7769,"longitude":106.7009,"requiredWorkers":3}
```

AuthResponse gồm `token`, `tokenType`, `expiresIn` (giây), `userId`, `phoneNumber`,
`fullName`, `role`. Lỗi API có `status`, `message`: 400 dữ liệu không hợp lệ,
401 chưa đăng nhập/token hết hạn/tài khoản bị khóa, 403 sai quyền, 404 không
tìm thấy, 409 trùng hoặc xung đột nghiệp vụ. Bán kính từ 0.1 đến 200 km.
Mật khẩu từ 8 ký tự và tối đa 72 byte UTF-8.

## Bảo mật quản trị

`/admin/**` không đòi JWT ở lớp HTTP như đặc tả. Các phương thức dashboard
và thay đổi dữ liệu kiểm tra `ROLE_ADMIN` bằng method security, đăng nhập phiên
bằng form và kiểm tra tài khoản còn hoạt động mỗi request. Form POST có CSRF.
Tài khoản bị khóa không đăng nhập được; JWT đã phát cũng bị chặn ở request kế tiếp.
Response không trả hash mật khẩu hoặc liên kết CCCD cho API tìm việc/ứng tuyển.

## Cấu trúc và kiểm chứng

- `src/main/java/vn/thoxay/`: entity, repository, DTO, security, service, controller, admin.
- `src/main/resources/`: cấu hình, template quản trị, CSS.
- `mobile_app/lib/`: models, services, screens và widgets.
- `schema.sql`: ba bảng PostgreSQL, constraints, indexes và seed.
- [AGENTS.md](AGENTS.md): kiến trúc và quy trình build → commit → push cho mỗi hạng mục.
- [TESTING.md](TESTING.md): lệnh kiểm thử, phạm vi đã kiểm chứng và kịch bản nghiệm thu.
