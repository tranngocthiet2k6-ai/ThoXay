# Môi trường trình diễn ThoXay

Demo dùng database riêng `thoxay_defense_demo` trên PostgreSQL loopback cổng 55433.
Không có seed tự chạy khi triển khai Render. Script từ chối host ngoài loopback,
database khác tên, database có bất kỳ người dùng nào không mang tiền tố `[DEMO]`,
hoặc chưa được Flyway nâng cấp tới V21. Không xóa hay ghi đè dữ liệu cũ khi chạy lại.

## Khởi động

```powershell
.\scripts\start-demo.ps1 -OpenBrowser
# Lần sau nếu code không đổi:
.\scripts\start-demo.ps1 -SkipBuild -OpenBrowser
# Dừng đúng các tiến trình demo, giữ database:
.\scripts\stop-demo.ps1
```

Trên máy thực hiện dự án, Java, Node, Flutter và PostgreSQL đã được chuẩn bị.
Để tái lập trên máy khác cần Java 17+, Node, Flutter theo `.flutter-version`,
PostgreSQL tools tại `.tools/postgres/pgsql/bin` và một cluster riêng
`.local/advanced-pgdata` lắng nghe localhost:55433. Python cần `psycopg`, `bcrypt`,
`Pillow`; launcher ưu tiên Python đi kèm PostgreSQL/pgAdmin. Đây là môi trường
demo cục bộ, không phải quy trình khởi tạo production.

Sau khi chạy, mở http://127.0.0.1:3008 hoặc Admin
http://127.0.0.1:18083/admin/login. Số điện thoại và mật khẩu ngẫu nhiên được lưu
trong `.local/demo/access.md`, thư mục đã bị Git bỏ qua. Launcher không in mật khẩu.
Backend chỉ bind loopback, cookie secure chỉ tắt cho instance HTTP cục bộ này.
Mặc định release APK/Web production vẫn gọi HTTPS Render như trước.

## Nội dung mẫu

- 8 tài khoản: 1 Admin, 2 Chủ thầu, 5 Thợ, tất cả tên có `[DEMO]`.
- Hồ sơ đã xác thực dùng hai ảnh minh họa đóng dấu DEMO, không chứa CCCD thật.
- 8 công trình đang tuyển tại các khu vực TP.HCM với tọa độ đại diện khu vực.
- 39 công trình hoàn thành cùng đánh giá và thanh toán để tạo Top 3, bậc Kim Cương,
  Vàng, Bạc, lịch sử công việc và thu nhập thực sự truy vấn từ sổ giao dịch mẫu.
- 1 công trình đang làm, chat, báo cáo ảnh chờ nghiệm thu, tổ đội đã xác nhận,
  lịch bận, công trình yêu thích, thợ quen và sự cố an toàn chờ Admin.
- Số dư ví khớp tổng main/escrow/held delta của sổ giao dịch. Ký quỹ của thợ đầu
  tiên là 100.000đ để minh họa cảnh báo dưới 200.000đ. Có yêu cầu rút chờ xử lý.

## VietQR trình diễn

Chỉ database demo được cấu hình BIN `000000`, số tài khoản `0000000000`, tên
`DEMO ONLY`, ngân hàng `DEMO KHONG CHUYEN TIEN`. API tạo payload TLV và CRC để
trình diễn việc điền tiền/nội dung đối soát. Đây **không phải tài khoản nhận tiền
hợp lệ để thanh toán**. Không chuyển tiền hoặc trình bày nó như kết nối ngân hàng thật.
Admin có thể sửa cấu hình trên giao diện như mọi môi trường khác.

Seed chỉ thêm cấu hình nếu chưa có dòng cài đặt; không thay ngân hàng đã được Admin
lưu. Production tiếp tục yêu cầu Admin nhập ngân hàng thật và xác nhận đối chiếu.
FCM trong demo tắt; lịch sử thông báo vẫn có. Thời tiết/OSM cần Internet, còn các
giao dịch và dữ liệu mẫu đều nằm trên máy. Trình duyệt localhost có thể dùng quyền
camera/GPS, nhưng GPS thật có thể nằm ngoài bán kính công trình: dùng QR ca làm
được chủ thầu cấp nếu cần minh họa chấm công mà không giả mạo tọa độ.

## Kiểm chứng

```powershell
& '.tools/postgres/pgsql/pgAdmin 4/python/python.exe' scripts/tests/demo_seed_test.py
& '.tools/postgres/pgsql/pgAdmin 4/python/python.exe' scripts/verify-demo.py
```

Kiểm chứng gồm đối chiếu tổng delta với số dư ví, tính lại số công trình/điểm sao,
Top 3 thực tế, dữ liệu ngày của biểu đồ, hộp thư và tạo lại cùng yêu cầu VietQR
250.000đ để kiểm tra idempotency/CRC. Yêu cầu này là mô phỏng và luôn chờ Admin,
không tự cộng tiền. Các kiểm tra không tác động database production.
