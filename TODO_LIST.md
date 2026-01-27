# DANH SÁCH CHỨC NĂNG CẦN HOÀN THIỆN - PCM SYSTEM

Dựa trên yêu cầu của đề tài "CLB Vợt Thủ Phố Núi", dưới đây là các hạng mục công việc còn lại cần triển khai:

## 1. BACKEND API (ASP.NET Core)
*Ưu tiên: Cao*
- [ ] **Đặt sân định kỳ (Recurring Booking):** 
  - API `POST /api/bookings/recurring`.
  - Logic: Nhận vào quy tắc lặp (VD: Thứ 3, Thứ 5), kiểm tra trống lịch cho tất cả các ngày, trừ tổng tiền ví và sinh hàng loạt record Booking.
- [ ] **Hủy đặt sân (Cancel Booking):** 
  - API `POST /api/bookings/cancel/{id}`.
  - Logic: Kiểm tra thời gian hủy (trước 24h?), hoàn lại tiền vào Ví, đổi trạng thái Booking, tạo Transaction hoàn tiền.
- [ ] **Xếp lịch tự động (Auto-Scheduler):** 
  - API `POST /api/tournaments/{id}/generate-schedule`.
  - Logic: Lấy danh sách người tham gia, chia cặp đấu (Vòng tròn hoặc Loại trực tiếp) và tạo dữ liệu vào bảng `Matches`.
- [ ] **SignalR Real-time:**
  - Tạo `PcmHub`.
  - Cấu hình gửi thông báo realtime khi: Có người đặt sân (đổi màu ô lịch), Có kết quả trận đấu, Nạp tiền thành công.
- [ ] **Background Services:**
  - `AutoCancelService`: Chạy ngầm mỗi phút, tìm Booking "Pending" quá 5 phút để hủy và nhả sân.

## 2. MOBILE APP (Flutter)
*Ưu tiên: Cao*
- [ ] **Module Giải đấu (Tournaments):**
  - Màn hình Danh sách giải đấu (Filter: Đang đăng ký, Đang diễn ra, Đã xong).
  - Màn hình Chi tiết giải đấu: Hiển thị thông tin, lệ phí, giải thưởng.
  - **Nút "Tham gia ngay":** Gọi API Join Tournament, trừ tiền ví.
  - **Cây thi đấu (Bracket View):** Vẽ sơ đồ thi đấu trực quan (Vòng loại -> Bán kết -> Chung kết).
- [ ] **Màn hình Thông báo (Notifications):**
  - Danh sách thông báo, đánh dấu đã đọc.
- [ ] **Chức năng Admin (Trên App):**
  - Màn hình Dashboard thống kê doanh thu/số lượng booking (Chỉ hiện nếu user là Admin).
  - Duyệt yêu cầu nạp tiền (nếu chưa làm xong UI).
- [ ] **Tích hợp Real-time (SignalR Client):**
  - Cài package, lắng nghe sự kiện để cập nhật UI lịch và thông báo ngay lập tức.

## 3. CHỨC NĂNG NÂNG CAO (Bonus)
- [ ] **Thanh toán QR:** Tích hợp SDK/Deep link ngân hàng (Fake logic).
- [ ] **Xuất báo cáo:** Chức năng xuất Excel/PDF doanh thu.
- [ ] **Biometric Login:** Đăng nhập vân tay.

---
**TRẠNG THÁI HIỆN TẠI:**
- [x] Database & Models (Full).
- [x] Auth & Member Profile.
- [x] Hệ thống Ví (Nạp, Rút, Lịch sử).
- [x] Đặt sân cơ bản (Booking lẻ) & Xem lịch.
