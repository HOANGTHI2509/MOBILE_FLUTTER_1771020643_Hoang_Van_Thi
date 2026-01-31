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
      Navigator.pop(context); // Go back to list to see updated status (needs refresh)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thất bại. Kiểm tra số dư hoặc bạn đã tham gia rồi.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _leaveTournament(BuildContext context) async {
    final auth = context.read<AuthProvider643>();
    final success = await context.read<TournamentProvider>().leaveTournament(auth.token!, tournament.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hủy đăng ký thành công. Đã hoàn 50% phí.'), backgroundColor: Colors.orange));
      auth.getProfile(); // Reload wallet
      Navigator.pop(context); // Go back
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hủy đăng ký thất bại.'), backgroundColor: Colors.red));
    }
  }

  void _onCancelPressed(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final refund = currencyFormat.format(tournament.entryFee * 0.5);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hủy đăng ký?"),
        content: Text("Bạn sẽ bị phạt 50% phí tham dự.\nBạn sẽ chỉ được hoàn lại: $refund.\n\nBạn có chắc chắn không?"),
        actions: [
           TextButton(
             child: const Text("Quay lại", style: TextStyle(color: Colors.grey)), 
             onPressed: () => Navigator.pop(ctx)
           ),
           ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
             onPressed: () {
                Navigator.pop(ctx);
                _leaveTournament(context);
             },
             child: const Text("Xác nhận Hủy", style: TextStyle(color: Colors.white)), 
           )
        ]
      )
    );
  }

  void _onJoinPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận đăng ký?"),
        content: const Text("LƯU Ý QUAN TRỌNG: Nếu bạn hủy tham gia sau này, bạn sẽ bị phạt 50% tiền phí tham dự. \n\nBạn có chắc chắn muốn đăng ký không?"),
        actions: [
           TextButton(
             child: const Text("Suy nghĩ lại", style: TextStyle(color: Colors.grey)), 
             onPressed: () => Navigator.pop(ctx)
           ),
           ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
             onPressed: () {
                Navigator.pop(ctx);
                _joinTournament(context);
             },
             child: const Text("Đồng ý & Đăng ký", style: TextStyle(color: Colors.white)), 
           )
        ]
      )
    );
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
                child: tournament.isJoined 
                  ? Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: null, // Disable
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text('BẠN ĐÃ THAM GIA', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Visual enabled look but disabled interaction
                            disabledBackgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50)
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _onCancelPressed(context),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('HỦY ĐĂNG KÝ (Rời giải)', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(double.infinity, 50)
                          ),
                        )
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _onJoinPressed(context),
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
