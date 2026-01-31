import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class UserScheduleScreen extends StatefulWidget {
  const UserScheduleScreen({super.key});

  @override
  State<UserScheduleScreen> createState() => _UserScheduleScreenState();
}

class _UserScheduleScreenState extends State<UserScheduleScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final response = await ApiService.get('Bookings/my-history');
      if (response.statusCode == 200) {
        final allBookings = response.data as List;
        // Client-side filter for "Upcoming" (Confirmed/Completed and Future)
        // Note: For strict "Schedule", strictly future confirmed bookings.
        final now = DateTime.now();
        final upcoming = allBookings.where((b) {
          final end = DateTime.parse(b['endTime']);
          final status = b['status']; 
          // Assuming Status 1: Confirmed. 
          return end.isAfter(now) && status == 1; 
        }).toList();

        // Sort ascending for upcoming
        upcoming.sort((a, b) => DateTime.parse(a['startTime']).compareTo(DateTime.parse(b['startTime'])));

        setState(() {
          _bookings = upcoming;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading schedule: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sắp Tới'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text("Bạn không có lịch đặt sân sắp tới."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (ctx, i) {
                    final booking = _bookings[i];
                    final start = DateTime.parse(booking['startTime']);
                    final end = DateTime.parse(booking['endTime']);
                    final price = booking['totalPrice'];
                    
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.green, width: 5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  booking['name'] ?? 'Sân ??',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Sắp tới', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('EEEE, dd/MM/yyyy', 'vi').format(start),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Giá thuê:"),
                                Text(
                                  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
