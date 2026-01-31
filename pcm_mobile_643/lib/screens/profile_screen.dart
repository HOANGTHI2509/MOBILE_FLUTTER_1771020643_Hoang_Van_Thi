import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_643.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider643>();
    final member = authProvider.member;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'), 
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: () async {
              await authProvider.logout();
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
      body: member == null 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                   child: Icon(Icons.person, size: 50),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(member.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Center(
                child: _buildTierBadge(member.tier),
              ),
              const SizedBox(height: 30),
              _buildProfileItem(Icons.email, 'Email', member.email),
              const Divider(),
              _buildProfileItem(Icons.phone, 'Số điện thoại', '0987654321'), // Fake data
              const Divider(),
              _buildProfileItem(Icons.military_tech, 'Điểm Rank', '3.5'), // Fake data
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    authProvider.logout();
                     Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }, 
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50)
                  ),
                ),
              )
            ],
          ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTierBadge(String tier) {
    Color color;
    IconData icon;
    
    switch (tier.toLowerCase()) {
      case 'gold':
        color = Colors.amber;
        icon = Icons.star;
        break;
      case 'diamond':
        color = Colors.blue.shade300;
        icon = Icons.diamond;
        break;
      case 'silver':
        color = Colors.blueGrey;
        icon = Icons.shield;
        break;
      default:
        color = Colors.brown.shade300; // Bronze/Standard
        icon = Icons.person;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(tier.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
