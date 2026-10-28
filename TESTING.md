# Kiểm thử và nghiệm thu

## Backend

```powershell
.\mvnw.cmd -B verify
```

64 kiểm thử JUnit/Spring Boot dùng H2 mặc định, chạy với Spring Security và JWT
thật: đăng ký/đăng nhập, BCrypt, chống đăng ký ADMIN, token giả/thiếu, tài khoản
bị khóa, phân quyền, Haversine, dữ liệu sai, ứng tuyển trùng, lịch sử, duyệt,
hai giao dịch duyệt đồng thời cho một vị trí, render Thymeleaf, CSRF, xác thực
CCCD, khóa/mở tài khoản và xóa công trình có đơn ứng tuyển.

Nâng cấp bao phủ cập nhật CCCD/đưa về chưa xác thực, chặn duyệt ảnh cũ,
đánh giá sai điểm/sai người/sai chủ công trình, tính trung bình qua nhiều
công trình, gửi lại yêu cầu hoàn thành, hoàn thành hai công trình đồng thời
cho cùng thợ, tính lại điểm khi xóa và bộ lọc loại việc/lương.
KYC hai mặt kiểm tra các vai trò kể cả Admin, mặc định chưa xác thực khi insert
SQL, CHECK chống verified=true với ảnh thiếu, cập nhật thiếu/HTTP bị từ chối
nguyên tử, ảnh đổi làm mất xác thực và chống duyệt snapshot cũ của từng mặt.

Uy tín kiểm tra các ngưỡng bậc, KYC của Kim Cương, giới hạn 100 điểm,
cộng thưởng đúng một lần, hai công trình cùng hoàn thành không mất lượt cộng,
nhật ký điểm riêng tư, đánh giá thực tế và loại tài khoản khóa/chưa được đánh
giá/chủ thầu khỏi bảng xếp hạng. Widget test kiểm tra dữ liệu bậc và phân trang
lịch sử cộng/trừ điểm.

Để chạy cùng bộ kiểm thử trên PostgreSQL, dùng **database kiểm thử riêng**.
Hibernate `create-drop` và các thao tác dọn dữ liệu trong test sẽ xóa dữ liệu
database được chỉ định. Ví dụ tạo database mới:

```powershell
createdb -U postgres tho_xay_test
.\mvnw.cmd -B verify `
  '-Dspring.datasource.url=jdbc:postgresql://localhost:5432/tho_xay_test' `
  '-Dspring.datasource.username=postgres' `
  '-Dspring.datasource.password=postgres' `
  '-Dspring.test.database.replace=NONE'
```

## Flutter

Module ví bổ sung 10 kiểm thử Backend: nạp chờ đối soát, duyệt đồng thời một
lần, mã ngân hàng không dùng lại, rút cạnh tranh không âm tiền, giữ chỗ và hoàn
giữ chỗ, ký quỹ idempotent, thanh toán đúng nguồn tiền và chỉ công trình hợp
lệ, ranh giới thời gian Việt Nam, riêng tư/hạn mức/số nguyên, bảo toàn sổ tiền
khi xóa bài, render và POST form Admin có CSRF. Bốn kiểm thử Flutter kiểm tra
cảnh báo ký quỹ, phân trang, thử lại cùng mã yêu cầu, đổi kỳ thu nhập và xác
nhận ngày công/tip/thưởng trước thanh toán.

Nghiệm thu HTTP local dùng ba tài khoản tạm gồm Admin thử: Online/Offline,
nạp chờ duyệt và duyệt lại, hoàn thành rồi trả tiền công/tip/thưởng, chuyển
ký quỹ, rút giữ chỗ, từ chối hoàn tiền và đối soát khoản rút, thống kê và sổ
giao dịch đều đạt. Chỉ dùng khoản tiền kiểm thử tổng hợp; không chuyển ngân
hàng thật. Các tài khoản và giao dịch thử được xóa theo đúng ID sau kiểm tra.

