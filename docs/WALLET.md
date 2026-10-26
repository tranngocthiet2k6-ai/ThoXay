# Ví, ký quỹ và thu nhập

Phiên bản này quản lý sổ ví nội bộ VND và đối soát thủ công. Chưa tích hợp
cổng nạp tiền hoặc tự động chuyển tiền tới ngân hàng. Không có dữ liệu tiền
mẫu được cộng vào tài khoản người dùng. Ví được tạo với số dư 0 khi dùng lần đầu.

## Cách sử dụng

- Thợ: menu biểu tượng ví ở màn hình chính → **Thu nhập** hoặc **Ví điện tử**.
- Chủ thầu: menu ví → **Ví điện tử**. Công trình COMPLETED có nút
  **Thanh toán thu nhập** cho các thợ ACCEPTED còn lại.
- Admin: **Đối soát Ví** tại dashboard hoặc `/admin/wallet`.

**Nạp:** người dùng chuyển tiền theo hướng dẫn nhận tiền của đơn vị vận hành,
gửi yêu cầu có số tiền và mã/nội dung chuyển khoản. Yêu cầu PENDING chưa cộng
số dư. Admin kiểm tra chứng từ/tiền thực nhận, đánh dấu đã đối soát và nhập mã
giao dịch ngân hàng thực tế để duyệt. Mã này được chuẩn hóa và không dùng lại
cho yêu cầu khác. Nếu không khớp, Admin từ chối và ghi lý do.

**Rút:** nhập ngân hàng, số tài khoản, tên chủ tài khoản và số tiền. Số tiền
chuyển ngay từ khả dụng sang tiền giữ chỗ. Admin thực hiện chuyển tiền ngoài
ứng dụng rồi xác nhận mã giao dịch; lúc đó số giữ chỗ được trừ. Từ chối hoàn
đúng tiền giữ chỗ về khả dụng. Việc duyệt không gọi ngân hàng hoặc tự chuyển tiền.

**Ký quỹ:** chuyển qua lại giữa số dư chính và ký quỹ. Cảnh báo mặc định khi
dưới 200.000đ, đổi bằng `APP_WALLET_MINIMUM_ESCROW`. Đây là khoản dự phòng do
người dùng quản lý; hiện chưa khóa theo từng công trình, chưa thu tiền phạt và
chưa chặn trạng thái Online. Chuyển ký quỹ không được tính là thu nhập.

**Thu nhập:** sau khi công trình hoàn thành và chốt sao, chủ thầu xác nhận số
ngày công (1–365), tip, thưởng cho từng thợ rồi thanh toán từ ví của mình.
Đơn giá lấy từ công trình, làm tròn HALF_UP tới VND; Backend tự tính
`tiền công = đơn giá × số ngày`, cộng tip/thưởng. Không tự suy diễn số ngày
từ ngày đăng việc hoặc cộng tiền chỉ vì bấm hoàn thành. Không truy lĩnh tiền
cho công trình cũ. Khoản đã thanh toán không sửa hoặc thanh toán lần hai.

Thống kê Ngày/Tuần/Tháng chỉ cộng WORK_EARNING, TIP, BONUS đã vào ví. Tuần bắt
đầu thứ Hai, múi giờ `Asia/Ho_Chi_Minh`, mốc cuối không bao gồm. Tiền nạp,
tiền rút và chuyển ký quỹ không tăng thu nhập. Xóa bài công trình bởi Admin
giữ nguyên khoản đã thanh toán và lịch sử; không tự đảo bút toán tiền.

## API (JWT)

| API | Chức năng |
| --- | --- |
| `GET /api/wallet` | Số dư khả dụng, ký quỹ, giữ rút, cảnh báo |
| `GET /api/wallet/transactions` | Sổ biến động số dư, phân trang beforeId/limit |
| `GET /api/wallet/requests` | Yêu cầu nạp/rút của chính tài khoản |
| `POST /api/wallet/requests` | Tạo TOP_UP hoặc WITHDRAW chờ đối soát |
| `POST /api/wallet/escrow` | Chuyển LOCK / RELEASE ký quỹ |
| `GET /api/wallet/earnings?period=DAY\|WEEK\|MONTH&date=2026-10-27` | Thống kê của chính thợ |
| `POST /api/wallet/job-payments` | Chủ công trình thanh toán theo applicationId, workDays, tip, bonus |
| `GET /api/wallet/jobs/{id}/payments` | Chủ công trình xem các khoản đã thanh toán |
| `GET /api/admin/wallet/requests` | Admin xem yêu cầu PENDING |
| `POST /api/admin/wallet/requests/{id}/review` | Admin APPROVE / REJECT |

Ví dụ tạo yêu cầu rút:

```json
{"kind":"WITHDRAW","amount":100000,"clientRequestId":"unique-retry-id-123",
 "bankName":"Tên ngân hàng","bankAccount":"1234567890","accountName":"CHU TAI KHOAN"}
```

TOP_UP dùng `transferReference` thay cho thông tin ngân hàng nhận. Chuyển ký
quỹ dùng `direction`, `amount`, `clientRequestId`. Duyệt dùng `decision`,
`externalReference`, `confirmed:true` cho APPROVE; REJECT cần `note` nêu lý do.
API tiền yêu cầu số nguyên VND, mỗi nạp/rút/chuyển ký quỹ 1.000–100.000.000đ,
tip/thưởng 0–100.000.000đ, tổng số dư tối đa 1.000 tỷ VND. Dùng BIGINT/long,
không dùng double cho số dư. Trường số nguyên không nhận JSON số thập phân.

Khóa công trình trước khi thanh toán, khóa tài khoản và ví theo thứ tự ID;
kiểm tra số dư và ghi sổ cùng transaction. Yêu cầu/chuyển ký quỹ có
`clientRequestId` để gửi lại an toàn. Giữ cùng mã khi thử lại sau timeout;
dùng lại mã với nội dung khác trả 409. Flutter giữ mã trong dialog khi thử lại.
Lịch sử riêng tư, dữ liệu ngân hàng chỉ tài khoản sở hữu và Admin được xem.
Trang Admin yêu cầu CSRF và có thao tác xác nhận đối soát thực tế.

## Database và cấu hình

Áp dụng `migrations/010_wallet_earnings.sql` sau 009. Các bảng:
`wallet_accounts`, `wallet_requests`, `wallet_entries`, `job_payments`.
`schema.sql` có DDL tạo mới; script local áp dụng migration theo thứ tự.
Migration chạy lại an toàn và không reset số dư, không sinh giao dịch tiền.
