# Thợ Xây — quy tắc thực thi dự án

## Mục tiêu và kiến trúc

Xây dựng đồ án “Ứng dụng Di động Kết nối Lao động Phổ thông & Chủ thầu”.
Backend ở thư mục gốc: Java 17+, Spring Boot 3.x, Maven, Spring Data JPA,
Spring Security, JWT, Lombok, Jakarta Validation. PostgreSQL dùng database
`tho_xay_db`. Web Admin dùng Spring MVC, Thymeleaf và Bootstrap 5.
Ứng dụng Flutter ở `mobile_app/`, gọi REST API bằng JWT, dùng `http`,
`shared_preferences`, `geolocator`. Vai trò: ROLE_WORKER, ROLE_CONTRACTOR,
ROLE_ADMIN. Chỉ cho phép đăng ký công khai vai trò thợ hoặc chủ thầu.

## Thiết kế PostgreSQL

- `users`: `id BIGSERIAL PRIMARY KEY`, `phone_number VARCHAR(15) UNIQUE NOT NULL`,
  `password VARCHAR(255) NOT NULL`, `full_name VARCHAR(100) NOT NULL`,
  `role VARCHAR(30)` (ROLE_WORKER, ROLE_CONTRACTOR, ROLE_ADMIN),
  `is_verified BOOLEAN DEFAULT FALSE`, `cccd_image VARCHAR(500)`,
  `rating DOUBLE PRECISION DEFAULT 5.0`, `is_active BOOLEAN DEFAULT TRUE`,
  `created_at TIMESTAMP`.
- `jobs`: `id BIGSERIAL PRIMARY KEY`, `contractor_id BIGINT REFERENCES users(id)`,
  `title VARCHAR(200) NOT NULL`, `description TEXT`, `job_type VARCHAR(50)`
  (Thợ chính, Phụ hồ), `salary_per_day DOUBLE PRECISION NOT NULL`,
  `address VARCHAR(255) NOT NULL`, `latitude DOUBLE PRECISION NOT NULL`,
  `longitude DOUBLE PRECISION NOT NULL`, `required_workers INTEGER NOT NULL`,
  `status VARCHAR(30) DEFAULT 'OPEN'` (OPEN, IN_PROGRESS, COMPLETED, CANCELLED),
  `created_at TIMESTAMP`.
- `job_applications`: `id BIGSERIAL PRIMARY KEY`, `job_id BIGINT REFERENCES jobs(id)`,
  `worker_id BIGINT REFERENCES users(id)`, `status VARCHAR(30) DEFAULT 'PENDING'`
  (PENDING, ACCEPTED, REJECTED), `applied_at TIMESTAMP`, UNIQUE(job_id, worker_id).

`schema.sql` chứa DDL và dữ liệu mẫu. Mật khẩu mẫu phải được băm BCrypt.
JobRepository tìm việc OPEN bằng truy vấn native Haversine theo lat/lng/radiusKm.
Khóa giao dịch công trình khi duyệt để tránh nhận vượt required_workers;
khi đủ số ACCEPTED, chuyển công trình sang IN_PROGRESS.

## Các tính năng phải hoàn thành theo thứ tự

0. AGENTS.md và .gitignore.
1. Spring Boot, cấu hình PostgreSQL, schema, ba entity và repository.
2. Đăng ký/đăng nhập, DTO, BCrypt, JWT, kiểm soát tài khoản bị khóa.
3. POST /api/jobs, GET /api/jobs/nearby, GET /api/jobs/contractor/{contractorId}.
4. POST /api/applications/apply, GET /api/applications/job/{jobId},
   GET /api/applications/worker/{workerId}, PUT /api/applications/{id}/status.
5. GET /admin/dashboard, POST /admin/users/{id}/verify,
   POST /admin/users/{id}/toggle-active, POST /admin/jobs/{id}/delete.
6. Flutter: API service, đăng nhập, đăng ký, tìm việc GPS và lịch sử của thợ,
   đăng công trình và duyệt ứng viên của chủ thầu. Checkpoint mỗi màn hình.

## Quy trình bắt buộc trong mọi phiên

Đọc file này trước khi sửa dự án. Viết đầy đủ code thực thi cho mỗi hạng mục.
Sau mỗi tính năng mới hoặc sửa đổi (cấu hình, database, API, màn hình, giao diện):

1. Chạy build/compile phù hợp và kiểm tra thành công. Với bước chỉ có tài liệu,
   kiểm tra định dạng bằng `git diff --check`; ghi rõ chưa có mã để biên dịch.
2. Chạy `git add .`.
3. Chạy `git commit -m "feat: <mo ta tinh nang vua hoan thanh>"`.
   Bước 0 dùng `docs: khoi tao AGENTS.md luu quy tac du an va .gitignore`.
4. Chạy `git push origin main` để tạo bản khôi phục GitHub.
5. Chỉ chuyển sang tính năng kế tiếp khi push thành công. Nếu build hoặc push
   thất bại, xử lý lỗi trong hạng mục hiện tại và báo đúng trạng thái.

Không commit bí mật, dữ liệu người dùng, build output hoặc SDK. Cấu hình môi
trường và hướng dẫn chạy phải đủ để người khác chạy lại và kiểm chứng.