Hủy việc bao phủ lý do sai, sai vai trò/chủ đơn/trạng thái, hai yêu cầu hủy
đồng thời, hủy đua với hoàn thành, giảm bậc, điểm sàn 0, thu hồi liên lạc/chat,
tuyển người thay thế và hoàn thành không chấm thợ đã hủy, giữ điểm phạt sau
khi Admin xóa công trình. Cùng bộ 46 test đạt trên H2 và PostgreSQL riêng.
Schema mới và migration 002–008 được chạy hai lần trên database thử nghiệm;
chạy lại 007 không xóa điểm phạt hay số lần hủy đã lưu.

Nghiệm thu HTTP trên Backend local/PostgreSQL: tạo ba tài khoản tạm, cập nhật
hồ sơ và kiểm tra dữ liệu công khai; ứng tuyển/duyệt/chat; hủy và gửi lại;
kiểm tra mất quyền liên lạc, vị trí trống trên tìm gần; nhận người thay thế,
hoàn thành/chấm sao, bảng xếp hạng và lịch sử uy tín; đọc tất cả thông báo.
Các bước đạt và dữ liệu thử được dọn theo đúng ID sau nghiệm thu.
FCM cloud/thiết bị thật chưa thử vì chưa có dự án Firebase; cấu hình theo
`docs/FIREBASE.md` trước khi kiểm thử foreground/background/terminated trên máy.

