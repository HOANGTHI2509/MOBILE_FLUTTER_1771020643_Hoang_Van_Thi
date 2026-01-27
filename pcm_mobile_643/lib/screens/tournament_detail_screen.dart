import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/tournament_643.dart';
import '../providers/auth_provider_643.dart';
import '../providers/tournament_provider.dart';
import 'bracket_screen.dart';

class TournamentDetailScreen extends StatelessWidget {
  final Tournament643 tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  Future<void> _joinTournament(BuildContext context) async {
    final auth = context.read<AuthProvider643>();
    final success = await context.read<TournamentProvider>().joinTournament(auth.token!, tournament.id, null);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký tham gia thành công!'), backgroundColor: Colors.green));
      auth.getProfile(); // Reload wallet
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thất bại. Kiểm tra số dư hoặc bạn đã tham gia rồi.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: Text(tournament.name), backgroundColor: Colors.indigo),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(15)
              ),
              child: const Icon(Icons.emoji_events, size: 80, color: Colors.indigo),
            ),
            const SizedBox(height: 20),
            
            Text(tournament.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 5),
                Text('${DateFormat('dd/MM/yyyy').format(tournament.startDate)} - ${DateFormat('dd/MM/yyyy').format(tournament.endDate)}')
              ],
            ),
             const SizedBox(height: 20),
            _buildInfoTile('Lệ phí tham gia', currencyFormat.format(tournament.entryFee), Icons.monetization_on),
            _buildInfoTile('Tổng giải thưởng', currencyFormat.format(tournament.prizePool), Icons.wallet_giftcard),
            _buildInfoTile('Thể thức', tournament.format.toString().split('.').last, Icons.sports_tennis),
            
            const SizedBox(height: 30),
            
            if (tournament.status == TournamentStatus.Ongoing || tournament.status == TournamentStatus.Finished)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BracketScreen(tournamentId: tournament.id))),
                  icon: const Icon(Icons.account_tree),
                  label: const Text('XEM CÂY THI ĐẤU (BRACKET)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, 
                    minimumSize: const Size(double.infinity, 50)
                  ),
                ),
              ),

             const SizedBox(height: 10),

             if (tournament.status == TournamentStatus.Registering || tournament.status == TournamentStatus.Open)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _joinTournament(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('ĐĂNG KÝ THAM GIA NGAY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    minimumSize: const Size(double.infinity, 50)
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigo),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
