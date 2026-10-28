# Đưa Thợ Xây lên Internet: Vercel + Render + PostgreSQL

Bạn đã kết nối GitHub với Vercel. Repository đã được chuẩn bị để Import Project
trực tiếp, nhưng cần tạo Backend/database online trước. Hiện chưa có URL online
hay tài nguyên trả phí nào được tạo tự động.

## Cách tự động bằng Blueprint (ưu tiên khi triển khai qua plugin)

Nếu phiên triển khai đã dùng Render CLI để tạo dịch vụ trực tiếp, cấu hình đang
chạy được quản lý trong Render (Environment/Secret Files), không phải Blueprint.
CLI có thể chuyển các thông tin kết nối và JWT qua secret file `backend.properties`,
được import bằng `SPRING_CONFIG_IMPORT=file:/etc/secrets/backend.properties`.
File tạm local nằm trong `.local` bị Git bỏ qua và được xóa sau khi chuyển lên Render.
Docker chạy user không phải root, thuộc group 1000 để đọc secret file theo hướng
dẫn của Render. Không Apply Blueprint lên dịch vụ CLI đang chạy khi chưa đối chiếu
các secret hiện có; `generateValue` khi thiếu biến có thể tạo một khóa JWT khác.

`render.yaml` ghép Backend Docker với database `tho-xay-db`, cùng vùng Singapore,
gói Free. Nếu database này đã được tạo trong workspace ThoXay, Blueprint dùng
lại nó theo tên, không tạo một bản khác. Không sửa các thuộc tính bất biến của
database đang có và không chạy Blueprint này ở workspace khác.