```powershell
cd mobile_app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

47 kiểm thử Dart/widget: lưu/khôi phục phiên, đính JWT, xóa phiên khi 401,
validation đăng nhập/đăng ký, tìm việc theo vị trí được cấp cho test, ứng tuyển
và lịch sử, duyệt thợ, validation form đăng công trình. Widget test dùng API
và vị trí giả lập, không truy cập GPS thật hay gửi yêu cầu ra mạng.
Nâng cấp kiểm tra thêm ACCOUNT_LOCKED 403, bộ lọc, liên hệ sau ACCEPTED,
URI tel qua launcher giả, cập nhật CCCD và chọn điểm trước khi hoàn thành.
Ba kiểm thử bản đồ dùng MemoryTiles: bắt buộc chọn vị trí trước khi xác nhận,
trả đúng tọa độ đã chọn, chọn đúng công trình qua ghim và cập nhật camera/ghim
khi kết quả tìm kiếm thay đổi. Không gọi tile OpenStreetMap trong test.
KYC kiểm tra nhãn hai ô ảnh, bắt buộc mặt sau, giữ mặt trước đã có và gửi đúng
hai khóa cccdFrontImage/cccdBackImage tới REST API.

## Nhắn tin realtime

`ChatApiTest` dùng cả MockMvc và WebSocket thật tới Tomcat cổng ngẫu nhiên:
gửi hai chiều, giới hạn nội dung, gửi lại không trùng, phân trang/cursor, lịch sử
riêng theo job và cặp người dùng, chặn pending/rejected/admin/người ngoài,
phát tin tới đúng hai kết nối sau commit, chặn JWT sai, khóa tài khoản đang
online, và cascade tin nhắn khi admin xóa job. Cùng bộ test chạy trên H2 và
PostgreSQL bằng lệnh verify ở trên.

Flutter kiểm tra wire format của API, nút chat chỉ hiện ở đơn ACCEPTED, tin
realtime đến trong lúc tải lịch sử, khử trùng, tải bù nhiều trang sau ngắt mạng
kể cả khi ID lớn đã đến trước, tải tin cũ, giữ bản nháp/gửi lại cùng mã khi mất
phản hồi, lỗi quyền và dọn kết nối lúc đóng màn hình/đăng xuất.

Checkpoint chat đã chạy `mvnw verify` thành công với 30 test trên H2 và
PostgreSQL, analyzer không lỗi, 26 test Flutter và Web release build thành công.
Đã kiểm tra thêm chính Flutter HTTP/WebSocket client với Backend JAR và
PostgreSQL đang chạy: đăng ký hai tài khoản tạm, đăng việc/ứng tuyển/duyệt,
gửi hai chiều realtime, gửi lại cùng mã và đọc lại đúng hai tin đã lưu. Migration
004 chạy lại thành công; công trình, tin nhắn và hai tài khoản thử đã được dọn.

Nghiệm thu: dùng hai tài khoản Thầu–Thợ, đăng việc → ứng tuyển → duyệt, mở Chat
ở hai thiết bị và gửi tin qua lại không tải lại trang. Ngắt mạng một thiết bị,
gửi thêm tin từ thiết bị kia, bật lại mạng và kiểm tra tin được tải bù đúng thứ
tự. Khóa một tài khoản trong Admin và kiểm tra socket bị đóng, không gửi được
tin mới. Đóng/mở lại Chat để xác nhận lịch sử đã được lưu.

## Hồ sơ mở rộng

ExtendedProfileApiTest xác nhận lưu/đọc kỹ năng và album, chuẩn hóa trùng kỹ
năng, không tự sửa vai trò/rating/verified hoặc hồ sơ tài khoản khác, bảo vệ
ngày sinh/điện thoại/CCCD ở API hồ sơ thợ, dữ liệu sai không lưu một phần và
thay đổi danh tính làm mất KYC. Đã chạy cùng bộ kiểm thử trên PostgreSQL cho
cả các collection có ON DELETE CASCADE. Flutter kiểm tra validation kinh nghiệm,
HTTP ảnh bị từ chối, lưu album/kỹ năng, payload API và cập nhật họ tên cache;
các test CCCD cũ vẫn chạy với hồ sơ có phần chỉnh sửa và danh sách cuộn dài.

## Thông báo và FCM

NotificationApiTest kiểm tra lịch sử riêng/phân trang/đã đọc, không trùng sự
kiện khi duyệt lại, không đưa nội dung chat lên push, rebind thiết bị sau đổi
tài khoản, không thu hồi thiết bị của người khác, rollback không gửi, retry
tối đa ba lần, xóa đăng ký hỏng và ngừng push cho tài khoản bị khóa. Gateway
Firebase được giả lập để test không gửi tới thiết bị thật/không cần khóa cloud.
Flutter kiểm tra inbox/phân trang/đọc tất cả, foreground cập nhật, dọn listener,
thiếu cấu hình được giải thích và đăng xuất không lặp khi unregister trả 401.
Push tới điện thoại thật cần cấu hình và kiểm tra theo `docs/FIREBASE.md`;
chưa thể nghiệm thu gửi thật khi chưa có dự án/credential/thiết bị Firebase.

## Giao diện và khả năng truy cập

Checkpoint UI: `mvnw verify` đạt 31 test; Flutter analyzer không lỗi, 30 test
đạt và Web release build thành công. Admin test kiểm tra số tài khoản/công trình,
tỷ lệ KYC 0% → 33% sau duyệt và trường hợp không có tài khoản. Widget test kiểm
tra skeleton → kết quả trống, phân biệt lỗi kết nối với danh sách trống, tắt
animation khi giảm chuyển động/route ẩn, card/minh họa ở chiều rộng 320px với
chữ phóng 1.8 lần. Test bản đồ giải mã ảnh in-memory trước khi đợi shimmer kết
thúc và tiếp tục kiểm tra chọn ghim/tọa độ; không tải tile mạng trong test.

Đã xem trên Chrome: Admin desktop hiển thị bốn thẻ và tỷ lệ KYC 33% từ dữ liệu
local thực tế, bảng/icon/badge và popup CCCD mở được, nút duyệt vẫn bị khóa
khi thiếu hai ảnh. Flutter ở viewport 390 × 844 hiển thị card, bộ lọc, shimmer
khi tải lại và minh họa/nút khôi phục khi lọc Phụ hồ không có kết quả. Viewport
kiểm tra đã được trả về mặc định. Không thay đổi tài khoản hoặc công trình
trong quá trình xem trước giao diện.

## Modal Admin

```powershell
node --check src/main/resources/static/js/admin-kyc.js
node --test scripts/tests/admin-kyc.test.cjs
```

4 kiểm thử sự kiện DOM: chỉ duyệt sau khi hai ảnh tải xong, chặn ảnh thiếu/lỗi,
bỏ qua callback ảnh của tài khoản trước, xóa URL khi đóng và chặn gửi lặp.
Modal Bootstrap còn được kiểm tra trực tiếp trên trình duyệt.

Đã kiểm chứng trên Windows, Java 21, Flutter 3.47.8: Maven verify với cả 23 test
trên H2 và PostgreSQL 17.11, Flutter analyzer, 18 test và Web release build.
Schema/seed PostgreSQL mới xác nhận mọi tài khoản mẫu đều chưa xác thực.
Fixture schema legacy xác nhận migration giữ ảnh cũ, hạ xác thực khi thiếu mặt
sau và chạy lại không thay đổi hồ sơ đã được duyệt đủ hai mặt.
Đã kiểm tra trên Chrome: popup hiển thị hai ảnh DEMO song song, duyệt ngay
trong modal thành công, đổi mặt sau qua API đưa verified về false, và popup
của seed Admin không có ảnh giữ nút duyệt bị vô hiệu hóa. Flutter hiển thị
đúng hai trường mặt trước/mặt sau. Tài khoản DEMO đã được xóa sau kiểm tra.
Schema/seed và luồng HTTP đăng nhập →
Haversine → đăng việc → ứng tuyển → nhận thợ → IN_PROGRESS đã chạy trên
PostgreSQL 17.11 thật. Web Admin và Flutter đã được đăng nhập trên Chrome,
kiểm tra dashboard quản trị và danh sách công trình/ứng viên của chủ thầu.
Nâng cấp đã kiểm chứng nền OpenStreetMap tải trên Chrome, chạm đặt ghim và
trả tọa độ về form đăng công trình. Luồng HTTP cập nhật CCCD → nhận thợ →
hoàn thành → điểm trung bình đã chạy trên database local bằng tài khoản tạm,
và dữ liệu kiểm thử đã được dọn sau khi xác nhận.
APK chưa build vì máy kiểm chứng chưa có Android SDK; iOS chưa build vì cần macOS/Xcode.

## Nghiệm thu thủ công

1. Khởi động PostgreSQL, backend và Flutter theo README; đăng nhập tài khoản thầu mẫu.
2. Đăng công trình cần 1 thợ, lương 500000, loại Thợ chính, vị trí `10.7769,106.7009`.
3. Đăng xuất, đăng ký thợ mới. Nếu muốn kiểm tra CCCD, nhập URL HTTPS ảnh thử
   nghiệm mặt trước và mặt sau thuộc quyền sử dụng của bạn; có thể bổ sung cả
   hai trong Hồ sơ & CCCD. Không dùng giấy tờ cá nhân thật cho demo.
4. Lấy GPS hoặc chọn vị trí mẫu, bán kính 10 km; mở chi tiết và bấm Nhận việc.
5. Kiểm tra đơn Chờ duyệt trong lịch sử; thao tác lặp không tạo đơn thứ hai.
6. Đăng nhập thầu, mở Xem & duyệt thợ, bấm Nhận thợ. Công trình chuyển Đang thi công.
7. Đăng nhập lại thợ, làm mới lịch sử để thấy Đã nhận. Công trình đủ thợ biến mất
   khỏi danh sách tìm việc OPEN.
8. Vào Web Admin, bấm Xem CCCD, kiểm tra hai ảnh trong popup và Xác thực danh tính.
   Thiếu một ảnh hoặc ảnh tải lỗi phải không duyệt được. Khóa thợ và kiểm tra
   đăng nhập/JWT bị chặn; mở khóa và thử lại.
9. Đăng công trình thử khác, xóa bằng Admin; xác nhận công trình và đơn liên quan
   không còn trong danh sách sau khi làm mới.

## Kiểm chứng lỗi khởi động PowerShell

Lỗi `Process terminated with exit code: 1` đã được tái hiện bằng
`.\mvnw.cmd spring-boot:run`: PostgreSQL mặc định `localhost:5432` từ chối kết nối.
Sau khi kết nối đúng PostgreSQL local ở cổng 55432, lỗi tiếp theo là thiếu
`JWT_SECRET`. Cổng 8080 trống tại thời điểm chẩn đoán.

Script `scripts/start-local.ps1 -WithFrontend` chuẩn bị cấu hình riêng trong
`.local/`, bật PostgreSQL portable nếu có, build/test và chờ cả backend cùng
frontend trả HTTP 200. Biến môi trường vẫn có thể thay thế các giá trị local.
`scripts/stop-local.ps1` kiểm tra đường dẫn command line trước khi dừng đúng
tiến trình của workspace; giữ PostgreSQL chạy để sử dụng Maven trực tiếp.

Sau sửa, chính lệnh `.\mvnw.cmd spring-boot:run` đã khởi động Tomcat cổng 8080
và trả HTTP 200 tại `/admin/login`. Đã kiểm tra cả khởi động lại sau khi tắt
PostgreSQL, nạp lại cấu hình/khóa JWT đã lưu, đăng nhập tài khoản demo và hai
giao diện HTTP 200. Cơ chế chờ frontend dùng loopback IPv4 để tránh việc
`localhost` trỏ IPv6 trong khi server Web chỉ lắng nghe IPv4.

## Checkpoint Git

Mỗi bước và mỗi màn hình có commit riêng trên `main`, chỉ chuyển bước sau khi
build và push thành công. Xem `git log --oneline` để chọn điểm khôi phục. Dùng
`git revert <commit>` khi cần đảo một thay đổi đã chia sẻ, rồi build và push
checkpoint mới theo AGENTS.md.

### Camera CCCD

Kiểm thử multipart hai mặt, kiểm tra nội dung ảnh thực, ảnh thiếu/giả/quá lớn,
ảnh trùng, truy cập riêng tư, tài khoản khóa, thay ảnh và chống duyệt snapshot cũ.
Flutter kiểm tra gửi binary có JWT, xóa phiên bị khóa, chụp đủ hai mặt, hủy
và từ chối quyền camera. Các kiểm thử camera dùng đối tượng giả; chưa thay thế
việc kiểm chứng quyền và chụp thực tế trên Android/iOS.

Theme theo vai trò được kiểm thử trên ứng dụng gốc: đăng nhập thợ → mở màn
hình con → đổi phiên chủ thầu → đăng xuất; cả màn hình đang mở đổi màu đúng.
Màu chữ trên nút nhấn chính đạt tỷ lệ tương phản tối thiểu 4.5:1 cho từng vai trò.

Kiểm chứng HTTP local với PostgreSQL: hai ảnh tổng hợp (không dùng CCCD thật)
được gửi bằng multipart, đọc lại JPEG riêng tư có `no-store`; tệp vượt 5 MB trả
413 từ servlet. Tài khoản thử được xóa và ảnh xóa theo cascade sau kiểm tra.

## Chuẩn bị Vercel / cloud

```powershell
node --test scripts/deployment.test.mjs
```

Ba kiểm thử Node xác minh URL Backend HTTPS, từ chối LAN/localhost/credentials
và export schema không có dữ liệu demo. Maven có thêm ba kiểm thử health công
khai, preflight multipart từ đúng domain Vercel và từ chối domain Preview khác.
Lệnh `node scripts/build-vercel.mjs` đã build Web release thành công với
`FLUTTER_BIN` trỏ tới SDK local và API HTTPS giả lập chỉ dùng để kiểm chứng build.
Sau đó Web local đã được build lại với cấu hình LAN ban đầu.

Kiểm tra chạy thật profile `prod` trên database riêng `tho_xay_deploy_test`:
schema được xuất từ DDL không seed, Hibernate `validate` khởi động thành công,
users trống, `/health` UP, Admin cookie Secure/SameSite=Lax khi đứng sau HTTPS
proxy và CORS đúng origin Vercel. Database ứng dụng hiện có không bị thay đổi.
Workflow `deployment-checks.yml` kiểm chứng Docker build và tải SDK Linux/build
Web bằng chính script dùng trên Vercel. Hướng dẫn cloud ở
[DEPLOY_VERCEL.md](docs/DEPLOY_VERCEL.md).

Render Blueprint: `render.yaml` đã được kiểm tra với JSON Schema chính thức
hiện hành. Chạy production với `DB_HOST`/`DB_PORT`/`DB_NAME` (không cần DB_URL),
`DB_INIT_MODE=always` trên database test trống: tự tạo bảng thành công, không seed
tài khoản. Khởi động lần hai giữ nguyên bản ghi tổng hợp đã tạo để kiểm chứng.
Kiểm thử Node so sánh byte nội dung DDL bootstrap với bản xuất không seed từ
`schema.sql` để phát hiện sai lệch. Luồng DB_URL thủ công vẫn được hỗ trợ.
