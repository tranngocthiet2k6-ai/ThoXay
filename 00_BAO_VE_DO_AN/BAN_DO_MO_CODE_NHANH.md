# Bản đồ mở code nhanh khi Hội đồng hỏi

Mở Preview bằng `Ctrl+Shift+V` rồi bấm tên file. Tất cả link trỏ về file gốc,
không trỏ đến bản sao dùng trình chiếu. Bắt đầu từ Controller, mở Service để
giải thích nghiệp vụ và mở test để chứng minh ca được kiểm tra.

## Xác thực, quyền và dữ liệu cá nhân

| Câu hỏi | File cần mở |
| --- | --- |
| Chạy ứng dụng Spring Boot từ đâu? | [ThoXayApplication.java](../src/main/java/vn/thoxay/ThoXayApplication.java), [pom.xml](../pom.xml) |
| JWT, session Admin và CSRF được phân tách ra sao? | [SecurityConfig.java](../src/main/java/vn/thoxay/security/SecurityConfig.java) |
| Khóa tài khoản có chặn JWT cũ không? | [JwtAuthenticationFilter.java](../src/main/java/vn/thoxay/security/JwtAuthenticationFilter.java), [AuthService.java](../src/main/java/vn/thoxay/service/AuthService.java), [AuthApiTest.java](../src/test/java/vn/thoxay/AuthApiTest.java) |
| Có kiểm tra người dùng đang đăng nhập và quyền sở hữu không? | [CurrentUser.java](../src/main/java/vn/thoxay/security/CurrentUser.java), [ChatAccessService.java](../src/main/java/vn/thoxay/service/ChatAccessService.java) |
| KYC hai mặt, ảnh riêng tư và Admin duyệt ở đâu? | [KycPhotosApiTest.java](../src/test/java/vn/thoxay/KycPhotosApiTest.java), [admin-dashboard.html](../src/main/resources/templates/admin-dashboard.html), [kyc_camera.dart](../mobile_app/lib/services/kyc_camera.dart), [profile_screen.dart](../mobile_app/lib/screens/profile_screen.dart) |
| Chứng minh kiểm tra lightbox KYC | [admin-kyc.test.cjs](../scripts/tests/admin-kyc.test.cjs) |

## Công trình, bản đồ, lịch và tổ đội

| Câu hỏi | File cần mở |
| --- | --- |
| Tìm việc gần bằng Haversine | [JobRepository.java](../src/main/java/vn/thoxay/repository/JobRepository.java), [JobService.java](../src/main/java/vn/thoxay/service/JobService.java), [JobApiTest.java](../src/test/java/vn/thoxay/JobApiTest.java) |
| Ghim lương, chọn tọa độ và chỉ đường | [jobs_map.dart](../mobile_app/lib/widgets/jobs_map.dart), [location_picker_screen.dart](../mobile_app/lib/screens/location_picker_screen.dart), [job_utilities.dart](../mobile_app/lib/widgets/job_utilities.dart) |
| Tránh nhận quá số thợ cần tuyển | [ApplicationService.java](../src/main/java/vn/thoxay/service/ApplicationService.java), [ApplicationApiTest.java](../src/test/java/vn/thoxay/ApplicationApiTest.java) |
| Thương lượng, cam kết và chặn trùng lịch | [ScheduleCommitmentTest.java](../src/test/java/vn/thoxay/ScheduleCommitmentTest.java), [work_commitment.dart](../mobile_app/lib/widgets/work_commitment.dart), [calendar_screen.dart](../mobile_app/lib/screens/calendar_screen.dart) |
| Tổ đội có phải chỉ nhập số người không? | [CrewHiringTest.java](../src/test/java/vn/thoxay/CrewHiringTest.java), [crew_screen.dart](../mobile_app/lib/screens/crew_screen.dart) |
| GPS 200m, QR 5 phút và ảnh cuối ca | [AttendanceTest.java](../src/test/java/vn/thoxay/AttendanceTest.java), [attendance_screen.dart](../mobile_app/lib/screens/attendance_screen.dart), [shift_scanner_screen.dart](../mobile_app/lib/screens/shift_scanner_screen.dart) |
| Chủ thầu nghiệm thu ngày công | [admin-attendance.html](../src/main/resources/templates/admin-attendance.html), [job_payments_screen.dart](../mobile_app/lib/screens/job_payments_screen.dart) |

## Tài chính, uy tín và tương tác

