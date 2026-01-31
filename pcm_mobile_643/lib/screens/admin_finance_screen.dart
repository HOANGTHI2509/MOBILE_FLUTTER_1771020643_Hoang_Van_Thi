import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingDeposits = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get("admin/wallet/pending");
      setState(() {
        _pendingDeposits = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isStatsLoading = true);
    try {
      final response = await ApiService.get("admin/wallet/stats");
      setState(() {
        _stats = response.data;
        _isStatsLoading = false;
      });
    } catch (e) {
      setState(() => _isStatsLoading = false);
      print(e);
    }
  }

  Future<void> _approve(int id) async {
    try {
      await ApiService.put("admin/wallet/approve/$id", {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã duyệt nạp tiền!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadData();
      _loadStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _reject(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận từ chối'),
        content: const Text('Bạn có chắc muốn từ chối yêu cầu nạp tiền này?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.post("admin/wallet/reject/$id", {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã từ chối yêu cầu nạp tiền"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý Tài chính',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Duyệt Nạp tiền'),
            Tab(text: 'Báo cáo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDepositList(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildDepositList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải dữ liệu...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_pendingDeposits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Không có yêu cầu nạp tiền nào",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.blue,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pendingDeposits.length,
        itemBuilder: (context, index) {
          final item = _pendingDeposits[index];
          final member = item['member'];
          final amount = item['amount'];
          final desc = item['description'] ?? '';
          final date = item['createdDate'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.monetization_on,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member != null ? member['fullName'] : 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                                  Text(
                                    '${amount}đ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                desc,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _approve(item['id']),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Duyệt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _reject(item['id']),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Từ chối'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isStatsLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải thống kê...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_stats == null) {
      return const Center(
        child: Text('Không có dữ liệu thống kê'),
      );
    }

    final currentMonth = _stats!['currentMonth'];
    final totalDeposit = currentMonth['totalDeposit'] ?? 0;
    final totalPayment = currentMonth['totalPayment'] ?? 0;
    final totalRefund = currentMonth['totalRefund'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: Colors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê tháng này',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Tổng Nạp tiền',
              '${totalDeposit}đ',
              Icons.arrow_downward,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Tổng Thanh toán',
              '${totalPayment}đ',
              Icons.arrow_upward,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Tổng Hoàn tiền',
              '${totalRefund}đ',
              Icons.refresh,
              Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Doanh thu 6 tháng gần đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_stats!['chartData'] != null && (_stats!['chartData'] as List).isNotEmpty)
              ..._buildChartData(_stats!['chartData'])
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có dữ liệu biểu đồ'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChartData(List chartData) {
    return chartData.map<Widget>((data) {
      final month = data['month'] ?? '';
      final income = data['income'] ?? 0;
      final revenue = data['revenue'] ?? 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tháng $month',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.arrow_downward, size: 16, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text('Nạp: ', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${income}đ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.arrow_upward, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text('Doanh thu: ', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${revenue}đ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
