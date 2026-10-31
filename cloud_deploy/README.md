# 05. Triển khai cloud: bản tham chiếu phục vụ bảo vệ

**Không sửa hoặc chạy deploy từ các bản sao ở thư mục này.** Cấu hình thật vẫn
ở root và `.github/workflows/`; các file dưới đây được sao chép nguyên byte.

| Bản mở nhanh | Nguồn mà hệ thống thực sự dùng |
| --- | --- |
| [Dockerfile](Dockerfile) | [Dockerfile gốc](../Dockerfile) |
| [render.yaml](render.yaml) | [render.yaml gốc](../render.yaml) |
| [vercel.json](vercel.json) | [vercel.json gốc](../vercel.json) |
| [Build APK](.github/workflows/build-apk.yml) | [Workflow gốc](../.github/workflows/build-apk.yml) |
| [Kiểm tra cloud](.github/workflows/deployment-checks.yml) | [Workflow gốc](../.github/workflows/deployment-checks.yml) |

## Giải thích luồng triển khai

Push lên `main` kích hoạt GitHub Actions: kiểm tra migration trên PostgreSQL 17,
build/test container Java 17, build/analyze/test Flutter Web và tạo APK release.
APK dùng API HTTPS Render và được lưu dưới artifact `tho-xay-release-apk`.
Workflow CI và các lượt deploy của dịch vụ cloud là những tiến trình riêng; phải
kiểm tra kết quả run/deploy, không suy luận deploy thành công chỉ từ git push.

Vercel chạy [build-vercel.mjs](../scripts/build-vercel.mjs), phục vụ đầu ra
`mobile_app/build/web`. `API_BASE_URL` lấy từ cấu hình môi trường Vercel;
rewrite trả về index.html để Flutter xử lý điều hướng.

Render chạy Spring Boot bằng image hai stage: JDK để verify/build, JRE để chạy
bằng user không phải root. Backend cung cấp REST JWT, WebSocket và Thymeleaf Admin.
PostgreSQL managed lưu dữ liệu; Flyway nâng cấp schema và production dùng JPA
validate. `/health` kiểm tra SELECT 1. `render.yaml` là Blueprint tham chiếu;
dịch vụ hiện hành còn có settings/secret files trên Render, không được suy đoán
toàn bộ cấu hình đang chạy chỉ từ file Blueprint.

JWT secret, database password và Firebase service account không nằm trong các bản
sao này. Demo local tách biệt production. Các file gốc, đường dẫn Docker COPY,
Flutter output và workflow `.github/workflows` đều không thay đổi do workspace.

Xem [DEPLOY_VERCEL.md](../docs/DEPLOY_VERCEL.md),
[DATABASE_MIGRATIONS.md](../docs/DATABASE_MIGRATIONS.md) và
[manifest SHA256](../00_BAO_VE_DO_AN/THAM_CHIEU.json).
