import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider_643.dart';
import '../providers/booking_provider.dart';
import '../providers/court_provider.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';
import 'user_schedule_screen.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  List<dynamic> _newsList = [];
  List<FlSpot> _rankSpots = [];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _loadNews();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider643>();
      if (auth.token != null) {
        context.read<BookingProvider>().fetchCalendar(
            auth.token!,
            DateTime.now(),
            DateTime.now().add(const Duration(days: 7)));
        _fetchRankHistory(auth.token!);
      }
    });
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_pageController.hasClients) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage > 2) nextPage = 0;
        _pageController.animateToPage(nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
        setState(() => _currentBannerIndex = nextPage);
        _startAutoScroll();
      }
    });
  }

  Future<void> _loadNews() async {
    try {
      final response = await ApiService.get('News');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _newsList = (response.data as List).take(5).toList();
          });
        }
      }
    } catch (e) {
      print("Error loading news: $e");
    }
  }

  Future<void> _fetchRankHistory(String token) async {
    // Mock Data for now as backend might not have this endpoint ready
    // Or you can implement it later.
    setState(() {
      _rankSpots = [
        const FlSpot(0, 1),
        const FlSpot(1, 1.5),
        const FlSpot(2, 1.2),
        const FlSpot(3, 2.0),
        const FlSpot(4, 2.5),
        const FlSpot(5, 3.0),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Safely get bookings
    final bookingProvider = context.watch<BookingProvider>();
    final myBookings = bookingProvider.bookings
        .where((b) => b.memberId == context.read<AuthProvider643>().member?.id && b.status == 1 && b.startTime.isAfter(DateTime.now()))
        .toList();
    
    // Sort by startTime
    myBookings.sort((a, b) => a.startTime.compareTo(b.startTime));

    final member = context.watch<AuthProvider643>().member;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.green.shade100,
                        backgroundImage: member?.avatarUrl != null
                            ? NetworkImage(member!.avatarUrl!)
                            : null,
                        child: member?.avatarUrl == null
                            ? const Icon(Icons.person,
                                color: Colors.green, size: 30)
                            : null),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Xin chào,",
                              style: TextStyle(color: Colors.grey.shade600)),
                          Text(member?.fullName ?? "Khách",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          if (member != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildRankBadge(member.tier ?? "Silver"),
                                const SizedBox(width: 8),
                                Text(
                                    "Ví: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(member.walletBalance)}",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            )
                          ]
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {}),
                    IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () {
                          context.read<AuthProvider643>().logout();
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()));
                        })
                  ],
                ),
              ),

              // 1. Banner Slider
              SizedBox(
                height: 180,
                child: PageView(
                  controller: _pageController,
                  children: [
                    _buildBannerItem(Colors.green, "Đặt sân nhanh chóng",
                        "Ưu đãi 20% cho thành viên mới"),
                    _buildBannerItem(Colors.orange, "Giải đấu chuyên nghiệp",
                        "Đăng ký tham gia ngay hôm nay"),
                    _buildBannerItem(Colors.blue, "Huấn luyện viên VIP",
                        "Nâng cao kỹ năng cùng chuyên gia"),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    3,
                    (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentBannerIndex == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: _currentBannerIndex == index
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4)),
                        )),
              ),
              const SizedBox(height: 20),

              // 1.5 News Section (NEW)
              if (_newsList.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text('Tin tức mới nhất',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _newsList.length,
                    itemBuilder: (ctx, i) {
                      final news = _newsList[i];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade200, blurRadius: 5)
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Text("HOT",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(news['title'] ?? 'No Title',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const Spacer(),
                            Text(
                              news['createdDate'] != null
                                  ? DateFormat('dd/MM').format(
                                      DateTime.parse(news['createdDate']))
                                  : '',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 2. Grid Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildMenuItem(
                            Icons.sports_tennis, "Đặt sân", Colors.green, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BookingScreen()));
                    })),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildMenuItem(
                            Icons.emoji_events, "Giải đấu", Colors.orange,
                            () {
                       // Navigate to Tournament
                    })),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildMenuItem(
                            Icons.group, "Cộng đồng", Colors.blue, () {
                       // Navigate to Community
                    })),
                    if (member?.isAdmin == true) ...[
                       const SizedBox(width: 10),
                       Expanded(
                        child: _buildMenuItem(
                            Icons.admin_panel_settings, "Admin", Colors.red, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                        })),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Upcoming Schedule
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lịch sắp tới của bạn',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UserScheduleScreen())),
                        child: const Text("Xem tất cả"))
                  ],
                ),
              ),

              if (myBookings.isEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.blue, size: 40),
                      const SizedBox(height: 10),
                      const Text("Bạn chưa có lịch đặt sân nào.",
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BookingScreen())),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white),
                        child: const Text("Đặt sân ngay"),
                      )
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: myBookings.length > 3
                      ? 3
                      : myBookings.length, // Show max 3
                  itemBuilder: (ctx, i) {
                    final b = myBookings[i];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('dd').format(b.startTime),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green)),
                              Text(DateFormat('MM').format(b.startTime),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.green)),
                            ],
                          ),
                        ),
                        title: Text(
                            "Sân: ${b.courtId == 1 ? 'Sân 1 (VIP)' : 'Sân ${b.courtId}'}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "${DateFormat('HH:mm').format(b.startTime)} - ${DateFormat('HH:mm').format(b.endTime)}"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Text("Sắp tới",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text('Thống kê hoạt động',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                height: 200,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade200, blurRadius: 5)
                    ]),
                child: _rankSpots.isEmpty
                    ? const Center(
                        child: Text("Chưa có dữ liệu lịch sử Rank",
                            style: TextStyle(color: Colors.grey)))
                    : LineChart(LineChartData(
                        gridData:
                            FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1)),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < _rankSpots.length) {
                                      return Text(
                                          (value.toInt() + 1).toString(),
                                          style: const TextStyle(fontSize: 10));
                                    }
                                    return const Text('');
                                  })),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: _rankSpots.isEmpty
                            ? 6
                            : (_rankSpots.length - 1).toDouble(),
                        minY: 0,
                        maxY: 6, // Assuming max rank around 5-6
                        lineBarsData: [
                          LineChartBarData(
                            spots: _rankSpots,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                                show: true,
                                color: Colors.green.withOpacity(0.1)),
                          )
                        ])),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerItem(Color color, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: const Offset(0, 5))
          ]),
      child: Stack(
        children: [
          Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.sports_tennis,
                  size: 120, color: Colors.white.withOpacity(0.2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ],
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(String tier) {
    Color color = Colors.grey;
    if (tier == 'Gold') color = Colors.amber;
    if (tier == 'Diamond') color = Colors.lightBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.white24, borderRadius: BorderRadius.circular(10)),
      child: Text(tier,
          style: const TextStyle(
              fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}