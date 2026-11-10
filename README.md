# Ứng dụng Xin Cấp Quyền Truy Cập Thiết Bị bằng Flutter (UTH Permission App)

Ứng dụng Flutter mô phỏng và thực thi luồng xin cấp quyền truy cập thiết bị thực tế (**Location**, **Notification**, **Camera**) trên hệ điều hành Android/iOS, với toàn bộ giao diện nằm gọn bên trong **khung Smartphone Android** đặt chính giữa màn hình.

---

## 1. Tính năng nổi bật

1. **Khung Smartphone cố định tỷ lệ (Responsive Smartphone Frame)**:
   - Toàn bộ giao diện ứng dụng hiển thị bên trong một khung điện thoại Android duy nhất ở chính giữa màn hình (`9 : 19.5`), có viền bezel, cụm camera trước đục lỗ, nút cứng âm lượng/nguồn, thanh điều hướng đáy và **Status Bar** (hiển thị giờ, sóng di động, Wi-Fi, pin).
   - Nền bên ngoài khung điện thoại có màu xám trung tính (`#E5E7EB`).
2. **Màn hình Đăng nhập nền phía sau (`LoginScreen`)**:
   - Bao gồm Logo ứng dụng, trường nhập `Email or Username`, `Password`, nút `Login` màu cam và nút `Continue without account` viền cam.
   - Được phủ một lớp màu đen bán trong suốt (`rgba(0,0,0,0.56)`) khi hộp thoại xin cấp quyền xuất hiện.
3. **Ba màn hình xin cấp quyền theo đúng thiết kế mẫu (`PermissionDialog`)**:
   - **Màn hình 1 – Location Permission**:
     - Icon: Location Pin | Title: `Location`
     - Description: *"Allow maps to access your location while you use the app?"*
     - Nút chính: `Allow` (Gradient cam – đỏ) | Nút phụ: `Skip for now` (Nền trắng, viền cam)
   - **Màn hình 2 – Notification Permission**:
     - Icon: Notification Bell | Title: `Notification`
     - Description: *"Please enable notifications to receive updates and reminders."*
     - Nút chính: `Turn on` | Nút phụ: `Skip for now`
   - **Màn hình 3 – Camera Permission**:
     - Icon: Camera | Title: `Camera`
     - Description: *"We need access to your camera to scan QR codes."*
     - Nút chính: `Turn on` | Nút phụ: `Skip for now`
4. **Xử lý quyền thực tế với hệ điều hành (`PermissionService`)**:
   - Sử dụng `permission_handler`, `geolocator` và `camera`.
   - Kiểm tra trạng thái quyền trước khi gửi yêu cầu (`Granted`, `Denied`, `Permanently Denied`, `Restricted`).
   - Không tự động gọi lại hộp thoại hệ thống khi quyền đã bị từ chối vĩnh viễn (`Permanently Denied`), thay vào đó hiển thị cảnh báo kèm nút mở **App Settings** (`openAppSettings()`).
   - Tự động kiểm tra và cập nhật lại trạng thái quyền khi người dùng quay về ứng dụng từ màn hình Cài đặt (`WidgetsBindingObserver` -> `AppLifecycleState.resumed`).

---

## 2. Cấu trúc thư mục Source Code

```text
lib/
├── main.dart                        # Điểm khởi chạy ứng dụng Flutter
├── models/
│   └── permission_item.dart         # Model dữ liệu và cấu hình 3 bước xin cấp quyền
├── services/
│   └── permission_service.dart      # Logic kiểm tra trạng thái và gửi request quyền tới OS
├── widgets/
│   ├── smartphone_frame.dart        # Khung Smartphone Android + Status Bar + Bezel
│   ├── permission_button.dart       # Nút Gradient cam-đỏ (Primary) và nút viền cam (Secondary)
│   └── permission_dialog.dart       # Hộp thoại xin quyền bo góc 24px
└── screens/
    ├── permission_screen.dart       # Màn hình điều phối luồng 3 quyền + lắng nghe AppLifecycle
    ├── login_screen.dart            # Màn hình Login làm nền phía sau
    └── home_screen.dart             # Màn hình tổng kết trạng thái & test GPS/Camera thực tế
```

---

## 3. Hướng dẫn chạy và kiểm thử ứng dụng

Mở Terminal tại thư mục dự án `d:\UTH 2026-2027\Lập Trình Di Động\BTnangcao` và chạy các lệnh sau:

### Bước 1: Khởi tạo các tệp nền tảng còn thiếu của Flutter (nếu chạy lần đầu) và tải thư viện
```bash
flutter create .
flutter pub get
```
*(Lưu ý: Lệnh `flutter create .` sẽ chỉ bổ sung các file khung nền tảng còn thiếu mà **không** ghi đè lên code trong `lib/`, `pubspec.yaml` hay `AndroidManifest.xml` đã cấu hình).*

### Bước 2: Chạy ứng dụng trên Android Emulator hoặc thiết bị Android thật
```bash
flutter run
```

### Bước 3: Kịch bản kiểm thử
1. **Kiểm tra nút `Allow` / `Turn on`**:
   - Nhấn `Allow` ở màn hình **Location** -> Hộp thoại hệ thống Android xuất hiện. Chọn *"While using the app"* -> Trạng thái cập nhật thành `Granted` và tự động chuyển sang màn hình **Notification**.
   - Nhấn `Turn on` ở màn hình **Notification** -> Trên Android 13+ (API 33+), hộp thoại `POST_NOTIFICATIONS` xuất hiện -> Chuyển sang màn hình **Camera**.
   - Nhấn `Turn on` ở màn hình **Camera** -> Hộp thoại cấp quyền Camera của hệ điều hành xuất hiện -> Chuyển sang màn hình hoàn tất (`HomeScreen`).
2. **Kiểm tra nút `Skip for now`**:
   - Nhấn `Skip for now` ở bất kỳ màn hình nào -> Không gọi hộp thoại hệ thống, đánh dấu bước đó là `Skipped` và chuyển ngay sang màn hình tiếp theo.
3. **Kiểm tra trường hợp Từ chối (`Denied`) và Từ chối vĩnh viễn (`Permanently Denied`)**:
   - Nếu chọn *"Don't allow"* nhiều lần trên Android, quyền chuyển sang trạng thái `Permanently Denied`.
   - Giao diện hiển thị khung hướng dẫn màu cam kèm nút **Mở Cài đặt (Open Settings)** để cấp quyền trong Cài đặt hệ thống. Khi quay lại ứng dụng, trạng thái quyền tự động được cập nhật.
