import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_643.dart';
import '../services/api_service.dart';
import 'admin_finance_screen.dart';
import 'admin_members_screen.dart';
import 'admin_courts_screen.dart';
import 'admin_tournaments_screen.dart';
import 'admin_news_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _weeklyStats = [];
  bool _isLoading = true;
  double _maxRevenue = 1000000; // Default 1M

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService.get('admin/wallet/stats');
      if (response.statusCode == 200 && response.data != null) {
        final stats = response.data['weeklyStats'] as List;
        double maxVal = 0;
        for (var s in stats) {
           double val = (s['amount'] as num).toDouble();
           if (val > maxVal) maxVal = val;
        }

        if (mounted) {
          setState(() {
            _weeklyStats = stats;
            // Set max Y Slightly higher than max val for better visual
            _maxRevenue = maxVal > 0 ? maxVal * 1.2 : 5000000; 
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading dashboard stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = context.watch<AuthProvider643>().member;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // 1. Header with Profile
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blueGrey.shade900,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(member?.avatarUrl ?? "https://i.pravatar.cc/150?u=admin"),
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Dashboard',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Xin chào, ${member?.fullName ?? "Admin"}',
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
                  ),
                ),
              ),
            ),
          ),

          // 2. Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Revenue Chart Card ---
                  Container(
                    height: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Doanh thu tháng này",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Biểu đồ theo tuần",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                              child: const Icon(Icons.bar_chart, color: Colors.green),
                            )
                          ],
                        ),
                        const SizedBox(height: 25),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : BarChart(
                                  BarChartData(
                                    maxY: _maxRevenue,
                                    gridData: FlGridData(
                                      show: true, 
                                      drawVerticalLine: false,
                                      horizontalInterval: _maxRevenue / 5,
                                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                                    ),
                                    titlesData: FlTitlesData(
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0) return const SizedBox();
                                            // Format 1000000 -> 1M, 500000 -> 500k
                                            String text;
                                            if (value >= 1000000) {
                                              text = '${(value / 1000000).toStringAsFixed(1)}M';
                                            } else if (value >= 1000) {
                                              text = '${(value / 1000).toStringAsFixed(0)}k';
                                            } else {
                                              text = value.toInt().toString();
                                            }
                                            return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10));
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text('Tuần ${value.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: _weeklyStats.map((stat) {
                                      final week = stat['week'] as int;
                                      final amount = (stat['amount'] as num).toDouble();
                                      return BarChartGroupData(
                                        x: week,
                                        barRods: [
                                          BarChartRodData(
                                            toY: amount,
                                            gradient: const LinearGradient(
                                              colors: [Colors.blue, Colors.lightBlueAccent],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                            width: 20, // Wider bars
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                            backDrawRodData: BackgroundBarChartRodData(
                                              show: true,
                                              toY: _maxRevenue,
                                              color: Colors.grey.shade50,
                                            ),
                                          ),
                                        ],
                                        showingTooltipIndicators: [0]
                                      );
                                    }).toList(),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (_) => Colors.blueGrey,
                                        tooltipPadding: const EdgeInsets.all(8),
                                        tooltipMargin: 8,
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          return BarTooltipItem(
                                            NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(rod.toY),
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  const Text("Quản lý nhanh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),

                  // --- Grid Menu ---
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMenuCard(
                        context, 'Thành viên', Icons.people_outline, 
                        const [Color(0xFFff9966), Color(0xFFff5e62)], 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMembersScreen()))
                      ),
                      _buildMenuCard(
                        context, 'Tài chính', Icons.monetization_on_outlined, 
                        const [Color(0xFF56ab2f), Color(0xFFa8e063)], 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFinanceScreen()))
                      ),
                      _buildMenuCard(
                        context, 'Sân bãi', Icons.sports_tennis_outlined, 
                        const [Color(0xFF2193b0), Color(0xFF6dd5ed)], 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCourtsScreen()))
                      ),
                      _buildMenuCard(
                        context, 'Giải đấu', Icons.emoji_events_outlined, 
                        const [Color(0xFFFDC830), Color(0xFFF37335)], 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTournamentsScreen()))
                      ),
                      _buildMenuCard(
                        context, 'Tin tức', Icons.article_outlined, 
                        const [Color(0xFF8E2DE2), Color(0xFF4A00E0)], 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNewsScreen()))
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, List<Color> colors, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circle
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

