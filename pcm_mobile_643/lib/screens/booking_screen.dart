import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider_643.dart';
import '../providers/booking_provider.dart';
import '../providers/court_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/court_643.dart';
import '../models/booking_643.dart';
import '../services/signalr_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final CalendarController _calendarController = CalendarController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    // Listen to real-time updates
    SignalRService().onCalendarUpdate = () {
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lịch thi đấu đã được cập nhật mới!'), duration: Duration(seconds: 1)),
        );
      }
    };
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider643>();
    final token = authProvider.token;
    if (token != null) {
      context.read<CourtProvider>().fetchCourts(token);
      final now = DateTime.now();
      // Lấy lịch tuần hiện tại
      context.read<BookingProvider>().fetchCalendar(
        token, 
        now.subtract(const Duration(days: 7)), 
        now.add(const Duration(days: 14))
      );
    }
  }

  void _showBookingDialog(BuildContext context, DateTime startTime, Court643 court) {
    // Mặc định đặt 1 tiếng
    DateTime endTime = startTime.add(const Duration(hours: 1));
    final double totalPrice = court.pricePerHour;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận đặt sân', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.stadium, 'Sân:', court.name),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.calendar_today, 'Ngày:', DateFormat('dd/MM/yyyy').format(startTime)),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.access_time, 'Thời gian:', '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}'),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.monetization_on, 'Chi phí:', formatter.format(totalPrice)),
              
              const SizedBox(height: 20),
              const Text(
                'Lưu ý: Tiền sẽ được trừ trực tiếp vào Ví của bạn. booking sẽ bị hủy nếu không đủ số dư.', 
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey)
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Đóng dialog trước
                await _processBooking(court.id, startTime, endTime);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('XÁC NHẬN ĐẶT', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 5),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
      ],
    );
  }

  Future<void> _processBooking(int courtId, DateTime startTime, DateTime endTime) async {
    // Show Loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    final auth = context.read<AuthProvider643>();
    final bookingProvider = context.read<BookingProvider>();

    final success = await bookingProvider.createBooking(auth.token!, {
      "courtId": courtId,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
    });

    if (!mounted) return;
    Navigator.pop(context); // Tắt loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt sân THÀNH CÔNG!'), backgroundColor: Colors.green),
      );
      // Reload lại data tiền, lịch và lịch sử giao dịch
      auth.getProfile(); 
      _loadData();
      context.read<WalletProvider>().refresh(); // Cập nhật lịch sử giao dịch
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt sân THẤT BẠI. Kiểm tra số dư hoặc trùng lịch!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courtProvider = context.watch<CourtProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    
    // Convert dữ liệu Bookings sang DataSource của Syncfusion
    final dataSource = BookingDataSource(bookingProvider.bookings, courtProvider.courts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Sân Pickleball'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: courtProvider.isLoading || bookingProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : SfCalendar(
            controller: _calendarController,
            view: CalendarView.week, // Hiển thị theo tuần
            timeSlotViewSettings: const TimeSlotViewSettings(
              startHour: 5, // 5 giờ sáng
              endHour: 23, // 11 giờ đêm
              timeIntervalHeight: 80,
              timeFormat: 'HH:mm',
            ),
            backgroundColor: Colors.white,
            dataSource: dataSource,
            onTap: (CalendarTapDetails details) {
              print("🔍 [Tap] Element: ${details.targetElement}");
              
              // Chỉ xử lý khi tap vào slot trống
              if (details.targetElement == CalendarElement.calendarCell && details.date != null) {
                print("🔍 [Tap] Empty slot tapped");
                _showCourtSelection(context, details.date!);
              }
              
              // Tap vào booking để hủy
              if (details.targetElement == CalendarElement.appointment && details.appointments != null && details.appointments!.isNotEmpty) {
                final Booking643 booking = details.appointments!.first;
                final currentMemberId = context.read<AuthProvider643>().member?.id;
                
                print("🔍 [Tap] Booking tapped - ID: ${booking.id}, MemberId: ${booking.memberId} (${booking.memberId.runtimeType}), CurrentMemberId: $currentMemberId (${currentMemberId.runtimeType}), Status: ${booking.status}");
                
                // Fix: Convert both to string for comparison (type mismatch issue)
                final bookingMemberIdStr = booking.memberId.toString();
                final currentMemberIdStr = currentMemberId?.toString();
                
                if (currentMemberId != null && bookingMemberIdStr == currentMemberIdStr && booking.status != BookingStatus.Cancelled) {
                  print("✅ [Tap] Showing cancel dialog");
                  _showCancelConfirmationDialog(context, booking);
                } else {
                  print("❌ [Tap] Cannot cancel - bookingMemberIdStr=$bookingMemberIdStr, currentMemberIdStr=$currentMemberIdStr, match=${bookingMemberIdStr == currentMemberIdStr}");
                }
              }
            },
            appointmentBuilder: (context, details) {
              final Booking643 booking = details.appointments.first;
              return Container(
                decoration: BoxDecoration(
                  color: booking.memberId == context.read<AuthProvider643>().member?.id 
                      ? Colors.blue.withOpacity(0.8) 
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.memberId == context.read<AuthProvider643>().member?.id ? "BẠN" : "Đã đặt",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  // Hiển thị dialog xác nhận hủy sân với cảnh báo phạt 50%
  void _showCancelConfirmationDialog(BuildContext context, Booking643 booking) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final refundAmount = booking.totalPrice * 0.5;
    final penalty = booking.totalPrice * 0.5;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Xác nhận hủy sân', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thời gian: ${DateFormat('HH:mm - dd/MM/yyyy').format(booking.startTime)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Chính sách hủy sân:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    Text('• Phí hủy: ${formatter.format(penalty)} (50%)'),
                    Text('• Hoàn lại: ${formatter.format(refundAmount)} (50%)', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Bạn có chắc chắn muốn hủy booking này?',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('KHÔNG', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Đóng dialog
                await _processCancellation(context, booking.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('ĐỒNG Ý HỦY', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processCancellation(BuildContext context, int bookingId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final auth = context.read<AuthProvider643>();
    final bookingProvider = context.read<BookingProvider>();

    final result = await bookingProvider.cancelBooking(auth.token!, bookingId);

    if (!mounted) return;
    Navigator.pop(context); // Tắt loading

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['message']} - Hoàn lại: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(result['refundAmount'])}'),
          backgroundColor: Colors.green,
        ),
      );
      // Reload data và lịch sử giao dịch
      auth.getProfile();
      _loadData();
      context.read<WalletProvider>().refresh(); // Cập nhật lịch sử giao dịch
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hủy sân THẤT BẠI!'), backgroundColor: Colors.red),
      );
    }
  }

  // Chọn sân khi bấm vào lịch
  void _showCourtSelection(BuildContext context, DateTime date) {
    if (date.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đặt thời gian trong quá khứ!')),
      );
      return;
    }

    final courts = context.read<CourtProvider>().courts;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn sân muốn đặt', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)
              ),
              const SizedBox(height: 10),
              Text(
                'Thời gian: ${DateFormat('HH:mm - dd/MM/yyyy').format(date)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: courts.length,
                  itemBuilder: (ctx, i) {
                    final court = courts[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.sports_tennis, color: Colors.green),
                        title: Text(court.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ/h').format(court.pricePerHour)),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showBookingDialog(context, date, court);
                          },
                          child: const Text('Chọn'),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// Cấu hình Nguồn Dữ Liệu cho Lịch
class BookingDataSource extends CalendarDataSource {
  BookingDataSource(List<Booking643> source, List<Court643> courts) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) => appointments![index].startTime;

  @override
  DateTime getEndTime(int index) => appointments![index].endTime;

  @override
  String getSubject(int index) => "Đã đặt";

  @override
  Color getColor(int index) => Colors.red;

  @override
  bool isAllDay(int index) => false;
}
