import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const termsSections = <(String, String)>[
  (
    '1. Phạm vi sử dụng',
    'Thợ Xây kết nối người thợ và chủ thầu để tìm công trình, ứng tuyển, thỏa thuận và theo dõi công việc. Mỗi bên chịu trách nhiệm về thông tin cung cấp, năng lực và điều kiện làm việc thực tế. Không tạo tài khoản giả, đăng việc gian dối hoặc sử dụng ứng dụng cho mục đích trái pháp luật.',
  ),
  (
    '2. Tài khoản và định danh',
    'Bảo mật mật khẩu và sử dụng số điện thoại mà bạn có quyền sử dụng. Không chia sẻ mã đăng nhập hoặc ảnh CCCD trong chat. Hồ sơ chỉ hiển thị đã xác thực sau khi Admin đối chiếu đủ hai mặt giấy tờ. Thay đổi thông tin định danh hoặc ảnh CCCD có thể yêu cầu xét duyệt lại.',
  ),
  (
    '3. Cam kết và chấm công',
    'Đọc kỹ mức lương, lịch, địa điểm và quy định hủy trong phiếu cam kết trước khi xác nhận. Ghi nhận GPS/QR và ảnh tiến độ phải phản ánh công việc thực tế; không giả mạo tọa độ hoặc bằng chứng. Chấm công và nghiệm thu là các bước khác nhau; ngày công cần được đối chiếu khi thanh toán.',
  ),
  (
    '4. Ví, ký quỹ và đối soát',
    'Số dư trong ứng dụng là sổ theo dõi giao dịch của hệ thống. Yêu cầu nạp/rút chỉ hoàn tất sau khi Admin đối soát giao dịch thực tế. VietQR hỗ trợ điền thông tin chuyển khoản, không tự xác nhận đã nhận tiền. Kiểm tra ngân hàng, số tiền và mã tham chiếu trước khi chuyển. Khoản đang giữ chỗ không thể rút trùng; ký quỹ và giải ngân theo trạng thái công trình và xác nhận nghiệp vụ.',
  ),
  (
    '5. An toàn và tranh chấp',
    'Ưu tiên an toàn tại công trường. SOS trong ứng dụng gửi cảnh báo nội bộ cho Admin, không thay thế dịch vụ cứu hộ hoặc cuộc gọi khẩn cấp. Khi phát sinh tranh chấp, giữ bằng chứng và gửi qua Trung tâm hỗ trợ; không công khai CCCD, thông tin ngân hàng hoặc dữ liệu riêng của người khác.',
  ),
  (
    '6. Xếp hạng và tài khoản',
    'Đánh giá phải dựa trên công trình thực tế. Điểm uy tín và bậc thợ được tính theo quy tắc của hệ thống; việc hủy đơn có thể làm giảm điểm như thể hiện trước khi xác nhận. Admin có thể khóa tài khoản vi phạm. Bạn có thể gửi yêu cầu xem xét qua Trung tâm hỗ trợ và theo dõi trạng thái xử lý.',
  ),
  (
    '7. Thay đổi và liên hệ',
    'Điều khoản áp dụng cho phiên bản ứng dụng hiện tại. Khi cần giải thích giao dịch, cập nhật dữ liệu hoặc phản ánh hành vi, mở Cài đặt → Trung tâm trợ giúp & SOS → gửi yêu cầu kèm công trình liên quan. Không gửi mật khẩu hoặc mã OTP trong bằng chứng.',
  ),
];
const privacySections = <(String, String)>[
  (
    '1. Dữ liệu được xử lý',
    'Ứng dụng xử lý số điện thoại, họ tên, thông tin nghề nghiệp, ảnh hồ sơ/công trình, hai mặt CCCD khi bạn gửi KYC, tọa độ do bạn chọn hoặc cung cấp khi chấm công, nội dung trao đổi, lịch sử công việc, giao dịch và báo cáo sự cố. Thiết bị có thể đăng ký mã nhận thông báo đẩy nếu bạn cho phép.',
  ),
  (
    '2. Mục đích sử dụng',
    'Dữ liệu phục vụ đăng nhập, kết nối công trình, xét duyệt danh tính, liên lạc khi đã nhận việc, đối chiếu chấm công/tiến độ, xử lý giao dịch, đánh giá uy tín và giải quyết sự cố. Không đưa mật khẩu, OTP hoặc ảnh giấy tờ vào thông tin công khai.',
  ),
  (
    '3. Quyền truy cập thiết bị',
    'Camera/thư viện chỉ được dùng khi bạn chụp hoặc chọn ảnh. Vị trí được yêu cầu cho tìm việc và ghi nhận tại công trường; bạn vẫn có thể chọn khu vực thủ công để tìm việc. Ứng dụng không cần theo dõi vị trí nền để thực hiện các thao tác này. Quyền hệ điều hành có thể thu hồi trong phần Cài đặt của điện thoại.',
  ),
  (
    '4. Phạm vi hiển thị',
    'Hồ sơ nghề nghiệp, ảnh tay nghề và xếp hạng có thể hiển thị cho người dùng liên quan. Số điện thoại liên lạc công trình chỉ được cung cấp cho cặp chủ thầu–thợ có đơn đã duyệt. Hai mặt CCCD được dùng cho xét duyệt nội bộ, không đưa vào hồ sơ nghề nghiệp công khai. Không đăng giấy tờ tùy thân dưới dạng ảnh tay nghề.',
  ),
  (
    '5. Dịch vụ kết nối',
    'Bản đồ tải ô ảnh từ OpenStreetMap; khi mở điều hướng hoặc thanh toán QR, dữ liệu cần thiết như tọa độ hay nội dung chuyển khoản được gửi tới dịch vụ được chọn. Thông báo đẩy dùng Firebase khi đã cấu hình và có quyền thiết bị. Bạn có thể tắt riêng thông báo công việc và tin nhắn trong Cài đặt; lịch sử trong ứng dụng vẫn còn.',
  ),
  (
    '6. Lưu trữ và bảo vệ',
    'Mật khẩu được băm tại máy chủ; phiên đăng nhập được lưu trên thiết bị để mở lại ứng dụng. Đăng xuất gỡ phiên trên thiết bị; đổi mật khẩu thu hồi các JWT cũ. Nhật ký công việc và giao dịch phục vụ đối soát, không bị xóa chỉ vì đăng xuất. Không có cơ chế tự xóa toàn bộ dữ liệu từ nút Đăng xuất.',
  ),
  (
    '7. Yêu cầu về dữ liệu',
    'Bạn có thể sửa hồ sơ và gửi lại CCCD trong mục Thông tin cá nhân & KYC. Để yêu cầu xem, sửa hoặc xem xét xóa dữ liệu khác, gửi yêu cầu qua Trung tâm hỗ trợ & SOS; nêu loại dữ liệu và công trình/giao dịch liên quan, tránh đính kèm lại giấy tờ nếu không cần thiết. Admin phản hồi tại mục Sự cố & khiếu nại.',
  ),
];

Future<void> showLegalInformation(
  BuildContext context, {
  required bool privacy,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => FractionallySizedBox(
    heightFactor: .88,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  privacy ? 'Chính sách bảo mật' : 'Điều khoản sử dụng',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                'Thợ Xây • Phiên bản chính sách 1.0',
                style: TextStyle(
                  color: AppPalette.of(context).muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              for (final section
                  in privacy ? privacySections : termsSections) ...[
                Text(
                  section.$1,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  section.$2,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ],
    ),
  ),
);