1. Mở [Apply Blueprint cho ThoXay](https://dashboard.render.com/blueprint/new?repo=https://github.com/tranngocthiet2k6-ai/ThoXay),
   chọn workspace ThoXay. Kết nối GitHub nếu Render yêu cầu.
2. Xem danh sách tài nguyên: `thoxay-api` và `tho-xay-db`, cả hai **Free**;
   xác nhận sử dụng database hiện có. Chọn Apply/Deploy.
3. Render tự truyền host/port/database/user/password cho Backend bằng `fromDatabase`,
   tự tạo `JWT_SECRET`. Bạn không phải dán những giá trị này vào chat hay source.
4. Backend nhận `DB_INIT_MODE=always`: khởi tạo DDL `CREATE ... IF NOT EXISTS`
   từ `src/main/resources/db/cloud-schema.sql` trước khi Hibernate kiểm tra schema.
   Không thêm tài khoản/công trình demo, không xóa hay sửa dữ liệu hiện có.
5. Sau khi Backend live, plugin sẽ dùng URL HTTPS thật của nó để nối Vercel.
   Cập nhật `CORS_ORIGINS` trong `render.yaml` bằng URL Production Vercel thật
   rồi push/sync để cấu hình vẫn đồng nhất qua các lần cập nhật Blueprint.

File DDL bootstrap được xuất từ `schema.sql` bằng `scripts/export-cloud-schema.mjs`;
kiểm thử phát hiện nếu file này lệch nguồn hoặc lẫn dữ liệu mẫu. Khi thay đổi
schema trên database đã có bảng, vẫn cần migration tương ứng: bootstrap chỉ tạo
bảng/index chưa có, không thay thế quy trình nâng cấp dữ liệu.

Nếu dùng Blueprint, bỏ qua bước tạo database và nhập các secret thủ công bên dưới.
Phần tiếp theo là phương án cấu hình thủ công khi không dùng Blueprint.

| Thành phần | Nơi chạy | Ví dụ URL, cần thay bằng URL thật của bạn |
| --- | --- | --- |
| Flutter Web cho Thợ/Chủ thầu | Vercel | `https://ten-du-an.vercel.app` |
| Spring Boot REST API, WebSocket, ảnh CCCD, Admin | Render Docker Web Service | `https://ten-api.onrender.com` |
| Dữ liệu và ảnh CCCD riêng tư | Render Postgres | Không có giao diện public cho người dùng |

Vercel phục vụ bản Web tĩnh; ứng dụng Spring Boot hiện tại cần tiến trình Java
chạy liên tục, kết nối PostgreSQL và WebSocket. Admin Thymeleaf đi cùng Backend,
không phải một thư mục HTML độc lập để upload lên Vercel.
Địa chỉ `192.168.1.16` chỉ dùng trong LAN; bản cloud yêu cầu API HTTPS.

## 1. Tạo database online trống

1. Đăng nhập [Render Dashboard](https://dashboard.render.com/), kết nối GitHub.
2. Chọn **New → Postgres**. Đặt tên `tho-xay-db`; nếu được chọn tên database,
   dùng `tho_xay_db`. Chọn vùng mà bạn cũng sẽ dùng cho Backend.
3. Xem gói và chi phí hiển thị trước khi tạo. Gói miễn phí có các giới hạn/thời hạn;
   kiểm tra [chính sách hiện tại](https://render.com/docs/free) trước khi dùng cho buổi bảo vệ.
4. Sau khi Available, ghi nhận **Database**, **Username**, **Password**,
   **Internal Hostname** và thông tin kết nối external. Giữ mật khẩu trong
   dashboard của bạn, không đưa vào Git hay gửi qua chat.

Khởi tạo **database mới trống** bằng PowerShell tại thư mục gốc repo:

```powershell
node scripts/export-cloud-schema.mjs --output .local/cloud-schema.sql
$env:PGSSLMODE = 'require'
# Thay ba giá trị sau bằng thông tin EXTERNAL của Render, không dùng hostname nội bộ.
& .\.tools\postgres\pgsql\bin\psql.exe -h 'EXTERNAL_HOST' -p 5432 -U 'DB_USER' -d 'DB_NAME' -W -v ON_ERROR_STOP=1 -f .local/cloud-schema.sql
```

`-W` hỏi mật khẩu trong terminal. Nếu máy chưa có bản portable tại `.tools`,
cài PostgreSQL client rồi dùng `psql` thay cho đường dẫn trên.
File export nằm trong `.local` được Git bỏ qua; script không ghi đè file có sẵn.
File này chỉ có DDL, không có tài khoản demo/mật khẩu `password` hay công trình mẫu.
Không chạy như một bản nâng cấp database cũ: trường hợp đó cần sao lưu và chạy
đúng các migration `002` đến `011` theo thứ tự. Dữ liệu local hiện có chưa được chuyển online.

## 2. Tạo Backend và Admin trên Render

**New → Web Service → Git Provider → repository ThoXay**, cấu hình:

| Mục | Giá trị |
| --- | --- |
| Branch | `main` |
| Language / Runtime | `Docker` |
| Root Directory | Để trống, dùng thư mục gốc repo |
| Dockerfile Path | `./Dockerfile` |
| Region | Cùng vùng với database |
| Health Check Path | `/health` |
| Docker Command | Để trống, dùng ENTRYPOINT trong Dockerfile |

Thêm các biến **Environment** sau trước khi Deploy:

| Biến | Giá trị |
| --- | --- |
| `SPRING_PROFILES_ACTIVE` | `prod` (Dockerfile đã đặt mặc định) |
| `DB_URL` | `jdbc:postgresql://INTERNAL_HOST:5432/DB_NAME?sslmode=require` |
| `DB_USERNAME` | Username thật của database |
| `DB_PASSWORD` | Password thật, nhập trực tiếp trong Render |
| `JWT_SECRET` | Khóa Base64 ngẫu nhiên riêng, tạo một lần bằng lệnh bên dưới |
| `CORS_ORIGINS` | Tạm dùng `https://deployment-pending.invalid`; cập nhật ở bước 4 |
| `APP_FCM_ENABLED` | `false` nếu chưa cấu hình Firebase |

`DB_URL` là **JDBC URL**, không dán nguyên chuỗi `postgresql://user:password@...`
vào biến này. Dùng hostname nội bộ khi Backend và DB cùng vùng Render;
nếu dùng PostgreSQL nhà cung cấp khác, dùng hostname public/TLS theo nhà cung cấp đó.
Render cung cấp `PORT`, Backend đã đọc biến này và bind `0.0.0.0`.

Tạo khóa JWT trên máy của bạn rồi dán kết quả vào Render:

```powershell
$keyBytes = New-Object byte[] 48
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($keyBytes) } finally { $rng.Dispose() }
[Convert]::ToBase64String($keyBytes)
```

Giữ cùng khóa qua các lần Deploy để tránh vô hiệu hóa toàn bộ JWT đang dùng.
Không đặt JWT secret, mật khẩu database hoặc service account trong Vercel:
Vercel chỉ cần URL API công khai.

Chọn gói sau khi xem giá, rồi Deploy. Dockerfile chạy Maven verify bằng Java 17
trước khi tạo image, chạy bằng user không phải root. Profile `prod` kiểm tra schema
với `validate`, không tự tạo bảng hoặc seed; nếu lỗi schema, xem bước 1.

Sau khi Live, mở:

- `https://BACKEND_THAT/health` → `{"status":"UP"}`.
- `https://BACKEND_THAT/admin/login` → form Admin.

Bạn sẽ cần URL HTTPS Backend ở bước tiếp theo. Chưa có tài khoản Admin mặc định.

## 3. Import Project trên Vercel

Trong [Vercel New Project](https://vercel.com/new):

1. Import repository `tranngocthiet2k6-ai/ThoXay` từ GitHub.
2. Production Branch: `main`. Đặt Project Name theo ý bạn.
3. **Framework Preset: Other**; **Root Directory: thư mục gốc repo (`.`)**,
   không chọn `mobile_app`. `vercel.json` nằm ở thư mục gốc.
4. Giữ cấu hình từ `vercel.json`:
   - Build Command: `node scripts/build-vercel.mjs`.
   - Install Command: `node --version`.
   - Output Directory: `mobile_app/build/web`.
   - Node.js: `24.x` trong Project Settings nếu cần chọn.
5. Thêm Environment Variable cho **Production**:
   `API_BASE_URL=https://BACKEND_THAT`.
   Chỉ dùng origin HTTPS, **không có `/api` ở cuối**, không dùng localhost/IP LAN.
6. Deploy. Script tải Flutter đúng phiên bản trong `.flutter-version` từ kho
   chính thức, kiểm tra SHA-256 rồi build. Lần đầu tải SDK có thể mất vài phút.
7. Ghi nhận URL Production Vercel thật, ví dụ `https://ten-du-an.vercel.app`.

Nếu không có `API_BASE_URL`, script dừng với lỗi rõ ràng trước khi build.
Thay biến này cần **Redeploy** vì Flutter nhúng cấu hình API lúc biên dịch.
Vercel chỉ nhận Flutter Web đã build; `.local`, SDK và bí mật không được upload.
Các rewrites giữ hỗ trợ tải lại trang; file tĩnh được ưu tiên theo filesystem.

## 4. Nối hai dịch vụ

Quay lại Render → Backend → Environment, đổi `CORS_ORIGINS` từ giá trị tạm sang
URL Vercel Production chính xác, **không có dấu `/` cuối**:

```text
CORS_ORIGINS=https://ten-du-an.vercel.app
```

Save và Redeploy Backend. CORS này dùng cho REST/multipart lẫn WebSocket.
Flutter tự đổi `https` thành `wss` khi chat, kết nối thẳng tới Backend.
Không proxy Java/Admin/WebSocket qua Vercel.

Nếu dùng thêm domain riêng, liệt kê các origin được phép, cách nhau bằng dấu phẩy.
Preview Deployment Vercel có origin khác; muốn thử Preview phải cấu hình
`API_BASE_URL` cho Preview và thêm đúng URL Preview vào CORS, hoặc dùng Backend staging.
Không mở CORS cho toàn bộ `*.vercel.app`.

## 5. Tạo tài khoản Admin của bạn

1. Mở Web Vercel, đăng ký **Chủ thầu** bằng số điện thoại và mật khẩu riêng của bạn.
2. Kết nối **database cloud** bằng psql như bước 1, thay `-f` bằng:

```powershell
& .\.tools\postgres\pgsql\bin\psql.exe -h 'EXTERNAL_HOST' -p 5432 -U 'DB_USER' -d 'DB_NAME' -W -f scripts/promote-cloud-admin.sql
```

3. Nhập đúng số điện thoại tài khoản vừa tạo khi được hỏi. Script chỉ đổi
   ROLE_CONTRACTOR đó thành ROLE_ADMIN, không tạo mật khẩu mặc định.
4. Đăng xuất tài khoản đó khỏi Flutter và đăng nhập lại ở
   `https://BACKEND_THAT/admin/login`. Tạo các tài khoản Thợ/Chủ thầu riêng để thử nghiệp vụ.

## 6. Nghiệm thu online

- `/health` UP; mở được trang Admin bằng HTTPS và đăng nhập được.
- Web Vercel đăng ký/đăng nhập được, tìm công trình và mở hồ sơ không báo CORS.
- Chat giữa hai tài khoản đã ACCEPTED dùng `wss://BACKEND_THAT/ws/chat`.
- Camera/GPS Web cần quyền trình duyệt và HTTPS; desktop có thể mở bộ chọn ảnh
  thay camera, tùy trình duyệt. Gửi ảnh CCCD vẫn cần Admin duyệt danh tính.
- Số dư online bắt đầu từ 0, nạp/rút chờ Admin đối soát. Không có giao dịch demo tự động.
- FCM thật vẫn cần Firebase riêng; lịch sử thông báo hoạt động khi FCM tắt.
- Giữ Backend một instance khi dùng bộ phát chat trong bộ nhớ hiện tại;
  nhiều instance cần bổ sung message broker trước khi mở rộng.

Mỗi push `main` sau khi đã liên kết repo sẽ kích hoạt build mới trên các dịch vụ.
Workflow `deployment-checks.yml` kiểm tra container và lệnh build Vercel;
workflow APK hiện có vẫn hoạt động. APK hiện vẫn dùng cấu hình LAN riêng:
muốn APK gọi Backend online cần build lại APK với `--dart-define=API_BASE_URL=https://BACKEND_THAT`.

## Bạn cần cung cấp cho tôi để kiểm tra tiếp

Chỉ gửi **URL HTTPS Backend**, **URL Production Vercel** và thông báo lỗi build
nếu có (đã bỏ khóa/mật khẩu). Tôi có thể kiểm tra health, tài nguyên Web và
CORS từ hai URL đó. Bạn tự nhập thông tin đăng nhập, database và khóa JWT
trong dashboard; không cần gửi mật khẩu hay token Vercel/Render cho tôi.

## Tài liệu chính thức

- [Vercel build/output](https://vercel.com/docs/builds/configure-a-build)
  và [vercel.json](https://vercel.com/docs/project-configuration/vercel-json).
- [Flutter Web release](https://docs.flutter.dev/deployment/web)
  và [SDK archive](https://docs.flutter.dev/install/archive).
- [Render Docker](https://render.com/docs/docker),
  [Web Services](https://render.com/docs/web-services),
  [Postgres](https://render.com/docs/postgresql-creating-connecting).