| Câu hỏi | File cần mở |
| --- | --- |
| Ví main, escrow, held và rút tiền chống trùng | [WalletService.java](../src/main/java/vn/thoxay/wallet/WalletService.java), [WalletApiTest.java](../src/test/java/vn/thoxay/WalletApiTest.java), [wallet_screen.dart](../mobile_app/lib/screens/wallet_screen.dart) |
| VietQR chưa tự cộng tiền, Admin đối soát | [DepositService.java](../src/main/java/vn/thoxay/wallet/DepositService.java), [VietQrPayload.java](../src/main/java/vn/thoxay/wallet/VietQrPayload.java), [admin-bank-settings.html](../src/main/resources/templates/admin-bank-settings.html) |
| Thu nhập ngày Việt Nam và tiền công/tip/thưởng | [JobPaymentService.java](../src/main/java/vn/thoxay/wallet/JobPaymentService.java), [earnings_screen.dart](../mobile_app/lib/screens/earnings_screen.dart), [earnings_timeline_chart.dart](../mobile_app/lib/widgets/earnings_timeline_chart.dart) |
| Hoàn thành công trình và sao trung bình | [JobCompletionService.java](../src/main/java/vn/thoxay/service/JobCompletionService.java), [WorkerRatingService.java](../src/main/java/vn/thoxay/service/WorkerRatingService.java), [JobLifecycleApiTest.java](../src/test/java/vn/thoxay/JobLifecycleApiTest.java) |
| Bạc/Vàng/Kim Cương, Top 3 và phạt hủy 15 điểm | [WorkerRankingService.java](../src/main/java/vn/thoxay/service/WorkerRankingService.java), [ApplicationCancellationService.java](../src/main/java/vn/thoxay/service/ApplicationCancellationService.java), [ranking_podium.dart](../mobile_app/lib/widgets/ranking_podium.dart) |
| Chat realtime, lưu trước phát sau và retry | [MessageService.java](../src/main/java/vn/thoxay/service/MessageService.java), [ChatApiTest.java](../src/test/java/vn/thoxay/ChatApiTest.java), [chat_controller.dart](../mobile_app/lib/services/chat_controller.dart), [chat_screen.dart](../mobile_app/lib/screens/chat_screen.dart) |
| SOS, portfolio, mục đã lưu và thời tiết | [IncidentTest.java](../src/test/java/vn/thoxay/IncidentTest.java), [PortfolioPhotosTest.java](../src/test/java/vn/thoxay/PortfolioPhotosTest.java), [FavoritesTest.java](../src/test/java/vn/thoxay/FavoritesTest.java), [WeatherApiTest.java](../src/test/java/vn/thoxay/WeatherApiTest.java) |
| Thông báo DB và FCM cần cấu hình riêng | [NotificationService.java](../src/main/java/vn/thoxay/service/NotificationService.java), [push_notifications.dart](../mobile_app/lib/services/push_notifications.dart), [FIREBASE.md](../docs/FIREBASE.md) |

## UI, schema, kiểm thử và triển khai

| Câu hỏi | File cần mở |
| --- | --- |
| Màu Cam/Xanh, Sáng/Tối/Outdoor và responsive | [app_theme.dart](../mobile_app/lib/theme/app_theme.dart), [adaptive_viewport.dart](../mobile_app/lib/widgets/adaptive_viewport.dart), [home_navigation.dart](../mobile_app/lib/widgets/home_navigation.dart), [UI_UX_DESIGN_SYSTEM.md](../docs/UI_UX_DESIGN_SYSTEM.md) |
| API Base URL và chờ Render khởi động | [api_service.dart](../mobile_app/lib/services/api_service.dart), [server_warmup.dart](../mobile_app/lib/services/server_warmup.dart) |
| Schema 30 bảng và toàn bộ endpoints | [schema.sql](../schema.sql), [PROJECT_INVENTORY.json](../docs/PROJECT_INVENTORY.json), [BAO_CAO_DO_AN.md](../docs/BAO_CAO_DO_AN.md) |
| Nâng cấp database cũ không mất dữ liệu | [DatabaseMigrationConfig.java](../src/main/java/vn/thoxay/config/DatabaseMigrationConfig.java), [MigrationCompatibilityTest.java](../src/test/java/vn/thoxay/MigrationCompatibilityTest.java), [DATABASE_MIGRATIONS.md](../docs/DATABASE_MIGRATIONS.md) |
| CI build/test và APK artifact | [deployment-checks.yml gốc](../.github/workflows/deployment-checks.yml), [build-apk.yml gốc](../.github/workflows/build-apk.yml) |
| Vercel, Render, Java container và readiness | [vercel.json gốc](../vercel.json), [render.yaml gốc](../render.yaml), [Dockerfile gốc](../Dockerfile), [DeploymentHealthController.java](../src/main/java/vn/thoxay/controller/DeploymentHealthController.java) |
| Seed có ghi vào production không? | [demo_seed.py](../scripts/demo_seed.py), [demo_seed_test.py](../scripts/tests/demo_seed_test.py), [DEMO.md](../docs/DEMO.md) |

Nêu rõ phạm vi: KYC do Admin duyệt danh tính; VietQR demo không nhận tiền thật;
FCM cần Firebase; test mô phỏng camera/GPS không thay thế nghiệm thu thiết bị thật.
