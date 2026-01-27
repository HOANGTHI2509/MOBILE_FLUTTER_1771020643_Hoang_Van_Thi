# PCM - Hệ Thống Quản Lý Câu Lạc Bộ Pickleball 🏸

**Sinh viên:** Hoàng Văn Thi  
**MSSV:** 1771020643  
**Đồ án:** Phát triển ứng dụng di động với Flutter

---

## 📋 Tổng Quan Dự Án

PCM (Pickleball Club Management) là hệ thống quản lý câu lạc bộ toàn diện được xây dựng bằng **Flutter** (mobile) và **ASP.NET Core** (backend). Hệ thống quản lý thành viên, đặt sân, giải đấu, giao dịch ví, và các hoạt động quản trị.

### Tính Năng Chính

#### 👥 Quản Lý Thành Viên
- Đăng ký và xác thực người dùng (JWT)
- Quản lý hồ sơ với hệ thống cấp bậc (Standard, Silver, Gold, Diamond)
- Theo dõi số dư ví
- Phân quyền Admin/Member

#### 🏟️ Hệ Thống Đặt Sân
- Lịch thời gian thực với Syncfusion Calendar
- Đặt sân theo khung giờ
- **Hủy sân với chính sách hoàn 50% tiền**
- Tự động phát hiện xung đột lịch
- Cập nhật thời gian thực qua SignalR

#### 💰 Ví & Giao Dịch
- Yêu cầu nạp tiền với ảnh chứng minh
- Quy trình phê duyệt của admin
- Lịch sử giao dịch
- Tự động cập nhật số dư

#### 🏆 Quản Lý Giải Đấu
- Tạo và quản lý giải đấu
- Lập lịch trận đấu
- Theo dõi điểm số với tích hợp DUPR
- Phân phối giải thưởng

#### 👨‍💼 Bảng Điều Khiển Admin
- Quản lý thành viên (phê duyệt/khóa tài khoản)
- Kiểm soát tài chính (phê duyệt nạp tiền, báo cáo doanh thu)
- Vận hành sân
- Giám sát giải đấu

---

## 🏗️ Kiến Trúc

### Frontend (Flutter)
```
pcm_mobile_643/
├── lib/
│   ├── models/          # Mô hình dữ liệu (Member, Booking, Court, etc.)
│   ├── providers/       # Quản lý trạng thái (Provider pattern)
│   ├── screens/         # Màn hình giao diện
│   ├── services/        # Dịch vụ API & SignalR
│   └── main.dart
```

### Backend (ASP.NET Core)
```
PcmBackend/
├── Controllers/         # API endpoints
├── Models/             # Database entities
├── Data/               # DbContext & migrations
├── Hubs/               # SignalR hubs
└── Program.cs
```

### Cơ Sở Dữ Liệu
- **SQL Server** với Entity Framework Core
- Identity cho xác thực
- Migrations để quản lý schema

---

## 🚀 Bắt Đầu

### Yêu Cầu Hệ Thống
- **Flutter SDK** (phiên bản stable mới nhất)
- **.NET 8.0 SDK** trở lên
- **SQL Server** (LocalDB hoặc phiên bản đầy đủ)
- **Visual Studio Code** hoặc **Visual Studio**

### Khởi Động Nhanh

#### 1. Khởi Động Backend & Frontend Cùng Lúc
```powershell
# Script tự động
.\START_PCM.ps1
```

Script này sẽ:
1. Khởi động backend tại `http://localhost:5282`
2. Đợi backend sẵn sàng
3. Chạy ứng dụng Flutter web

#### 2. Khởi Động Thủ Công

**Backend:**
```powershell
cd PcmBackend
dotnet restore
dotnet ef database update  # Chỉ lần đầu
dotnet run
```

