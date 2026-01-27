## Hướng dẫn Test Hủy Sân

### Bước 1: Restart App
```powershell
# Tắt app hiện tại (Ctrl+C)
# Chạy lại:
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=C:/tmp/pcm_chrome_v8"
```

### Bước 2: Mở Developer Console
- Nhấn **F12** trong Chrome
- Chọn tab **Console**

### Bước 3: Tap vào Booking
- Tap vào **booking màu xanh** (BẠN)
- Xem log trong Console:

**Nếu thấy:**
```
🔍 [Tap] Element: CalendarElement.appointment
🔍 [Tap] Booking tapped - ID: 1, MemberId: 2, CurrentMemberId: 2, Status: BookingStatus.Confirmed
✅ [Tap] Showing cancel dialog
```
→ **OK!** Dialog sẽ hiện

**Nếu thấy:**
```
❌ [Tap] Cannot cancel - Not owner or already cancelled
```
→ **Booking không phải của bạn** hoặc đã hủy rồi

### Bước 4: Nếu vẫn không hiện
Gửi log trong Console cho em xem!
