# Bộ tham chiếu 16 màn hình ThoXay

Nguồn: 16 PNG người dùng cung cấp tại Downloads ngày 02/11/2026. Ảnh được sao chép
nguyên byte, giữ nguyên tên; ba màn hình Hồ sơ, Tìm việc và Ví tiền của Thợ dùng
dấu `·` trong tên. `Untitled.zip` được giữ nguyên ở Downloads, không đưa vào repo.
Hash SHA256, kích thước byte và tên gốc có trong [manifest.json](manifest.json).
Bản trình chiếu đồng nhất ở `00_BAO_VE_DO_AN/06_ANH_THIET_KE_FIGMA/`.

Tất cả 16 ảnh đã được mở trực tiếp để đối chiếu. PNG là tài liệu thiết kế, không
phải ảnh chụp ứng dụng đang chạy và không được dùng làm nền giả giao diện tương tác.
Giá trị số, tên, hình ảnh hồ sơ/công trường và trạng thái trong app lấy từ API.

| Nhóm | Màn hình tham chiếu | Điểm bố cục |
| --- | --- | --- |
| Thợ | Đăng nhập & Vai trò | Logo nhỏ, hai thẻ vai trò ngang, form đăng nhập |
| Thợ | Tìm việc | Lời chào, tìm kiếm/chips, bản đồ preview, job card lương nổi bật |
| Thợ | Chi tiết việc | Thông tin, vị trí, thương lượng, thanh hành động cuối |
| Thợ | Việc của tôi & Chấm công | Lịch tuần, ca làm, GPS/QR, ảnh cuối ngày, SOS |
| Thợ | Ví tiền | Số dư, ký quỹ, biểu đồ tuần, lịch sử giao dịch |
| Thợ | Nạp ví VietQR | Mệnh giá nhanh, QR thật từ yêu cầu, nội dung đối soát |
| Thợ | Hồ sơ | Thông tin, ba thống kê, uy tín, tay nghề, KYC hai mặt |
| Thợ | Trò chuyện | Đối tác, công trình/cam kết ghim, bong bóng, input cố định |
| Thợ | Bảng xếp hạng | Podium thứ tự 2–1–3, hạng hiện tại và danh sách |
| Chủ thầu | Đăng việc | Ba thống kê thực, CTA đăng, bản đồ, công trình |
| Chủ thầu | Tạo công trình mới | Form nhóm trường, lịch, vị trí, dự toán và CTA |
| Chủ thầu | Duyệt thợ | Công trình, lọc đơn, hồ sơ/uy tín/portfolio, duyệt |
| Chủ thầu | Nghiệm thu | Ca/ảnh, trạng thái duyệt, đánh giá và thanh toán |
| Chủ thầu | Ví & Quỹ lương | Số dư, ký quỹ, chi trả có dữ liệu và lịch sử |
| Chủ thầu | Hồ sơ & Thợ ruột | Thông tin/KYC, danh sách thợ đã lưu, liên hệ theo quyền |
| Chủ thầu | Trò chuyện & Cam kết | Cam kết ghim, bong bóng xanh, ảnh và vị trí |

Thiết kế sáng dùng nền #F8FAFC, surface #FFFFFF, viền #E2E8F0, bán kính 12–16px;
Thợ #EA580C/#FFF7ED, Chủ thầu #059669/#ECFDF5. Chế độ Tối/Outdoor, giảm chuyển
động, responsive và các tính năng bổ sung hiện có tiếp tục được hỗ trợ.

Quy tắc dữ liệu được giữ: GPS 200m/accuracy 100m; QR 5 phút; KYC do Admin duyệt;
VietQR không tự cộng tiền; job posting không tự khóa quỹ lương; escrow đang có là
số dư ký quỹ tài khoản. Không hiển thị phần trăm đúng hẹn, số tin đã xem hoặc vị
trí chấm công giả. Điểm uy tín và bậc nghề không thay bằng số/hạng mẫu trong ảnh.
