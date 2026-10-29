# ThoXay — Phương án redesign Flutter Web & Mobile

Phạm vi: toàn bộ màn hình Flutter dành cho Thợ và Chủ thầu, đăng nhập/đăng ký.
Không thay đổi Web Admin, Backend, API, model dữ liệu hay quy tắc nghiệp vụ.
Checkpoint trước chỉnh sửa: `02a5a2d`.

## 1. Visual Theme & Atmosphere

Phong cách Warm Professional kết hợp bố cục editorial: nền giấy trắng ấm,
chữ mực đậm, đường viền mảnh, nhãn ngắn gọn, thẻ rõ thứ bậc. Biểu tượng
công trình vẽ bằng vector trong Flutter, không phụ thuộc ảnh tải từ mạng.
L2 đã được duyệt: tiêu đề xuất hiện theo lớp, section reveal khi cuộn, nền minh họa parallax nhẹ trên desktop, spotlight card và điều hướng pill chuyển động.

## 2. Color Palette & Roles

| Vai trò màu | Giá trị | Sử dụng |
| --- | --- | --- |
| Worker | #EA580C | CTA, mục chọn, điểm nhấn Thợ |
| Contractor | #059669 | CTA, mục chọn, điểm nhấn Chủ thầu |
| Canvas | #F7F8FA | Nền nội dung |
| Surface | #FFFFFF | Form, thẻ, khung thông tin |
| Ink | #182230 | Tiêu đề, lương, số dư |
| Muted | #64748B | Chú thích |
| Border | #E4E7EC | Phân nhóm nội dung |
| Success / Warning / Error | #15803D / #B45309 / #B42318 | Có cả icon/chữ |

Token Flutter tập trung tại theme; màu web tham chiếu cùng hệ token.
Màu chủ đạo dành cho chi tiết có ý nghĩa, không phủ toàn bộ màn hình.

## 3. Typography Rules

Plus Jakarta Sans, hỗ trợ dấu tiếng Việt, đóng gói font cùng app; fallback
Roboto/sans-serif. Đầu trang 28–36px, tiêu đề khu vực 20–24px, tên công trình
18px, nội dung 14–16px, nhãn 12–13px. Mức lương/số dư dùng số rõ, weight
700–800. Nội dung có thể tăng cỡ chữ; không gradient hay bóng chữ.

## 4. Component Stylings

- Nút: cao tối thiểu 48px, góc 12px; primary nền vai trò, secondary có viền;
  hover tăng tương phản, pressed giảm độ sáng, focus có viền, disabled rõ.
- Card: nền trắng, bo 20px, viền mảnh; header/chi tiết/footer phân tầng;
  hover viền màu vai trò, focus có vòng viền khi card có thể mở.
- Input: nhãn luôn rõ, icon đầu trường, nền xám nhẹ, focus viền màu vai trò,
  lỗi có chữ và icon; giữ nguyên validation/autofill hiện có.
- Navigation: điện thoại dùng thanh đáy, desktop dùng thanh điều hướng ngang
  có nhãn thương hiệu; trạng thái chọn có pill màu nhạt; giữ badge dữ liệu thật.
- Badge: icon + nhãn trạng thái, nền nhạt; không thêm xác thực hoặc số giả.
- Dialog/bottom sheet: tiêu đề rõ, nội dung chia nhóm, nút cuối dễ bấm.

## 5. Layout Principles

Nhịp 8px, gap 12/16/24px; desktop nội dung tối đa 1120px, phần nội dung phụ
có khung cân đối. Auth desktop chia hai cột: giới thiệu thương hiệu và form.
Mobile ưu tiên form và thao tác, tránh banner cao phải cuộn mới đăng nhập.
Trang chủ có lời chào, dải thông tin ngắn, tìm kiếm và card công trình.
Các trang ví, thu nhập, hồ sơ, chat, thông báo, uy tín đều cùng ngôn ngữ hình.

## 6. Depth & Elevation

Nền phẳng; card thường dùng viền và shadow rất nhẹ; card ví/hero có khối mực
đậm và điểm nhấn vai trò; modal tách nền rõ. Không glow hoặc blur nền lớn.

## 7. Animation & Interaction

L2: fade/slide 420ms khi vào viewport, hover 180ms, switch/segmented controls
180ms. Flutter Material làm trạng thái bàn phím/chuột. Giảm/tắt chuyển động
khi hệ thống yêu cầu reduced motion; skeleton không chạy ở route bị che.
Không thêm thư viện WebGL/GSAP hay chuyển động cuộn gây chậm trên điện thoại.

