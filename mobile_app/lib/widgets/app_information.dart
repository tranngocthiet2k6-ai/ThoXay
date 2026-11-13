import 'package:flutter/material.dart';

/// Flutter injects these defines from pubspec/build-name/build-number in release.
abstract final class AppRelease {
  static const name = String.fromEnvironment(
    'FLUTTER_BUILD_NAME',
    defaultValue: '1.0.0',
  );
  static const number = String.fromEnvironment(
    'FLUTTER_BUILD_NUMBER',
    defaultValue: '1',
  );
  static const label = '$name+$number';
}

Future<void> showDataInformation(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Quyền truy cập & dữ liệu'),
    scrollable: true,
    content: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vị trí', style: TextStyle(fontWeight: FontWeight.w700)),
        Text(
          'GPS dùng để tìm công trình gần bạn, chia sẻ vị trí khi xác nhận gửi và kiểm tra chấm công. Bạn có thể chọn vị trí tìm việc bằng tay; chấm công vẫn cần GPS hợp lệ hoặc mã ca làm.',
        ),
        SizedBox(height: 16),
        Text('Camera & ảnh', style: TextStyle(fontWeight: FontWeight.w700)),
        Text(
          'Ảnh CCCD dùng để quản trị viên đối chiếu danh tính. Ảnh công trình dùng trong hồ sơ tay nghề, báo cáo và tin nhắn. Kiểm tra ảnh trước khi xác nhận tải lên.',
        ),
        SizedBox(height: 16),
        Text(
          'Thông tin liên hệ',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          'Số điện thoại trao đổi công việc chỉ hiển thị cho cặp thợ và chủ thầu có đơn đã được duyệt. Không chia sẻ mật khẩu, mã OTP hoặc ảnh giấy tờ trong chat.',
        ),
        SizedBox(height: 16),
        Text(
          'Đây là giải thích tính năng trong ứng dụng, không thay thế chính sách quyền riêng tư hoặc điều khoản dịch vụ.',
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  ),
);
