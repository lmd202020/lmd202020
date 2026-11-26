# ADMIN MINHDUC – SwiftUI

Ứng dụng iOS SwiftUI hỗ trợ thiết lập chơi game an toàn, mở Free Fire VN/TH và xác thực License Key.

## Yêu cầu / build
- Xcode 16 trở lên (GitHub Actions macOS 15)
- Deployment target iOS 15.0; app chỉ dùng API tương thích iOS 15+
- Mở `ADMINMINHDUC.xcodeproj`, chọn scheme `ADMINMINHDUC`, build trên thiết bị hoặc simulator.
- GitHub Actions: push lên nhánh `main` hoặc chạy Actions → Build ADMIN MINHDUC IPA → Run workflow.
- Artifact `ADMIN-MINHDUC-unsigned-IPA` là IPA unsigned để ký bằng chứng chỉ hợp lệ trước khi cài lên iPhone.

## License API
Client endpoint và contract được kế thừa từ source bạn cung cấp:
- `POST /activate` JSON `{ "key": "...", "deviceId": "..." }`
- `POST /validate` JSON `{ "key": "...", "deviceId": "..." }`
- Response tối thiểu `{ "success": true, "valid": true, "expiresAt": "..." }`
- Endpoint: `https://muddy-snow-bf48.minhduc1234509876.workers.dev`

Nếu API của bạn dùng schema khác, cần chỉnh `APIResult` và request payload trong `LicenseManager.swift`.
**Không đưa ADMIN_SECRET hoặc Cloudflare API token vào IPA.** Việc tạo / thu hồi / gia hạn key cần chạy trên dashboard/backend quản trị riêng có xác thực admin.

## Tính năng
- Login License Key; lưu key trong iOS Keychain; xác thực server khi mở app; kiểm tra định kỳ; logout/xoá key.
- Trang Admin hiển thị trạng thái License (không có quyền quản trị server).
- Trang Game có nút mở Free Fire VN và TH theo URL scheme.
- Trang chủ hướng dẫn thiết lập iOS: pin, nhiệt độ, kết nối, Tập trung, dung lượng.

## Giới hạn iOS
Không có API công khai cho app thường để ép FPS, tăng xung CPU/GPU, điều khiển hệ thống làm mát, can thiệp tiến trình game khác hoặc bảo đảm ping / hiệu năng 100%. Ứng dụng không thực hiện injection, exploit, sửa dữ liệu game hay bypass bảo vệ. Các hướng dẫn chỉ là thao tác người dùng có thể thực hiện trong iOS.
