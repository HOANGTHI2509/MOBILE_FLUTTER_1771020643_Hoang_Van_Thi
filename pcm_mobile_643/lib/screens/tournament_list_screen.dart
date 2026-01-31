import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider_643.dart';
import '../providers/tournament_provider.dart';
import '../models/tournament_643.dart';
import 'tournament_detail_screen.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider643>().token;
      if (token != null) {
        context.read<TournamentProvider>().fetchTournaments(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Giải đấu chuyên nghiệp', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: provider.tournaments.length,
              itemBuilder: (ctx, i) {
                final tour = provider.tournaments[i];
                return Padding(
                   padding: const EdgeInsets.only(bottom: 15),
                   child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: tour))
                      );
                      // Refresh list to update IsJoined status
                      if (context.mounted) {
                         final token = context.read<AuthProvider643>().token;
                         if (token != null) {
                           context.read<TournamentProvider>().fetchTournaments(token);
                         }
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Column(
                        children: [
                          // Header Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: _getStatusGradient(tour.status),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_getStatusText(tour.status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                if (tour.isJoined)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text("ĐÃ THAM GIA", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tour.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 15),
                                
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                                    const SizedBox(width: 8),
                                    Text('${DateFormat('dd/MM').format(tour.startDate)} - ${DateFormat('dd/MM/yyyy').format(tour.endDate)}', style: TextStyle(color: Colors.blueGrey.shade700)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 8),
                                        Text('Phí: ${currencyFormat.format(tour.entryFee)}', style: TextStyle(color: Colors.blueGrey.shade700)),
                                      ],
                                    ),
                                    
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.orange.shade200)
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.emoji_events, size: 16, color: Colors.orange.shade800),
                                          const SizedBox(width: 5),
                                          Text(currencyFormat.format(tour.prizePool), style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                   ),
                );
              },
            ),
    );
  }

  LinearGradient _getStatusGradient(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.Open:
      case TournamentStatus.Registering:
        return const LinearGradient(colors: [Color(0xFF00b09b), Color(0xFF96c93d)]);
      case TournamentStatus.Ongoing:
        return const LinearGradient(colors: [Color(0xFFf12711), Color(0xFFf5af19)]);
      case TournamentStatus.Finished:
        return LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600]);
      default:
        return const LinearGradient(colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)]);
    }
  }

  String _getStatusText(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.Open:
      case TournamentStatus.Registering:
        return "ĐANG MỞ ĐĂNG KÝ";
      case TournamentStatus.Ongoing:
        return "ĐANG DIỄN RA 🔥";
      case TournamentStatus.Finished:
        return "ĐÃ KẾT THÚC";
      default:
        return "SẮP DIỄN RA";
    }
  }
}
