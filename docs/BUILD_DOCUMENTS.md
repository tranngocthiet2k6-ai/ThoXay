# Tái tạo và kiểm tra tài liệu bảo vệ

Số liệu nghiệp vụ nằm trong `PROJECT_INVENTORY.json`: 30 bảng, 256 cột,
28 Controller, 90 endpoint dưới `/api/` và 21 route HTTP khác. Catalog được đọc
sau Flyway V21, không lấy thông tin cá nhân hoặc số dư người dùng làm báo cáo.

```powershell
# Python có psycopg; truy vấn catalog chỉ đọc, mặc định database QA loopback.
& '.tools/postgres/pgsql/pgAdmin 4/python/python.exe' scripts/report_inventory.py
& '.tools/postgres/pgsql/pgAdmin 4/python/python.exe' scripts/generate_report.py
node scripts/render-report-diagrams.mjs
& '.tools/postgres/pgsql/pgAdmin 4/python/python.exe' scripts/export-report-docx.py
.\scripts\render-office.ps1 -InputFile docs/BAO_CAO_DO_AN.docx `
  -OutputDirectory .local/report-qa -UpdateFields
.\scripts\rasterize-pdf-windows.ps1 `
  -InputFile .local/report-qa/BAO_CAO_DO_AN.pdf `
  -OutputDirectory .local/report-qa/pages
& '.tools/postgres/pgsql/pgAdmin 4/python/python.exe' scripts/validate-report.py
```

Trình xuất Word viết OOXML trực tiếp với Times New Roman 13, dòng 1.5, A4,
bảng có viền, header lặp và mục lục tự cập nhật bằng Word. Dòng chứa riêng hình
dùng khoảng dòng đơn để hình không vượt chiều cao trang. Kiểu PostgreSQL trong
Word dùng các alias chính xác `varchar`, `timestamp`, `timestamptz`; bản Markdown
và JSON giữ chuỗi kiểu do catalog trả về. Khóa ghép được ghi rõ `UNIQUE nhóm` và
liệt kê đầy đủ cột trong ràng buộc sau bảng.

Mermaid và Playwright chạy hoàn toàn cục bộ. Renderer dùng thư viện Mermaid tại
`.tools/report-validation/node_modules`; Playwright có thể resolve từ Node
runtime hiện có. `docs/diagrams/manifest.json` ghi hash mã Mermaid và hash PNG,
giúp kiểm chứng ảnh đúng phiên bản. Mọi khối Mermaid phải có marker duy nhất.
Python export cần Pillow và markdown-it-py. Không commit các SDK/dependency này.

Máy Windows thực hiện có Microsoft Word. `render-office.ps1` tạo một instance
automation riêng, cập nhật mục lục và dùng SaveAs2 để tạo PDF QA. Nó chỉ đóng
tài liệu/instance của mình. Bộ raster dùng Windows.Data.Pdf nên không cần dịch vụ
chuyển đổi online. PDF và ảnh từng trang trong `.local` chỉ phục vụ kiểm tra,
không phải đầu ra phát hành. Bản Word trước đợt cập nhật được giữ tại
`.local/final-delivery/BAO_CAO_DO_AN.before.docx` trên máy thực hiện.

Không tuyên bố PDF đã được kiểm tra nếu chỉ chạy XML validator. Quy trình chốt
gồm mở PNG của các trang để rà ngắt trang, viền bảng, cột dài, sơ đồ và chú thích,
sau đó sửa nguồn và render lại nếu cần. Không chỉnh migration hoặc logic nghiệp vụ
chỉ để khớp số liệu trình bày.
