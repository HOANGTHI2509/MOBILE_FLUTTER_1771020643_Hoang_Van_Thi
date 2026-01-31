import 'dart:async';
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
import '../services/api_service.dart'; // Add this line

import 'package:intl/date_symbol_data_local.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final CalendarController _calendarController = CalendarController();
  Court643? _selectedCourt;



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

  // --- Step 1: Select Court ---
  Widget _buildCourtList(List<Court643> courts) {
    // Remove Scaffold wrapper as it's now inside a TabBarView
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courts.length,
        itemBuilder: (ctx, i) {
          final court = courts[i];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCourt = court;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      height: 60, width: 60,
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.sports_tennis, color: Colors.green, size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(court.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ/h').format(court.pricePerHour), 
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      );
  }

  // --- Step 2: Custom Date & Time Picker ---
  DateTime _selectedDate = DateTime.now();
  late DateTime _currentMonth;
  late List<DateTimeRange> _weeksOfMonth;
  late DateTimeRange _selectedWeek;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi', null).then((_) {
      if (mounted) setState(() {});
    });

    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _calculateWeeks(_currentMonth);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    SignalRService().onCalendarUpdate = () {
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lịch thi đấu đã được cập nhật mới!'), duration: Duration(seconds: 1)),
        );
      }
    };
  }

  void _calculateWeeks(DateTime month) {
    // Find the first day of the month
    DateTime firstDay = DateTime(month.year, month.month, 1);
    // Find the last day
    DateTime lastDay = DateTime(month.year, month.month + 1, 0);
    
    _weeksOfMonth = [];
    
    // Start from the first day, find the start of that week (Monday)
    // Adjust if you want weeks to start on Monday
    DateTime currentStart = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    
    while (currentStart.isBefore(lastDay)) {
      DateTime currentEnd = currentStart.add(const Duration(days: 6));
      _weeksOfMonth.add(DateTimeRange(start: currentStart, end: currentEnd));
      currentStart = currentStart.add(const Duration(days: 7));
    }

    // Select the week containing the current _selectedDate, or the first week
    _selectedWeek = _weeksOfMonth.firstWhere(
      (w) => !(_selectedDate.isBefore(w.start) || _selectedDate.isAfter(w.end.add(const Duration(days: 1)))), // loose check
      orElse: () => _weeksOfMonth.first
    );
  }

  Widget _buildCalendar(BuildContext context, Court643 court) {
    final bookingProvider = context.watch<BookingProvider>();
    final courtBookings = bookingProvider.bookings.where((b) => b.courtId == court.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(court.name),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedCourt = null),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: Column(
        children: [
          _buildMonthWeekSelector(),
          _buildDayRow(),
          const Divider(height: 1),
          Expanded(
            child: _buildTimeSlotGrid(courtBookings, court),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthWeekSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Month Selector
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.indigo),
              const SizedBox(width: 10),
              DropdownButton<DateTime>(
                value: _currentMonth,
                underline: Container(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16),
                items: List.generate(12, (index) {
                  return DateTime(DateTime.now().year, DateTime.now().month + index);
                }).map((date) {
                  return DropdownMenuItem(
                    value: date,
                    child: Text("Tháng ${DateFormat('MM/yyyy').format(date)}"),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _currentMonth = val;
                      _calculateWeeks(_currentMonth);
                      _selectedDate = _weeksOfMonth.first.start; // Reset date to start of new month/week
                      if (_selectedDate.isBefore(DateTime.now())) _selectedDate = DateTime.now(); // No past
                    });
                  }
                },
              ),
            ],
          ),
          // Week Selector
          Row(
            children: [
              const Icon(Icons.date_range, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<DateTimeRange>(
                  isExpanded: true,
                  value: _weeksOfMonth.contains(_selectedWeek) ? _selectedWeek : _weeksOfMonth.first,
                  underline: Container(height: 1, color: Colors.grey.shade300),
                  items: _weeksOfMonth.map((range) {
                    final label = "Tuần: ${DateFormat('dd/MM').format(range.start)} - ${DateFormat('dd/MM').format(range.end)}";
                    return DropdownMenuItem(value: range, child: Text(label));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedWeek = val;
                        // Select Monday of that week by default
                        _selectedDate = val.start;
                      });
                    }
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDayRow() {
    // Generate 7 days of selected week
    List<DateTime> days = [];
    for (int i = 0; i < 7; i++) {
      days.add(_selectedWeek.start.add(Duration(days: i)));
    }

    return Container(
      height: 80,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = DateFormat('dd/MM').format(date) == DateFormat('dd/MM').format(_selectedDate);
          final isToday = DateFormat('dd/MM').format(date) == DateFormat('dd/MM').format(DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : (isToday ? Colors.green.shade50 : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(DateFormat('EEE', 'vi').format(date), 
                     style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.grey)),
                   const SizedBox(height: 4),
                   Text(date.day.toString(), 
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<Booking643> bookings, Court643 court) {
    // Generate slots from 05:00 to 22:00 (Last slot 22-23)
    final slots = List.generate(18, (index) => 5 + index); // 5, 6, ..., 22

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final hour = slots[index];
        final startTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour);
        final endTime = startTime.add(const Duration(hours: 1));
        
        DateTime now = DateTime.now();
        // Prevent booking in past today
        if (_selectedDate.day == now.day && _selectedDate.month == now.month && hour <= now.hour) {
             return _buildSlotItem(hour, "Qua gi", Colors.grey.shade300, Colors.grey, null);
        }

        // Check availability
        Booking643? conflict;
        try {
           conflict = bookings.firstWhere((b) => 
            (b.startTime.isBefore(endTime) && b.endTime.isAfter(startTime)) && 
            b.status != BookingStatus.Cancelled
          );
        } catch (_) {}

        if (conflict != null) {
          final currentMemberId = context.read<AuthProvider643>().member?.id;
          if (conflict.status == BookingStatus.PendingPayment) {
             return _buildSlotItem(hour, "Đang giữ", Colors.orange.shade100, Colors.deepOrange, null);
          } else if (currentMemberId != null && conflict.memberId.toString() == currentMemberId.toString()) { // Ensure String comparison
             return _buildSlotItem(hour, "Đã đặt", Colors.amber, Colors.black, () {
               _showCancelDialog(conflict!);
             });
          } else {
             return _buildSlotItem(hour, "Đã kín", Colors.grey.shade400, Colors.white, null);
          }
        }

        // Available
        return _buildSlotItem(hour, "Trống", Colors.white, Colors.green, () {
           _processHoldBooking(court, startTime);
        });
      },
    );
  }

  void _showCancelDialog(Booking643 booking) {
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: const Text("Hủy đặt sân?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bạn có chắc muốn hủy lịch đặt này không?"),
            const SizedBox(height: 10),
            Text("Thời gian: ${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('dd/MM').format(booking.startTime)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("⚠️ Lưu ý: Phí hủy sân là 50% giá trị đặt sân.", style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Quay lại")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
               Navigator.pop(context);
               // Call Cancel API
               final auth = context.read<AuthProvider643>();
               final result = await context.read<BookingProvider>().cancelBooking(auth.token!, booking.id);
               
               if (result != null) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy sân thành công. Tiền hoàn đã cộng vào ví.')));
                 _loadData();
                 context.read<WalletProvider>().refresh();
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hủy thất bại. Vui lòng thử lại.')));
               }
            }, 
            child: const Text("Hủy sân (-50%)", style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }

  Widget _buildSlotItem(int hour, String status, Color bg, Color text, VoidCallback? onTap) {
    bool isAvailable = status == "Trống";
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: isAvailable ? Border.all(color: Colors.green) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${hour}:00', style: TextStyle(fontWeight: FontWeight.bold, color: text)),
            Text(status, style: TextStyle(fontSize: 10, color: text)),
          ],
        ),
      ),
    );
  }

  Future<void> _processHoldBooking(Court643 court, DateTime startTime) async {
    // 1 hour default
    DateTime endTime = startTime.add(const Duration(hours: 1));
    
    // Show Loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    final auth = context.read<AuthProvider643>();
    final bookingProvider = context.read<BookingProvider>();

    // Call Hold API
    Booking643? heldBooking = await bookingProvider.holdBooking(auth.token!, {
      "courtId": court.id,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
    });

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (heldBooking != null) {
       // Show Confirm Dialog with Timer
       _showPaymentDialog(context, heldBooking, court);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sân đã bị người khác đặt hoặc giữ!'), backgroundColor: Colors.red));
    }
  }

  void _showPaymentDialog(BuildContext context, Booking643 booking, Court643 court) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // 5 minutes countdown
    int timeLeft = 300; 
    Timer? _timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Start timer once
            _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (timeLeft > 0) {
                setState(() => timeLeft--);
              } else {
                timer.cancel();
                Navigator.pop(context); // Close dialog on timeout
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hết thời gian giữ chỗ!')));
              }
            });

            String minutes = (timeLeft ~/ 60).toString().padLeft(2, '0');
            String seconds = (timeLeft % 60).toString().padLeft(2, '0');

            return AlertDialog(
              title: const Text('Xác nhận thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Icon(Icons.timer, color: Colors.orange),
                         const SizedBox(width: 10),
                         Text("Giữ chỗ trong: $minutes:$seconds", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)),
                       ],
                     ),
                   ),
                   const SizedBox(height: 20),
                   _buildInfoRow(Icons.stadium, 'Sân:', court.name),
                   _buildInfoRow(Icons.calendar_today, 'Ngày:', DateFormat('dd/MM/yyyy').format(booking.startTime)),
                   _buildInfoRow(Icons.access_time, 'Giờ:', '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}'),
                   Divider(),
                   _buildInfoRow(Icons.monetization_on, 'Tổng tiền:', formatter.format(booking.totalPrice)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    _timer?.cancel();
                    
                    // Call API to cancel the pending booking immediately
                    final auth = context.read<AuthProvider643>();
                    await context.read<BookingProvider>().cancelBooking(auth.token!, booking.id);

                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadData(); // Refresh grid to remove "Processing" status
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy giữ chỗ.')));
                    }
                  },
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _timer?.cancel();
                    Navigator.pop(context);
                    await _processConfirmBooking(booking.id);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('THANH TOÁN', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    ).then((_) => _timer?.cancel());
  }

  Future<void> _processConfirmBooking(int bookingId) async {
      final auth = context.read<AuthProvider643>();
      final success = await context.read<BookingProvider>().confirmBooking(auth.token!, bookingId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt sân THÀNH CÔNG!'), backgroundColor: Colors.green));
        auth.getProfile();
        _loadData();
        context.read<WalletProvider>().refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanh toán thất bại! Hết giờ hoặc không đủ tiền.'), backgroundColor: Colors.red));
      }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // --- Toggle ---
  bool _isRecurring = false;
  
  // --- Recurring State ---
  DateTimeRange? _recurringRange;
  Set<int> _selectedWeekDays = {}; // 1 (Mon) -> 7 (Sun)
  int? _selectedRecurringHour; // 5..22

  // --- History State ---
  List<dynamic> _historyBookings = [];
  String _historyFilter = "All"; // All, Confirmed, Cancelled
  bool _isLoadingHistory = false;

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final response = await ApiService.get('Bookings/my-history');
    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
        if (response.statusCode == 200) {
          _historyBookings = response.data;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đặt Sân Pickleball'),
          backgroundColor: Colors.green,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Đặt sân"),
              Tab(text: "Lịch sử"),
            ],
          ),
          leading: const BackButton(), // Ensure back button works if pushed
        ),
        body: TabBarView(
          children: [
            // Tab 1: Booking Flow (Existing)
            _buildBookingTab(context),
            // Tab 2: History (New)
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTab(BuildContext context) {
     final courts = context.watch<CourtProvider>().courts;
     
     if (_selectedCourt == null) {
       return _buildCourtList(courts);
     } else {
       return Scaffold(
         // Remove AppBar here since parent has one, or keep for Court details
         // To stay consistent with previous code which pushed context, we can just show body
         // But previous code had full Scaffold. Let's adapt.
         appBar: AppBar(
          title: Text(_selectedCourt!.name),
          backgroundColor: Colors.green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _selectedCourt = null),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  _buildTab("Đặt lẻ", !_isRecurring, () => setState(() => _isRecurring = false)),
                  _buildTab("Đặt định kỳ (VIP)", _isRecurring, () {
                    final member = context.read<AuthProvider643>().member;
                    bool isVip = member?.tier == 'Gold' || member?.tier == 'Diamond';
                    
                    if (isVip) {
                      setState(() => _isRecurring = true);
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Row(children: [Icon(Icons.lock, color: Colors.orange), SizedBox(width: 10), Text("Tính năng VIP")]),
                          content: const Text("Chức năng Đặt sân định kỳ chỉ dành cho thành viên hạng Vàng (Gold) trở lên (Chi tiêu > 10.000.000đ).\n\nHãy đặt thêm sân để nâng hạng ngay!"),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đã hiểu"))],
                        )
                      );
                    }
                  }, isLocked: !(context.read<AuthProvider643>().member?.tier == 'Gold' || context.read<AuthProvider643>().member?.tier == 'Diamond')),
                ],
              ),
            ),
          )
         ),
         body: _isRecurring 
            ? _buildRecurringConfig(context, _selectedCourt!)
            : Column(
                children: [
                   _buildMonthWeekSelector(),
                   _buildDayRow(),
                   const Divider(height: 1),
                   Expanded(child: _buildTimeSlotGrid(context.watch<BookingProvider>().bookings.where((b) => b.courtId == _selectedCourt!.id).toList(), _selectedCourt!)),
                ],
              )
       );
     }
  }

  Widget _buildHistoryTab() {
    // Re-fetch when entering this tab? For simplicity, fetch on build if empty or add RefreshIndicator
    if (_historyBookings.isEmpty && !_isLoadingHistory) _loadHistory();

    final filtered = _historyBookings.where((b) {
       if (_historyFilter == "All") return true;
       // Status Enum: 1=Confirmed, 2=Cancelled, 3=Completed
       if (_historyFilter == "Confirmed") return b['status'] == 1 || b['status'] == 3;
       if (_historyFilter == "Cancelled") return b['status'] == 2;
       return true;
    }).toList();

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _buildFilterChip("Tất cả", "All"),
              const SizedBox(width: 10),
              _buildFilterChip("Đã đặt", "Confirmed"),
              const SizedBox(width: 10),
              _buildFilterChip("Đã hủy", "Cancelled"),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadHistory,
            child: _isLoadingHistory 
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty 
                  ? const Center(child: Text("Không có lịch sử đặt sân"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final b = filtered[i];
                        final status = b['status'];
                        Color color = Colors.green;
                        String statusText = "Thành công";
                        if (status == 2) { color = Colors.red; statusText = "Đã hủy"; }
                        if (status == 3) { color = Colors.grey; statusText = "Hoàn thành"; }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(status == 2 ? Icons.cancel : Icons.check_circle, color: color),
                            ),
                            title: Text(b['name'] ?? 'Sân', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${DateFormat('dd/MM/yyyy').format(DateTime.parse(b['startTime']))} | ${DateFormat('HH:mm').format(DateTime.parse(b['startTime']))} - ${DateFormat('HH:mm').format(DateTime.parse(b['endTime']))}'),
                                Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(b['totalPrice'])),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text(statusText, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }
                    ),
          ),
        )
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool selected = _historyFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: Colors.green.shade100,
      labelStyle: TextStyle(color: selected ? Colors.green : Colors.black),
      onSelected: (val) {
        if (val) setState(() => _historyFilter = value);
      },
    );
  }

  Widget _buildTab(String title, bool isActive, VoidCallback onTap, {bool isLocked = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? Colors.green : Colors.transparent, width: 3))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(
                color: isActive ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold
              )),
              if (isLocked) ...[
                const SizedBox(width: 5),
                const Icon(Icons.lock, size: 14, color: Colors.grey)
              ]
            ],
          ),
        ),
      ),
    );
  }

  // --- Recurring UI ---
  Widget _buildRecurringConfig(BuildContext context, Court643 court) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Select Date Range
        Card(
          child: ListTile(
            leading: const Icon(Icons.date_range, color: Colors.indigo),
            title: const Text("Chọn khoảng thời gian"),
            subtitle: Text(_recurringRange == null 
              ? "Chưa chọn ngày bắt đầu - kết thúc" 
              : "${DateFormat('dd/MM/yyyy').format(_recurringRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_recurringRange!.end)}"),
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context, 
                firstDate: DateTime.now(), 
                lastDate: DateTime.now().add(const Duration(days: 365))
              );
              if (picked != null) setState(() => _recurringRange = picked);
            },
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Select Days of Week
        const Text("Chọn ngày trong tuần:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: List.generate(7, (index) {
            int day = index + 1; // 1 Mon .. 7 Sun
            bool isSelected = _selectedWeekDays.contains(day);
            return FilterChip(
              label: Text(day == 7 ? "CN" : "T${day + 1}"),
              selected: isSelected,
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green,
              onSelected: (val) {
                setState(() {
                  if (val) _selectedWeekDays.add(day); else _selectedWeekDays.remove(day);
                });
              },
            );
          }),
        ),
        const SizedBox(height: 16),

        // 3. Select Time
        const Text("Chọn khung giờ (Cố định):", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: List.generate(18, (index) {
            final hour = 5 + index;
            bool isSelected = _selectedRecurringHour == hour;
            return ChoiceChip(
              label: Text("$hour:00"),
              selected: isSelected,
              selectedColor: Colors.green,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              onSelected: (val) => setState(() => _selectedRecurringHour = val ? hour : null),
            );
          }),
        ),
        
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _processRecurringBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 15)
          ),
          child: const Text("KIỂM TRA & THANH TOÁN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Future<void> _processRecurringBooking() async {
    if (_recurringRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn khoảng thời gian!')));
      return;
    }
    if (_selectedWeekDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ngày trong tuần!')));
      return;
    }
    if (_selectedRecurringHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn khung giờ!')));
      return;
    }

    // Convert Dart weekday (1..7) to C# DayOfWeek (1..6, 0)
    List<int> cSharpDays = _selectedWeekDays.map((d) => d % 7).toList();

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    final auth = context.read<AuthProvider643>();
    final error = await context.read<BookingProvider>().createRecurringBooking(auth.token!, {
       "courtId": _selectedCourt!.id,
       "startDate": _recurringRange!.start.toIso8601String(),
       "endDate": _recurringRange!.end.toIso8601String(),
       "startTime": "${_selectedRecurringHour.toString().padLeft(2,'0')}:00:00",
       "endTime": "${(_selectedRecurringHour! + 1).toString().padLeft(2,'0')}:00:00",
       "daysOfWeek": cSharpDays
    });

    if (!mounted) return;
    Navigator.pop(context);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt sân định kỳ THÀNH CÔNG!')));
      setState(() {
        _isRecurring = false;
        _selectedCourt = null; // Back to list
      });
      _loadData(); // Refresh calendar to see new bookings
      context.read<WalletProvider>().refresh();
    } else {
       showDialog(
         context: context,
         builder: (_) => AlertDialog(
           title: const Text("Đặt sân thất bại"),
           content: Text(error),
           actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))],
         )
       );
    }
  }

  }


class BookingDataSource extends CalendarDataSource {
  BookingDataSource(List<Booking643> source) {
    appointments = source;
  }
  @override
  DateTime getStartTime(int index) => appointments![index].startTime;
  @override
  DateTime getEndTime(int index) => appointments![index].endTime;
  @override
  String getSubject(int index) => "Booked";
}
