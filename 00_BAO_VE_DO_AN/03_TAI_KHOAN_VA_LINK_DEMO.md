# Link trình diễn và 8 tài khoản mẫu

## Production

| Mục | Địa chỉ |
| --- | --- |
| Flutter Web | https://thoxay.vercel.app |
| API Spring Boot | https://thoxay-api.onrender.com |
| Web Admin | https://thoxay-api.onrender.com/admin/login |
| Readiness và kết nối database | https://thoxay-api.onrender.com/health |
| APK release mới nhất | [GitHub Actions Build APK](https://github.com/tranngocthiet2k6-ai/ThoXay/actions/workflows/build-apk.yml) → run `main` thành công → Artifacts |

APK tải tự động trên máy được lưu tại `.local/releases/` sau khi xác minh artifact;
không commit file APK/build output. APK release mặc định gọi HTTPS Render.

Production dùng tài khoản thật đã được cấp quyền. Các tài khoản trong bảng dưới
chỉ có ở database demo riêng; APK release mặc định kết nối production Render.
Render Free có thể cần thời gian khởi động sau khi ngủ; không bấm gửi giao dịch liên tục.

## Demo cục bộ có dữ liệu bảo vệ

| Mục | Địa chỉ |
| --- | --- |
| Web responsive Thợ/Chủ thầu | http://127.0.0.1:3008 |
| Web Admin | http://127.0.0.1:18083/admin/login |
| API/Readiness | http://127.0.0.1:18083/health |
| Database | `thoxay_defense_demo`, PostgreSQL loopback `55433` |

| Vai trò | Họ tên mẫu | Số điện thoại đăng nhập |
| --- | --- | --- |
| Admin | [DEMO] Quản trị trình diễn | 000106000000 |
| Chủ thầu | [DEMO] Xây dựng Minh Thành | 000106000001 |
| Chủ thầu | [DEMO] Kiến trúc An Gia | 000106000002 |
| Thợ | [DEMO] Nguyễn Minh An | 000106000003 |
| Thợ | [DEMO] Trần Quốc Bảo | 000106000004 |
| Thợ | [DEMO] Lê Hoàng Phúc | 000106000005 |
| Thợ | [DEMO] Phạm Văn Sơn | 000106000006 |
| Thợ | [DEMO] Đỗ Thanh Tâm | 000106000007 |

Mật khẩu demo ngẫu nhiên đã có trên máy tại
[tệp truy cập riêng](../.local/demo/access.md). Không đưa mật khẩu vào tài liệu
được commit, ảnh chụp hay nội dung trình chiếu. Dùng các phiên trình duyệt riêng
cho Thợ, Chủ thầu và Admin. Tên, CCCD, giao dịch và công trình đều là dữ liệu tổng hợp.

Khởi động bằng task **Bảo vệ: khởi động demo đã build** hoặc chạy
`./scripts/start-demo.ps1 -SkipBuild` từ thư mục gốc. Nếu chưa build lần đầu,
chạy không có `-SkipBuild`. Hướng dẫn đầy đủ tại [DEMO.md](../docs/DEMO.md).
VietQR mẫu chỉ dựng payload để minh họa, **không chuyển tiền thật**.

## Bộ hồ sơ đã đánh số

Mở [workspace bảo vệ](../ThoXay-BaoVe.code-workspace). Ngăn đầu chứa báo cáo
`01_BAO_CAO_DO_AN.docx` 103 trang sau đợt Commercial UI, slide
`02_SLIDE_BAO_VE_DO_AN.pptx` 15 trang có Speaker Notes, kịch bản 20 câu hỏi,
bản đồ mở code nhanh và `06_ANH_THIET_KE_FIGMA/` với đủ 20 PNG chụp giao diện DEMO.
Số liệu kiểm thử: 131 Backend, 119 Flutter, 12 JS và 8 Python pass.
Danh sách 8 tài khoản phía trên **đã gồm một Admin**; không có tài khoản thứ chín.
