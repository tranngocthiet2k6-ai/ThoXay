# Thợ Xây Mobile

Ứng dụng Flutter cho thợ và chủ thầu. Chạy `flutter pub get`, sau đó
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` trên Android emulator.
Chrome và iOS simulator dùng `http://localhost:8080`; thiết bị thật dùng địa chỉ LAN
của máy chạy backend. Bản phát hành dùng API HTTPS.

Kiểm tra bằng `flutter analyze`, `flutter test`, `flutter build web --release`.
Android cần Android SDK; iOS cần macOS và Xcode. Cấu hình Android hiện ký bằng
debug key để chạy demo; dùng upload key riêng khi phân phối qua Play Store.
