# Workspace thuyết trình sáu phân khu

1. Mở `ThoXay-BaoVe.code-workspace` ở thư mục gốc bằng **File → Open Workspace from File**.
2. Explorer hiển thị sáu mục đã đánh số, theo đúng thứ tự thuyết trình.
3. Mở Markdown Preview và dùng các link ở bản đồ code để đi thẳng tới file gốc.
4. Dùng **Terminal → Run Task** để chạy test, build hoặc demo từ đúng thư mục.

| Phân khu | Đường dẫn thật |
| --- | --- |
| 01. HỒ SƠ BẢO VỆ & DEMO | `00_BAO_VE_DO_AN` |
| 02. BACKEND & WEB ADMIN (Spring Boot) | `src/main` |
| 03. MOBILE & WEB APP (Flutter) | `mobile_app/lib` |
| 04. CƠ SỞ DỮ LIỆU (PostgreSQL) | `migrations` |
| 05. TRIỂN KHAI CLOUD (Render & Vercel) | `cloud_deploy` |
| 06. KIỂM THỬ TỰ ĐỘNG (Tests) | `kiem_thu`, gồm hai liên kết tới `src/test` và `mobile_app/test` |

Mỗi root của VS Code chỉ có một `path`. Hai junction cục bộ trong khu 06 giúp
mở trực tiếp cả hai cây test thật trong một root, không sao chép hoặc di chuyển
code. Chỉnh sửa một file qua liên kết cũng sửa chính file test gốc: chỉ dùng để
mở xem khi bảo vệ. Junction không được Git lưu; sau khi clone sang máy Windows
khác, chạy `./scripts/prepare-defense-workspace.ps1` để tạo lại đúng đích trong repo.
Không xóa đệ quy qua liên kết. Các link Markdown tại khu 06 vẫn mở được file gốc
ngay cả khi chưa tạo junction.

`src/`, `mobile_app/`, `pom.xml`, Dockerfile, render.yaml, vercel.json và workflow
gốc vẫn ở đúng vị trí cũ. CI chỉ đọc các đường dẫn gốc, không đọc các bản cloud
tham chiếu. Maven vẫn lấy `pom.xml` ở root; Flutter vẫn lấy `mobile_app/pubspec.yaml`.
Không chạy build tại `src/main` hoặc `mobile_app/lib`. Workspace ưu tiên Explorer
cho thuyết trình; khi cần IDE tự phát hiện dự án Maven/Flutter đầy đủ, có thể mở
lại root `ThoXay` như trước. Các task ở workspace đã đặt working directory đúng.

`files.exclude` chỉ ẩn mục trong Explorer, không xóa file hoặc đổi cấu hình build.
Nó có mặt ở cả `.vscode/settings.json` (khi mở root) và settings trong workspace
(khi mở sáu root). Junction được Git bỏ qua nhưng vẫn hiển thị vì
`explorer.excludeGitIgnore` được tắt; các cache vẫn bị ẩn bởi `files.exclude`.
Không có task tự chạy, không tự cài extension, không đổi thiết lập VS Code toàn máy.

Tài liệu VS Code: [Multi-root Workspaces](https://code.visualstudio.com/docs/editing/workspaces/multi-root-workspaces).
Liên kết thư mục dùng [New-Item Junction của PowerShell](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-item).
