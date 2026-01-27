import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider_643.dart';
import 'providers/court_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/match_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo AuthProvider và load token (nếu có)
  final authProvider = AuthProvider643();
  await authProvider.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CourtProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: const PcmApp(),
    ),
  );
}

class PcmApp extends StatelessWidget {
  const PcmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Vợt Thủ Phố Núi 643',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(),
    );
  }
}