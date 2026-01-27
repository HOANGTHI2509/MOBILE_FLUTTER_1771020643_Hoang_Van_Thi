import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_643.dart';
import 'home_screen.dart';
import 'booking_screen.dart';
import 'tournament_list_screen.dart';
import 'wallet_screen.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';
import '../services/signalr_service.dart'; // Will create this next

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo SignalR để nghe thông báo Realtime
    SignalRService().initSignalR();
    SignalRService().onNotificationReceived = (message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        )
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final member = context.watch<AuthProvider643>().member;
    final bool isAdmin = member?.isAdmin ?? false;

    // Admin chỉ thấy: Admin Dashboard + Profile
    // User thường thấy: Home, Đặt sân, Giải đấu, Ví tiền, Profile
    final List<Widget> currentScreens = isAdmin 
        ? [
            const AdminDashboardScreen(),
            const ProfileScreen(),
          ]
        : [
            const HomeScreen(),
            const BookingScreen(),
            const TournamentListScreen(),
            const WalletScreen(),
            const ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> currentNavItems = isAdmin
        ? [
            const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
          ]
        : [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Đặt sân'),
            const BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Giải đấu'),
            const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ví tiền'),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex < currentScreens.length ? _currentIndex : 0, // Prevent overflow if toggling roles
        children: currentScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < currentNavItems.length ? _currentIndex : 0,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: currentNavItems,
      ),
    );
  }
}
