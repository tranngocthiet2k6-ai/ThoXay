# Thợ Xây Mobile

Ứng dụng Flutter cho thợ và chủ thầu. Chạy `flutter pub get`, sau đó `flutter run`.
API mặc định là `http://192.168.1.16:8080`; các endpoint tự thêm tiền tố `/api`.
Điện thoại cần cùng mạng LAN với máy chạy backend và truy cập được cổng 8080.
Android cho phép HTTP tới riêng `192.168.1.16` qua `network_security_config.xml`.
Có thể đổi API bằng `--dart-define=API_BASE_URL=https://api.example.com`.

Kiểm tra bằng `flutter analyze`, `flutter test`, `flutter build web --release`.
Android cần Android SDK; iOS cần macOS và Xcode. Cấu hình Android hiện ký bằng
debug key để chạy demo; dùng upload key riêng khi phân phối qua Play Store.

## Tải APK từ GitHub Actions

Workflow `.github/workflows/build-apk.yml` tự chạy khi push lên `main`, hoặc chạy
thủ công bằng **Actions → Build Flutter APK → Run workflow**. Workflow dùng Java
17 và Flutter 3.47.8, chạy `flutter pub get` và `flutter build apk --release`
trong `mobile_app/` trên Ubuntu.

Khi lần chạy thành công, mở phần **Artifacts**, tải `tho-xay-release-apk` và giải
nén để lấy `app-release.apk`. Artifact được giữ 30 ngày. APK dùng cấu hình ký demo
hiện tại và API mặc định `http://192.168.1.16:8080` được tích hợp từ mã nguồn.
