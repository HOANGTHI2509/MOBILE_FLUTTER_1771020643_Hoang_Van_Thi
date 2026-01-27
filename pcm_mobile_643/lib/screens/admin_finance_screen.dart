import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart'; // Uncomment when using charts
import '../services/api_service.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingDeposits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
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

  Future<void> _approve(int id) async {
    try {
      await ApiService.put("admin/wallet/approve/$id", {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã duyệt nạp tiền!")));
      _loadData(); // Reload list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài chính'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Duyệt Nạp tiền'), Tab(text: 'Báo cáo')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDepositList(),
          const Center(child: Text('Biểu đồ doanh thu đang cập nhật...')), // Placeholder for Stats
        ],
      ),
    );
  }

  Widget _buildDepositList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_pendingDeposits.isEmpty) return const Center(child: Text("Không có yêu cầu nạp tiền nào."));

    return ListView.builder(
      itemCount: _pendingDeposits.length,
      itemBuilder: (context, index) {
        final item = _pendingDeposits[index];
        final member = item['member'];
        final amount = item['amount'];
        final desc = item['description'];
        final date = item['createdDate'];

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.monetization_on, color: Colors.orange, size: 40),
            title: Text("${member != null ? member['fullName'] : 'Unknown'} nạp ${amount}đ"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc),
                Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _approve(item['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () {}, // Reject logic
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
