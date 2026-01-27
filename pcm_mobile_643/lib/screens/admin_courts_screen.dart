import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminCourtsScreen extends StatefulWidget {
  const AdminCourtsScreen({super.key});

  @override
  State<AdminCourtsScreen> createState() => _AdminCourtsScreenState();
}

class _AdminCourtsScreenState extends State<AdminCourtsScreen> {
  List<dynamic> _courts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    try {
      final response = await ApiService.get('Courts');
      setState(() {
        _courts = response.data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading courts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCourtStatus(int courtId, bool currentStatus) async {
    try {
      await ApiService.put('Courts/$courtId/status', !currentStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái sân thành công'), backgroundColor: Colors.green),
      );
      _loadCourts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditDialog(Map<String, dynamic>? court) {
    final nameController = TextEditingController(text: court?['name'] ?? '');
    final priceController = TextEditingController(text: court?['pricePerHour']?.toString() ?? '');
    final descController = TextEditingController(text: court?['description'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(court == null ? 'Thêm Sân Mới' : 'Chỉnh Sửa Sân'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên sân', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá/giờ (VNĐ)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
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
                'pricePerHour': double.tryParse(priceController.text) ?? 0,
                'description': descController.text,
                'isActive': court?['isActive'] ?? true,
              };

              try {
                if (court == null) {
                  await ApiService.post('Courts', data);
                } else {
                  await ApiService.put('Courts/${court['id']}', data);
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lưu thành công'), backgroundColor: Colors.green),
                );
                _loadCourts();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Sân'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(null),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _courts.length,
              itemBuilder: (ctx, i) {
                final court = _courts[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: court['isActive'] ? Colors.green : Colors.grey,
                      child: Icon(
                        court['isActive'] ? Icons.sports_tennis : Icons.block,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(court['name'] ?? 'N/A'),
                    subtitle: Text('${court['pricePerHour']} VNĐ/giờ\n${court['description'] ?? ''}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDialog(court),
                        ),
                        Switch(
                          value: court['isActive'] ?? false,
                          onChanged: (val) => _toggleCourtStatus(court['id'], court['isActive']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
