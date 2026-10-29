# Migration tự động với Flyway

Spring Boot chạy Flyway trước khi khởi tạo JPA. Production dùng `ddl-auto=validate`;
không dùng Hibernate để thay thế migration. Spring SQL init production đã tắt,
vì Flyway chịu trách nhiệm tạo schema mới và nâng cấp schema cũ.

## Database hiện có

Database ThoXay đã hoàn thành migration 002–011 nhưng chưa có bảng lịch sử Flyway
được baseline tại phiên bản **11**. Dữ liệu tài khoản, ví, KYC và công trình được giữ.
Migration tiếp theo dùng V12 trở lên trong `src/main/resources/db/migration/`.
Flyway không chạy lại V1 trên database cũ. Không đổi checksum migration đã phát hành.

Nếu dùng bản database cũ hơn 011, hoàn thành các migration legacy 002–011 trước
khi khởi chạy bản có Flyway; không tự gán baseline cho schema chưa đầy đủ.

## Database mới

V1 tạo schema nền, không có seed tài khoản/demo. Sau đó Flyway chạy các bản
nâng cấp mới theo số phiên bản. Không cần bật `DB_INIT_MODE=always`; biến legacy
này không còn điều khiển việc khởi tạo schema production.

Mỗi migration mới phải tương thích dữ liệu hiện có, có default/backfill khi
cần và không xóa dữ liệu vận hành. Tệp V1 là snapshot nền cố định, không đồng
bộ lại từ schema.sql sau khi phát hành.

## Kiểm chứng PostgreSQL

`MigrationCompatibilityTest` chỉ được chạy khi có URL QA riêng chứa
`thoxay_upgrade_qa`. Test tạo schema `qa_<UUID>` riêng, kiểm tra fresh/legacy/
repeat, sau đó chỉ xóa schema do chính test tạo. Không trỏ URL này tới database app.

```powershell
$env:THOXAY_PG_TEST_URL='jdbc:postgresql://127.0.0.1:55433/thoxay_upgrade_qa'
# THOXAY_PG_TEST_USER / THOXAY_PG_TEST_PASSWORD được đọc từ môi trường khi cần.
.\mvnw.cmd -B verify
```

Khi server local đang giữ JAR trên Windows, dùng thư mục build QA riêng:

```powershell
.\mvnw.cmd -B '-Dthoxay.build.directory=.local/advanced-target' verify
```

Lệnh này vẫn test và đóng gói JAR thực thi đầy đủ, không cần dừng server local.

GitHub Actions có PostgreSQL 17 tạm cho cùng bộ test. Test Spring/H2 thông thường
tắt Flyway và để Hibernate tạo schema test; test PostgreSQL kiểm chứng SQL thật.
Flyway clean bị vô hiệu hóa. Khi deploy migration lớn, chuẩn bị bản sao lưu
theo hạ tầng vận hành trước khi nâng cấp; không dùng clean trên database thật.

## V12 — Lịch và cam kết

Bổ sung lịch công trình, lương đề xuất/chốt, phiên bản/xác nhận và snapshot cam kết,
ngày bận riêng của thợ. Đơn ACCEPTED cũ chỉ backfill lương từ giá công trình;
không tự ghi thời điểm đồng ý hoặc nội dung hợp đồng. Ngày công trình cũ để NULL.
Bản SQL chạy thủ công tương ứng: `migrations/012_schedule_offers_commitments.sql`.