**Frontend:**
```powershell
cd pcm_mobile_643
flutter pub get
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

#### 3. Khởi Động Lại Backend
```powershell
.\RESTART_BACKEND.ps1
```

---

## 🔑 Tài Khoản Mặc Định

### Tài Khoản Admin
- **Email:** `admin@pcm.com`
- **Mật khẩu:** `Pcm@1234563`

### Tài Khoản Thành Viên Test
- **Email:** `test5@gmail.com` 
- **Mật khẩu:** `admin123`

---

## 📱 Hướng Dẫn Sử Dụng

### 1. Đặt Sân
1. Vào tab **"Đặt sân"**
2. Nhấn vào khung giờ trống
3. Chọn sân từ danh sách
4. Xác nhận đặt sân (tiền sẽ bị trừ từ ví)

### 2. Hủy Sân
1. Vào tab **"Đặt sân"**
2. **Nhấn vào booking của bạn** (màu xanh)
3. Xem chính sách hủy:
   - Hoàn lại 50%
   - Phí hủy 50%
4. Xác nhận hủy
5. Tiền được hoàn vào ví

### 3. Nạp Tiền
1. Vào tab **"Ví tiền"**
2. Nhấn **"Nạp tiền"**
3. Nhập số tiền và tải ảnh chứng minh
4. Đợi admin phê duyệt
5. Số dư tự động cập nhật

### 4. Chức Năng Admin
1. Đăng nhập bằng tài khoản admin
2. Vào tab **"Admin"**
3. Quản lý:
   - Thành viên (phê duyệt/khóa)
   - Nạp tiền (phê duyệt/từ chối)
   - Sân
   - Giải đấu

---

## 🛠️ Công Nghệ Sử Dụng

### Frontend
- **Flutter** - Framework đa nền tảng
- **Provider** - Quản lý trạng thái
- **Dio** - HTTP client
- **Syncfusion Calendar** - Lịch đặt sân
- **SignalR Client** - Cập nhật thời gian thực
- **FlutterSecureStorage** - Lưu trữ token

### Backend
- **ASP.NET Core 8.0** - Web API
- **Entity Framework Core** - ORM
- **SQL Server** - Cơ sở dữ liệu
- **SignalR** - Giao tiếp thời gian thực
- **ASP.NET Identity** - Xác thực
- **JWT** - Xác thực dựa trên token

---

## 📊 Cấu Trúc Database

### Bảng Chính
- `AspNetUsers` - Tài khoản người dùng (Identity)
- `643_Members` - Hồ sơ thành viên
- `643_Courts` - Thông tin sân
- `643_Bookings` - Đặt sân
- `643_WalletTransactions` - Giao dịch tài chính
- `643_Tournaments` - Dữ liệu giải đấu
- `643_Matches` - Kết quả trận đấu

---

## 🔧 Cấu Hình

### URL Backend API
**File:** `pcm_mobile_643/lib/services/api_service.dart`
```dart
static const String baseUrl = 'http://localhost:5282';
```

### Kết Nối Database
**File:** `PcmBackend/appsettings.json`
```json
"ConnectionStrings": {
  "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=PcmDb643;..."
}
```

---

## 🐛 Xử Lý Sự Cố

### Backend không khởi động được
```powershell
# Tắt các process đang chạy
Get-Process -Name "dotnet" | Where-Object {$_.Path -like "*PcmBackend*"} | Stop-Process -Force

# Khởi động lại
cd PcmBackend
dotnet run
```

### Lỗi 401 Unauthorized
- Kiểm tra token đã được lưu trong FlutterSecureStorage chưa
- Thử đăng xuất và đăng nhập lại
- Xác nhận backend đang chạy

### Lỗi 404 Member not found
- Backend tự động tạo member record khi gọi API lần đầu
- Đảm bảo backend chạy đúng cổng (5282)

### Dialog hủy sân không hiện
- Đảm bảo bạn đang nhấn vào **booking của mình** (màu xanh)
- Hot reload app sau khi thay đổi code
- Kiểm tra console của browser để xem debug logs

---

## 📝 Cập Nhật Gần Đây

### v1.2 - Tính Năng Hủy Sân
- ✅ Thêm chính sách hoàn 50% khi hủy
- ✅ Bỏ giới hạn hủy trước 24 giờ
- ✅ Dialog xác nhận với chi tiết phí phạt
- ✅ Sửa lỗi type mismatch (Member.id vs Booking.memberId)

### v1.1 - Sửa Lỗi Xác Thực
- ✅ Lưu trữ JWT token với FlutterSecureStorage
- ✅ Tự động đăng nhập khi khởi động app
- ✅ Sửa lỗi 401
- ✅ Tự động tạo member records

---

---

## 🤝 Đóng Góp

Đây là dự án sinh viên phục vụ mục đích học tập.

---

## 📄 Giấy Phép

Dự án học tập - Trường Đại học Đại Nam

---

## 📞 Liên Hệ

**Sinh viên:** Hoàng Văn Thi  
**MSSV:** 1771020643  
**Trường:** Đại học Đại Nam  
**Môn học:** Phát triển ứng dụng di động

---

**Được xây dựng với ❤️ bằng Flutter & ASP.NET Core**
