# 01. Hồ sơ bảo vệ và demo

Mở [ThoXay-BaoVe.code-workspace](../ThoXay-BaoVe.code-workspace) bằng VS Code
để có đúng sáu phân khu Explorer. Thư mục này tập hợp bản sao tài liệu đã chốt;
file gốc ở `docs/` vẫn giữ nguyên và là nguồn để cập nhật tiếp.

- [01. Báo cáo Word 103 trang](01_BAO_CAO_DO_AN.docx).
- [02. Slide PowerPoint 15 trang, có Speaker Notes](02_SLIDE_BAO_VE_DO_AN.pptx).
- [03. Link Web/Admin/APK và 8 tài khoản demo, gồm Admin](03_TAI_KHOAN_VA_LINK_DEMO.md).
- [04. Kịch bản thuyết trình, demo và 20 câu hỏi đáp](04_KICH_BAN_VA_20_CAU_HOI_DAP.md).
- [05. Bản đồ mở code nhanh theo câu hỏi Hội đồng](05_BAN_DO_MO_CODE_NHANH.md).
- [06. Bộ 20 ảnh giao diện thực thi DEMO](06_ANH_THIET_KE_FIGMA/).
- [Cách hoạt động và cách mở workspace](HUONG_DAN_WORKSPACE.md).

Phiên bản ngày 03/11/2026 bổ sung đủ 20 hình giao diện thực thi DEMO vào báo cáo và slide.
Kiểm kê: 31 bảng/260 cột/114 route; 131 Backend, 119 Flutter, 12 JS và 8 Python pass.
Workspace giữ nguyên sáu phân khu, vị trí code gốc và cấu hình CI/CD.
Mở Word/PowerPoint bằng ứng dụng Office để giữ nguyên bố cục và xem Notes.
Trong Markdown Preview (`Ctrl+Shift+V`), bấm vào link để mở file mã nguồn.

Các bản tham chiếu cùng SHA256 được ghi tại [THAM_CHIEU.json](THAM_CHIEU.json).
Khi thay đổi tài liệu hoặc cấu hình gốc, chạy task **Bảo vệ: đồng bộ bản tham chiếu**
hoặc [script chuẩn bị](../scripts/prepare-defense-workspace.ps1) từ thư mục gốc.
Script dừng nếu phát hiện bản tham chiếu đã bị sửa riêng; không ghi đè thay đổi đó.