## 8. Do's and Don'ts

- Dùng Material icons hiện có, văn bản tiếng Việt nhất quán.
- Giữ nguyên API, phân quyền, online/offline, GPS, điều kiện chat/nhận việc.
- Giữ dữ liệu thật cho biểu đồ, số dư, KYC, bậc thợ, badge.
- Có empty/error/loading và CTA có tác dụng thật.
- Không thay đổi bất kỳ tệp giao diện Admin nào.
- Không tạo thêm dữ liệu mẫu trong tài khoản thật để trang trông đông hơn.
- Không thêm nút không hoạt động, lời hứa bảo đảm thanh toán hay số liệu giả.
- Không dùng emoji trang trí, gradient chữ, shadow dày hoặc nền màu tràn lan.
- Không hy sinh thao tác bàn phím và cỡ chữ lớn vì bố cục cố định.
- Không đưa ảnh CCCD, token hoặc thông tin bí mật vào screenshot/commit.

## 9. Responsive Behavior

320/390px: một cột, thanh đáy, padding 16px; 768px: tăng padding 24px,
nhóm chi tiết vừa màn hình; 1120px+: bố cục rộng có điều hướng ngang,
card và form giới hạn chiều rộng hợp lý. Mọi mục tương tác tối thiểu 44px,
CTA chính 48px. Kiểm tra keyboard, text scale và không tràn ngang.

Kiểm chứng: Flutter analyze + toàn bộ widget/unit tests + build web release;
kiểm tra ảnh desktop/mobile; diff chứng minh Admin/Backend/API giữ nguyên.
Commit và push từng nhóm hoàn chỉnh sau build thành công theo AGENTS.md.


### Handoff token (CSS tham chiếu; runtime dùng AppColors/ColorScheme)

```css
:root { --bg:#f7f8fa; --bg-rgb:247,248,250; --surface:#fff;
  --text:#182230; --text-secondary:#64748b; --border:#e4e7ec;
  --accent:#ea580c; --accent-rgb:234,88,12; --accent-hover:#c2410c;
  --success:#15803d; --warning:#b45309; --error:#b42318; }
[data-role=contractor] { --accent:#059669; --accent-rgb:5,150,105; --accent-hover:#047857; }
.button { min-height:48px; border-radius:12px; background:var(--accent); transition:background 180ms; }
.button:hover { background:var(--accent-hover); }
.button:active { transform:translateY(1px); }
.button:focus-visible, a:focus-visible, .card:focus-visible { outline:2px solid var(--accent); outline-offset:3px; }
.button:disabled { opacity:.45; cursor:not-allowed; }
.card { border:1px solid var(--border); border-radius:20px; background:var(--surface); }
.card:hover { border-color:var(--accent); }
a { color:var(--accent); text-underline-offset:4px; }
a:hover { text-decoration:underline; }
a:active { color:var(--accent-hover); }
a[aria-disabled=true] { opacity:.45; pointer-events:none; }
.badge { border-radius:10px; padding:6px 10px; background:rgba(var(--accent-rgb),.08); }
.nav-item[aria-current=page] { background:rgba(var(--accent-rgb),.1); color:var(--accent); }
@media(prefers-reduced-motion:reduce) { * { animation:none!important; transition:none!important; } }
```

Font tham chiếu: https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap
Fallback: `Plus Jakarta Sans, Roboto, Arial, sans-serif`.
Nguồn font: https://github.com/google/fonts/tree/main/ofl/plusjakartasans
Giấy phép OFL nằm cùng tệp font trong mobile_app/assets/fonts/.
Flutter đóng gói font để không gọi Google Fonts khi mở app.

### Ánh xạ L2 sang Flutter

| Nhóm | Hiện thực native |
| --- | --- |
| Hero H1 | DesignReveal, heading chia dòng, opacity + translate |
| Section H2 | SectionIntro, chỉ reveal khi đi vào viewport |
| Body / Label | Eyebrow reveal, AnimatedSwitcher cho nhãn trạng thái |
| Element | Material hover/focus/pressed và DesignSurface spotlight |
| Component | Pill navigation, segmented control, dialog/gallery transitions |
| Background | ConstructionArtwork parallax giới hạn 14px, static trên mobile |

Không nhập mã React/Vue vào Flutter. Các hiệu ứng được triển khai native với
Material, TweenAnimationBuilder và CustomPainter; không có ticker nền vô hạn.
Khung hình phụ thuộc cuộn chỉ cập nhật phần minh họa. Không dùng chuyển động
để làm giả trạng thái kết nối, thu nhập hoặc tiến độ công trình.
