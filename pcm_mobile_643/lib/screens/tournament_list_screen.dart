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
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải đấu chuyên nghiệp'),
        backgroundColor: Colors.indigo,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: provider.tournaments.length,
              itemBuilder: (ctx, i) {
                final tour = provider.tournaments[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: tour))
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tour.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                              _buildStatusBadge(tour.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Thời gian: ${DateFormat('dd/MM/yyyy').format(tour.startDate)} - ${DateFormat('dd/MM/yyyy').format(tour.endDate)}'),
                          const SizedBox(height: 5),
                          Text('Phí tham gia: ${currencyFormat.format(tour.entryFee)}'),
                          Text('Giải thưởng: ${currencyFormat.format(tour.prizePool)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    Color color;
    String text;
    switch (status) {
      case TournamentStatus.Open:
      case TournamentStatus.Registering:
        color = Colors.green;
        text = "ĐANG MỞ";
        break;
      case TournamentStatus.Ongoing:
        color = Colors.orange;
        text = "DIỄN RA";
        break;
      case TournamentStatus.Finished:
        color = Colors.grey;
        text = "KẾT THÚC";
        break;
      default:
        color = Colors.blue;
        text = "SẮP TỚI";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
