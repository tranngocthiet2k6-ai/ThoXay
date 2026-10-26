# Thông báo đẩy Firebase Cloud Messaging

Lịch sử thông báo trong PostgreSQL luôn hoạt động, kể cả khi chưa cấu hình
Firebase. Push thật cần một dự án Firebase của bạn; repo không chứa khóa mẫu
và không tự tạo tài khoản/dự án dịch vụ bên ngoài.

## Android và APK trên GitHub Actions

1. Trong [Firebase Console](https://console.firebase.google.com/), thêm ứng dụng
   Android với application ID **vn.thoxay.tho_xay_mobile**.
2. Tải `google-services.json`, đặt tại `mobile_app/android/app/google-services.json`.
   File này được Git bỏ qua. Gradle chỉ bật Google Services plugin khi có file.
3. Với CI, tạo repository Actions secret **FIREBASE_ANDROID_CONFIG_BASE64** chứa
   nội dung file đó được mã hóa Base64. Workflow giải mã trước khi build APK.
   Không đặt service account vào secret này: cấu hình APK chỉ là cấu hình client.
4. Cài APK, đăng nhập, mở **Thông báo → Bật thông báo đẩy**, cấp quyền trên máy.
   Khi chưa có Firebase, APK vẫn build/chạy và màn hình giải thích push chưa sẵn sàng.

Ví dụ lấy Base64 trong PowerShell (chạy trên file cấu hình client của bạn):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('mobile_app/android/app/google-services.json'))
```

FlutterFire 17 dùng Firebase Installation ID qua `register`/`onRegistered`;
Firebase Admin 9.11 gửi tới `fid`. Endpoint vẫn dùng tên `token` để đại diện
đăng ký thiết bị, nhưng giá trị do client gửi là FID. Backend không cung cấp
API đọc các đăng ký này. Khi đổi tài khoản, đăng ký được gắn lại với tài khoản
đang đăng nhập; đăng xuất thu hồi đăng ký trên máy và Backend.

## Backend

Bật Cloud Messaging API cho cùng dự án. Dùng Application Default Credentials
hoặc file service account đặt ngoài Git, ví dụ `.local/firebase-service-account.json`.
Không đưa file này vào Flutter hoặc GitHub artifact.

```powershell
$env:APP_FCM_ENABLED = 'true'
$env:APP_FCM_PROJECT_ID = '<project-id-cua-ban>'
$env:GOOGLE_APPLICATION_CREDENTIALS = (Resolve-Path '.local/firebase-service-account.json').Path
.\scripts\start-local.ps1 -WithFrontend
```

Mặc định `APP_FCM_ENABLED=false`. Thông báo được tạo cùng transaction nghiệp
vụ; rollback không tạo lịch sử/push. Outbox gửi sau commit, thử lại tối đa ba
lần khi lỗi tạm thời, xóa đăng ký không còn hợp lệ, bỏ qua tài khoản bị khóa
hoặc thông báo đã đọc. Lỗi gửi không làm mất lịch sử. Provider nhận yêu cầu
không đồng nghĩa thiết bị chắc chắn đã hiển thị. FCM có thể giao lại; Android
dùng cùng notification tag để hạn chế trùng hiển thị và lịch sử chỉ có một bản.
Thông báo tạo lúc FCM bị tắt không được phát lại hàng loạt khi bật dịch vụ.

## Flutter và nền tảng

- Foreground: hiện nhắc trong ứng dụng và cập nhật lịch sử đang mở.
- Background/terminated: hệ điều hành hiển thị payload notification; bấm mở lịch sử
  khi còn đăng nhập. Payload không chứa nội dung chat hoặc ảnh CCCD.
- Thông báo của phiên cũ được lọc theo user ID trước khi cập nhật UI foreground.
- iOS cần `GoogleService-Info.plist` ở Runner, bật Push Notifications/Remote
  notifications và cấu hình APNs trong Firebase/Xcode. AppDelegate đã nối
  notification delegate cho UIScene. Build iOS cần macOS/Xcode và chứng chỉ của bạn.
- Web hiện hỗ trợ lịch sử trong ứng dụng; push nền của trình duyệt chưa bật.

## API

- `GET /api/notifications?beforeId=<id>&limit=30`: `{items, hasMore, unreadCount}`;
  chỉ dữ liệu người đang đăng nhập, limit 1–100.
- `PUT /api/notifications/{id}/read`, `PUT /api/notifications/read-all`.
- `PUT /api/notifications/devices`, `POST /api/notifications/devices/unregister`:
  body `{"token":"FID từ SDK"}`, trả 204, yêu cầu JWT còn hoạt động.

Sự kiện: đơn mới, duyệt/từ chối, hoàn thành/đánh giá, KYC được duyệt, tin chat mới.
Migration: `migrations/005_notifications.sql`, chạy sau 004 và có thể chạy lại.

Tham khảo chính thức: [Flutter nhận thông báo](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages),
[Firebase Admin setup](https://firebase.google.com/docs/admin/setup),
[gửi tới FID](https://firebase.google.com/docs/cloud-messaging/send/admin-sdk).
