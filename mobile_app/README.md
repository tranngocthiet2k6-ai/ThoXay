# Thợ Xây Mobile

Ứng dụng Flutter cho thợ và chủ thầu. Chạy `flutter pub get`, sau đó
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` trên Android emulator.
Chrome và iOS simulator dùng `http://localhost:8080`; thiết bị thật dùng địa chỉ LAN
của máy chạy backend. Bản phát hành dùng API HTTPS.

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
hiện tại và API mặc định dành cho Android emulator; thiết bị thật cần build với
`--dart-define=API_BASE_URL=<dia-chi-backend>` phù hợp.
