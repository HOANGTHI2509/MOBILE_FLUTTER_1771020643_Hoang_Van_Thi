# Pickleball Court Management System (PCM) - Mobile & Backend

Dự án quản lý sân Pickleball bao gồm Backend (.NET 8) và Frontend Mobile App (Flutter).

## 1. Công nghệ sử dụng
- **Backend**: ASP.NET Core 8.0 Web API
- **Database**: SQL Server 2022
- **Mobile App**: Flutter (Android/iOS)
- **Deployment**: Docker, Docker Compose, Nginx (VPS Ubuntu)

## 2. Hướng dẫn cài đặt & Chạy Local

### Backend
Yêu cầu: .NET 8 SDK, SQL Server (hoặc Docker).

1. **Cấu hình Database**:
   - Mở `PcmBackend/appsettings.json` và cập nhật ConnectionString nếu cần.
   - Chạy lệnh sau để tạo Database:
     ```bash
     cd PcmBackend
     dotnet ef database update
     ```

2. **Chạy Server**:
   ```bash
   dotnet run
   ```
   - Server sẽ chạy tại: `http://localhost:5282`
   - Swagger docs: `http://localhost:5282/swagger`

### Mobile App (Flutter)
Yêu cầu: Flutter SDK, Android Studio/VS Code.

1. **Cài đặt dependencies**:
   ```bash
   cd pcm_mobile_643
   flutter pub get
   ```

2. **Chạy ứng dụng**:
   - Mở máy ảo Android hoặc cắm thiết bị thật.
   - Chạy lệnh:
     ```bash
     flutter run
     ```

## 3. Triển khai lên VPS (Deployment)

Dự án đã bao gồm bộ script tự động deploy lên VPS Ubuntu.

### Cấu trúc thư mục deploy
- `deployment/`: Chứa các script deploy.
  - `setup_vps.sh`: Cài đặt môi trường (Docker, .NET, Nginx).
  - `deploy.ps1`: Script PowerShell để build & upload code tự động.
  - `docker-compose.yml`: Cấu hình SQL Server.
  - `pcm-backend.service`: File cấu hình Systemd service.

### Hướng dẫn Deploy
1. **Trên máy tính (Windows)**:
   - Mở PowerShell, vào thư mục `deployment`.
   - Chạy script:
     ```powershell
     .\deploy.ps1
     ```
   - Nhập mật khẩu VPS khi được hỏi.

2. **Trên VPS**:
   - (Chỉ cần làm lần đầu) Chạy `setup_vps.sh` để cài đặt môi trường.
   - App sẽ tự động chạy tại port **5000**.
   - API URL: `http://<VPS_IP>:5000`

## 4. Thông tin Sinh viên & Demo
### Thông tin Sinh viên
| Thông tin | Chi tiết |
| :--- | :--- |
| **Trường** | Đại Học Đại Nam |
| **Họ và tên** | Hoàng Văn Thi |
| **Mã Sinh Viên** | 1771020643 |
| **Lớp** | CNTT 17-07 |

### Tài khoản Demo
Dưới đây là danh sách tài khoản để kiểm tra hệ thống:

| Vai trò (Role) | Email | Mật khẩu (Password) | Mô tả |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@pcm.com` | `Pcm@123456` | Quản trị viên hệ thống (mặc định) |
| **User** | `test5@gmail.com` | `admin123` | Người dùng đã đăng ký trước |

## 5. File cài đặt (APK)

Ứng dụng đã được build sẵn file cài đặt cho Android. Bạn có thể tìm thấy file APK tại đường dẫn sau trong source code:

| Loại file | Đường dẫn (Path) |
| :--- | :--- |
| **Android APK** | `pcm_mobile_643/build/app/outputs/flutter-apk/app-release.apk` |

### Hướng dẫn cài đặt nhanh:
1. Copy file `app-release.apk` vào điện thoại Android.
2. Mở trình quản lý file trên điện thoại, tìm đến file APK.
3. Nhấn vào file và chọn **Install** (Cài đặt).
   *(Lưu ý: Nếu điện thoại chặn, hãy vào Cài đặt -> Bảo mật -> Cho phép cài ứng dụng từ nguồn không xác định)*.
