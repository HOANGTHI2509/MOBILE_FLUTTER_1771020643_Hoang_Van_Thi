import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_643.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider643>();
    final member = authProvider.member;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member?.fullName ?? 'Xin chào', style: const TextStyle(fontSize: 14)),
                Text(member?.email ?? '', style: const TextStyle(fontSize: 10)),
              ],
            )
          ],
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
          IconButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen()), 
                (route) => false
              );
            }, 
            icon: const Icon(Icons.logout)
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Số dư khả dụng', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text(
                    member != null ? '${member.walletBalance} đ' : '...', 
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text('Tier: ${member?.tier ?? 'Standard'}', style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            const Text('Lịch thi đấu sắp tới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Demo Upcoming Matches
            Card(
              child: ListTile(
                leading: Container(width: 50, height: 50, color: Colors.blue.withOpacity(0.1), child: const Center(child: Text('14'))), // Ngày
                title: const Text('Giao hữu vs Team A'),
                subtitle: const Text('14:00 - Sân 1'),
                trailing: const Chip(label: Text('Sắp tới', style: TextStyle(fontSize: 10))),
              ),
            ),
             Card(
              child: ListTile(
                leading: Container(width: 50, height: 50, color: Colors.orange.withOpacity(0.1), child: const Center(child: Text('16'))), 
                title: const Text('Giải Winter Cup - Vòng 1'),
                subtitle: const Text('08:00 - Sân VIP'),
                trailing: const Chip(label: Text('Quan trọng', style: TextStyle(fontSize: 10, color: Colors.red))),
              ),
            ),
            
            const SizedBox(height: 25),
            const Text('Biểu đồ Rank (Demo)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: const Center(child: Text('[Biểu đồ Rank sẽ hiển thị ở đây]', style: TextStyle(color: Colors.grey))),
            )
          ],
        ),
      ),
    );
  }
}