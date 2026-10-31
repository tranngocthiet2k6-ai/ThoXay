# Tham chiếu schema 30 bảng

[schema.sql](schema.sql) là bản sao nguyên byte của [schema.sql gốc](../../schema.sql)
để mở xem ngay trong phân khu Cơ sở dữ liệu. Không chạy bản sao này như một
migration mới. Flyway runtime chỉ đọc `src/main/resources/db/migration`;
`migrations/` là các script nâng cấp tham khảo/thủ công của dự án.

Nguồn đối chiếu: [30 bảng và từ điển dữ liệu](../../docs/BAO_CAO_DO_AN.md),
[catalog/API inventory](../../docs/PROJECT_INVENTORY.json) và
[hướng dẫn migration](../../docs/DATABASE_MIGRATIONS.md).
Đồng bộ lại bằng [prepare-defense-workspace.ps1](../../scripts/prepare-defense-workspace.ps1).
