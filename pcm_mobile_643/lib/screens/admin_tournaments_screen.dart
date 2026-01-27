import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminTournamentsScreen extends StatefulWidget {
  const AdminTournamentsScreen({super.key});

  @override
  State<AdminTournamentsScreen> createState() => _AdminTournamentsScreenState();
}

class _AdminTournamentsScreenState extends State<AdminTournamentsScreen> {
  List<dynamic> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    try {
      final response = await ApiService.get('Tournaments');
      setState(() {
        _tournaments = response.data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tournaments: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Đang đăng ký';
      case 1: return 'Đang diễn ra';
      case 2: return 'Kết thúc';
      default: return 'N/A';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.blue;
      case 1: return Colors.orange;
      case 2: return Colors.grey;
      default: return Colors.black;
    }
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final entryFeeController = TextEditingController();
    final prizePoolController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    int format = 0; // 0: Knockout, 1: RoundRobin

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo Giải Đấu Mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên giải đấu', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: entryFeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Phí tham gia (VNĐ)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: prizePoolController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tổng giải thưởng (VNĐ)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: format,
                  decoration: const InputDecoration(labelText: 'Thể thức', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Loại trực tiếp')),
                    DropdownMenuItem(value: 1, child: Text('Vòng tròn')),
                  ],
                  onChanged: (val) => setDialogState(() => format = val ?? 0),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => startDate = picked);
                  },
                ),
                ListTile(
                  title: const Text('Ngày kết thúc'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => endDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameController.text,
                  'startDate': startDate.toIso8601String(),
                  'endDate': endDate.toIso8601String(),
                  'format': format,
                  'entryFee': double.tryParse(entryFeeController.text) ?? 0,
                  'prizePool': double.tryParse(prizePoolController.text) ?? 0,
                  'status': 0, // Registering
                };

                try {
                  await ApiService.post('Tournaments', data);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo giải đấu thành công'), backgroundColor: Colors.green),
                  );
                  _loadTournaments();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Giải Đấu'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _tournaments.length,
              itemBuilder: (ctx, i) {
                final tournament = _tournaments[i];
                final status = tournament['status'] ?? 0;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status),
                      child: const Icon(Icons.emoji_events, color: Colors.white),
                    ),
                    title: Text(tournament['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_getStatusText(status)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Ngày bắt đầu', tournament['startDate'] != null 
                                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(tournament['startDate'])) 
                                : 'N/A'),
                            _buildInfoRow('Ngày kết thúc', tournament['endDate'] != null 
                                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(tournament['endDate'])) 
                                : 'N/A'),
                            _buildInfoRow('Phí tham gia', currencyFormat.format(tournament['entryFee'] ?? 0)),
                            _buildInfoRow('Giải thưởng', currencyFormat.format(tournament['prizePool'] ?? 0)),
                            _buildInfoRow('Thể thức', tournament['format'] == 0 ? 'Loại trực tiếp' : 'Vòng tròn'),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status == 0) ...[
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await ApiService.put('Tournaments/${tournament['id']}/status', 1);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Bắt đầu giải đấu'), backgroundColor: Colors.green),
                                        );
                                        _loadTournaments();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Bắt đầu'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  ),
                                ],
                                if (status == 1) ...[
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await ApiService.put('Tournaments/${tournament['id']}/status', 2);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Kết thúc giải đấu'), backgroundColor: Colors.green),
                                        );
                                        _loadTournaments();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.stop),
                                    label: const Text('Kết thúc'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
