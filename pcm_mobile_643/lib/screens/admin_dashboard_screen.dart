import 'package:flutter/material.dart';
import 'admin_finance_screen.dart';
import 'admin_members_screen.dart';
import 'admin_courts_screen.dart';
import 'admin_tournaments_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blueGrey,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _buildMenuCard(context, Icons.people, 'Thành viên', Colors.orange, const AdminMembersScreen()),
          _buildMenuCard(context, Icons.attach_money, 'Tài chính', Colors.green, const AdminFinanceScreen()),
          _buildMenuCard(context, Icons.sports_tennis, 'Sân bãi', Colors.blue, const AdminCourtsScreen()),
          _buildMenuCard(context, Icons.emoji_events, 'Giải đấu', Colors.amber, const AdminTournamentsScreen()),
          _buildMenuCard(context, Icons.article, 'Tin tức', Colors.purple, null), // TODO
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, IconData icon, String label, Color color, Widget? screen) {
    return InkWell(
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển')));
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 15),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
