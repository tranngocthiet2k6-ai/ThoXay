# Thợ Xây trên Ubuntu AWS

Bộ triển khai dành cho Ubuntu Server 24.04 LTS, EC2 `t4g.small` ARM64 hoặc
`t3.small` AMD64, 2 vCPU/2 GB RAM, SSD gp3 từ 30 GB. Backend Java 17 chạy bằng
systemd, heap tối đa 768 MB; Nginx phục vụ HTTPS và WebSocket. PostgreSQL mới
dùng image chính thức `postgres:17-alpine`, volume bền vững và giới hạn RAM
384 MB. Java và database chỉ lắng nghe cổng loopback. Không build trên VPS.

## Trước khi triển khai

- Security group: TCP 22 chỉ từ IP quản trị; TCP 80 và 443 cho khách truy cập.
  Không mở 5432 hoặc 8080 ra Internet. Không cần RDS, NAT Gateway hay Load Balancer.
- Trỏ hostname API đầy đủ (ví dụ `api.ten-mien-cua-ban.vn`) tới IPv4 máy chủ.
  Tên ứng dụng `Thoxay` chưa phải hostname. Web `thoxay.vercel.app` có thể giữ
  nguyên trên Vercel. Cần cập nhật DNS nếu IP EC2 thay đổi khi stop/start.
- Đăng nhập SSH, đối chiếu fingerprint của máy chủ bằng nguồn tin cậy từ AWS,
  rồi thêm máy chủ vào known_hosts. Script dùng kiểm tra host key nghiêm ngặt.
- Với hệ thống đã có dữ liệu, dùng chế độ `existing` và kết nối database hiện
  hành. Đảm bảo database cho phép IP EC2 và đã sao lưu trước khi chạy Flyway.
  Không dùng `new` để thay cho database hiện hành.

## Chạy từ PowerShell tại thư mục dự án

Chuẩn bị gói đã build/test, chưa kết nối hoặc tạo tài nguyên AWS:

```powershell
.\scripts\deploy-aws.ps1 -Server ec2.example.com -ApiDomain api.example.com -IdentityFile .local/aws/key.pem -PrepareOnly
```

Database hiện hành: tạo file riêng `.local/aws/backend.env`, không commit,
chứa các dòng sau với giá trị thật. `DB_URL` là JDBC URL với `sslmode=require`
cho database từ xa. Giữ JWT secret cũ nếu muốn token đang dùng tiếp tục hợp lệ.
File phải theo cú pháp systemd EnvironmentFile; đặt giá trị trong dấu nháy
đơn nếu chứa khoảng trắng hoặc ký tự đặc biệt. Không dùng `export`.

```text
DB_URL=jdbc:postgresql://DB_HOST:5432/DB_NAME?sslmode=require
DB_USERNAME=YOUR_DATABASE_USER
DB_PASSWORD=YOUR_DATABASE_PASSWORD
JWT_SECRET=YOUR_EXISTING_BASE64_JWT_SECRET
```

```powershell
.\scripts\deploy-aws.ps1 -Server EC2_IP -ApiDomain api.example.com -IdentityFile .local/aws/key.pem -RuntimeEnvironmentFile .local/aws/backend.env
```

Chỉ khi chủ động tạo môi trường mới, chưa có dữ liệu cần giữ:

```powershell
.\scripts\deploy-aws.ps1 -Server EC2_IP -ApiDomain api.example.com -IdentityFile .local/aws/key.pem -DatabaseMode new
```

Chế độ mới sinh mật khẩu và JWT secret ngẫu nhiên trực tiếp trên VPS; không
nạp tài khoản demo hoặc tự tạo admin. Đăng ký tài khoản chủ thầu của bạn rồi
dùng `scripts/promote-cloud-admin.sql` với đúng database nếu cần quyền admin.
Không tự xác thực CCCD. File môi trường chỉ root đọc được tại `/etc/thoxay`.

## Kiểm tra và chuyển ứng dụng

Installer chỉ thành công khi cả health nội bộ và HTTPS trả `UP`. Sau đó kiểm
tra `/admin/login`, đăng nhập, dữ liệu hiện có, CORS từ web và WebSocket chat.
Đổi `API_BASE_URL` trên Vercel sang origin HTTPS mới rồi redeploy web; APK cũng
cần build lại với `--dart-define=API_BASE_URL=https://API_HOSTNAME`.
Bộ triển khai không tự đổi web/APK trước các kiểm tra này.

Lệnh vận hành trên Ubuntu:

```bash
sudo systemctl status thoxay
sudo journalctl -u thoxay -n 100
sudo certbot renew --dry-run
```

JAR được lưu theo SHA256 trong `/opt/thoxay/releases`; `previous.jar` giữ bản
trước. Đây chỉ là bản cũ của mã chạy, không hoàn tác migration. Backup database
ra ngoài VPS trước mỗi lần cập nhật. Database mới có thể xuất bằng:

```bash
sudo docker exec thoxay-postgres pg_dump -U thoxay -d tho_xay_db -Fc > thoxay-backup.dump
```

Lưu bản dump trong thư mục riêng có quyền hạn chế, kiểm tra phục hồi và chuyển
ra ngoài VPS. Không đưa dump, ảnh CCCD, secret hoặc SSH key lên Git.
Theo dõi Billing/credit; EC2, EBS, public IPv4, snapshot và CPU credit có thể
tính phí riêng. T4g là CPU burstable, không bảo đảm dùng 100% cả hai vCPU liên tục.
