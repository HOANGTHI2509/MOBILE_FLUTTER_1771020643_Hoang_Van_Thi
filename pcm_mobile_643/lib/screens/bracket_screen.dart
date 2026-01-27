import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_643.dart';
import '../providers/match_provider.dart';
import '../models/match_643.dart';

class BracketScreen extends StatefulWidget {
  final int tournamentId;
  const BracketScreen({super.key, required this.tournamentId});

  @override
  State<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends State<BracketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider643>().token;
      if (token != null) {
        context.read<MatchProvider>().fetchMatches(token, widget.tournamentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cây thi đấu'), backgroundColor: Colors.indigo),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.matches.isEmpty
              ? const Center(child: Text("Chưa có lịch thi đấu"))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRoundColumn("Vòng loại", provider.matches.where((m) => m.roundName == "Round 1").toList()),
                          const SizedBox(width: 50),
                          _buildRoundColumn("Bán kết", provider.matches.where((m) => m.roundName == "Semi Final").toList()),
                          const SizedBox(width: 50),
                          _buildRoundColumn("Chung kết", provider.matches.where((m) => m.roundName == "Final").toList()),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildRoundColumn(String title, List<Match643> matches) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
        const SizedBox(height: 20),
        if (matches.isEmpty) const Text("---", style: TextStyle(color: Colors.grey)),
        ...matches.map((m) => _buildMatchCard(m)),
      ],
    );
  }

  Widget _buildMatchCard(Match643 match) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Team 1", style: TextStyle(fontWeight: FontWeight.bold)),
              if (match.status == MatchStatus.Finished && match.score1 > match.score2)
                const Icon(Icons.check_circle, color: Colors.green, size: 16)
            ],
          ),
          Text("${match.score1} - ${match.score2}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Team 2", style: TextStyle(fontWeight: FontWeight.bold)),
              if (match.status == MatchStatus.Finished && match.score2 > match.score1)
                const Icon(Icons.check_circle, color: Colors.green, size: 16)
            ],
          ),
          const Divider(),
          Text(match.status == MatchStatus.Finished ? "Kết thúc" : "Chờ đấu", 
               style: TextStyle(fontSize: 10, color: match.status == MatchStatus.Finished ? Colors.black : Colors.blue)),
        ],
      ),
    );
  }
}
