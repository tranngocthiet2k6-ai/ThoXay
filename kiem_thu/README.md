# 06. Kiểm thử tự động

Hai thư mục **Backend** và **Flutter** ở đây là junction cục bộ, trỏ vào các bộ
test gốc. Không có bản sao thứ hai của mã kiểm thử. Chạy script
`./scripts/prepare-defense-workspace.ps1` ở root để tạo lại khi đổi máy Windows.

| Bộ test thật | Mở nhanh một bài kiểm tra tiêu biểu |
| --- | --- |
| [src/test](../src/test/) | [AuthApiTest.java](../src/test/java/vn/thoxay/AuthApiTest.java) |
| [mobile_app/test](../mobile_app/test/) | [worker_home_test.dart](../mobile_app/test/worker_home_test.dart) |
| [Kiểm tra migration PostgreSQL](../src/test/java/vn/thoxay/MigrationCompatibilityTest.java) | Database QA riêng, schema ngẫu nhiên, không dùng database app |
| [Kiểm tra JavaScript Admin](../scripts/tests/) | [admin-kyc.test.cjs](../scripts/tests/admin-kyc.test.cjs) |

Trong **Terminal → Run Task**, chọn **Bảo vệ: kiểm thử và build Backend** hoặc
**Bảo vệ: kiểm thử Flutter**. Task Maven mặc định chạy test H2; muốn chạy đủ ba
test tương thích PostgreSQL, phải có QA database riêng và đặt biến môi trường
`THOXAY_PG_TEST_URL=jdbc:postgresql://127.0.0.1:55433/thoxay_upgrade_qa` trước khi
mở VS Code/chạy Maven. Lượt nghiệm thu workspace dùng đúng QA database này.
Không đặt URL production vào biến test.

Mốc trước workspace: 125 test Backend, 110 Flutter, 12 JS; xem kết quả chạy lại
trong terminal và báo cáo build, không coi số lượng test là phần trăm code coverage.
Không có task nào tự chạy khi mở workspace. [Bản đồ code/test](../00_BAO_VE_DO_AN/BAN_DO_MO_CODE_NHANH.md).
