import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService.get('admin/wallet/stats'); // Reusing existing endpoint logic
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _weeklyStats = response.data['weeklyStats'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading dashboard stats: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart Section
              Container(
                height: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Doanh thu tháng này",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Text(
                      "12M", // Placeholder for scale, logic below handles dynamic
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _weeklyStats.isEmpty
                              ? const Center(child: Text("Chưa có dữ liệu"))
                              : BarChart(
                                  BarChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                'W${value.toInt()}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
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
                                            color: Colors.blue,
                                            width: 16,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Grid Menu
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildMenuCard(
                    context,
                    'Thành viên',
                    Icons.people,
                    Colors.orange.shade100,
                    Colors.orange,
                    const AdminMembersScreen(),
                  ),
                  _buildMenuCard(
                    context,
                    'Tài chính',
                    Icons.attach_money,
                    Colors.green.shade100,
                    Colors.green,
                    const AdminFinanceScreen(),
                  ),
                  _buildMenuCard(
                    context,
                    'Sân bãi',
                    Icons.sports_tennis,
                    Colors.blue.shade100,
                    Colors.blue,
                    const AdminCourtsScreen(),
                  ),
                  _buildMenuCard(
                    context,
                    'Giải đấu',
                    Icons.emoji_events,
                    Colors.amber.shade100,
                    Colors.amber,
                    const AdminTournamentsScreen(),
                  ),
                  _buildMenuCard(
                    context,
                    'Tin tức',
                    Icons.article,
                    Colors.purple.shade100,
                    Colors.purple,
                    const AdminNewsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color bgColor, Color iconColor, Widget? page) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng đang phát triển')),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
