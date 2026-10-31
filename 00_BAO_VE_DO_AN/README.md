# 01. Hồ sơ bảo vệ và demo

Mở [ThoXay-BaoVe.code-workspace](../ThoXay-BaoVe.code-workspace) bằng VS Code
để có đúng sáu phân khu Explorer. Thư mục này tập hợp bản sao tài liệu đã chốt;
file gốc ở `docs/` vẫn giữ nguyên và là nguồn để cập nhật tiếp.

- [Báo cáo Word 81 trang](BAO_CAO_DO_AN.docx).
- [Slide PowerPoint 15 trang, có Speaker Notes](SLIDE_BAO_VE_DO_AN.pptx).
- [Link Web/Admin và 8 tài khoản demo](LINK_VA_8_TAI_KHOAN_DEMO.md).
- [Kịch bản thuyết trình, demo và 20 câu hỏi đáp](KICH_BAN_DEMO_VA_HOI_DAP.md).
- [Bản đồ mở code nhanh theo câu hỏi Hội đồng](BAN_DO_MO_CODE_NHANH.md).
- [Cách hoạt động và cách mở workspace](HUONG_DAN_WORKSPACE.md).

Các số 81 trang/15 slide là phiên bản đã nghiệm thu ngày 30/10/2026. Workspace
được chuẩn bị ngày 01/11/2026; không viết lại nội dung hoặc chuyển đổi Office.
Mở Word/PowerPoint bằng ứng dụng Office để giữ nguyên bố cục và xem Notes.
Trong Markdown Preview (`Ctrl+Shift+V`), bấm vào link để mở file mã nguồn.

Các bản tham chiếu cùng SHA256 được ghi tại [THAM_CHIEU.json](THAM_CHIEU.json).
Khi thay đổi tài liệu hoặc cấu hình gốc, chạy task **Bảo vệ: đồng bộ bản tham chiếu**
hoặc [script chuẩn bị](../scripts/prepare-defense-workspace.ps1) từ thư mục gốc.
Script dừng nếu phát hiện bản tham chiếu đã bị sửa riêng; không ghi đè thay đổi đó.
