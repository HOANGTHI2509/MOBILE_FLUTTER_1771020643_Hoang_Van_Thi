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
      backgroundColor: Colors.grey.shade100,
      body: member == null 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
               Stack(
                 clipBehavior: Clip.none,
                 alignment: Alignment.center,
                 children: [
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))
                      ),
                    ),
                    Positioned(
                      top: 40, right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {}, // Settings placeholder
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                        child: const CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                      ),
                    )
                 ],
               ),
               const SizedBox(height: 60),

               Text(member.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
               const SizedBox(height: 5),
               _buildTierBadge(member.tier),
               
               const SizedBox(height: 30),

               Expanded(
                 child: ListView(
                   padding: const EdgeInsets.symmetric(horizontal: 20),
                   children: [
                      _buildProfileCard(
                        icon: Icons.email, 
                        title: "Email", 
                        subtitle: member.email,
                        color: Colors.blue
                      ),
                      _buildProfileCard(
                        icon: Icons.phone, 
                        title: "Số điện thoại", 
                        subtitle: "0987654321", // Fake data
                        color: Colors.orange
                      ),
                      _buildProfileCard(
                        icon: Icons.military_tech, 
                        title: "Điểm Rank", 
                        subtitle: "3.5", // Fake data
                        color: Colors.purple
                      ),
                      
                      const SizedBox(height: 30),
                      
                      ElevatedButton.icon(
                        onPressed: () {
                          authProvider.logout();
                           Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }, 
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2
                        ),
                      )
                   ],
                 ),
               )
            ],
          ),
    );
  }

  Widget _buildProfileCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }

  Widget _buildTierBadge(String tier) {
    Color color;
    IconData icon;
    String text = tier.toUpperCase();
    
    switch (tier.toLowerCase()) {
      case 'gold':
        color = Colors.amber;
        icon = Icons.star;
        break;
      case 'diamond':
        color = Colors.cyan;
        icon = Icons.diamond;
        break;
      case 'silver':
        color = Colors.blueGrey;
        icon = Icons.shield;
        break;
      default:
        color = Colors.brown; // Bronze/Standard
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
