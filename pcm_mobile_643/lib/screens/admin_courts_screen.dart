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
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('Courts/all');
      setState(() {
        _courts = response.data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading courts: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleCourtStatus(int courtId, bool currentStatus) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(currentStatus 
            ? 'Bạn có chắc muốn vô hiệu hóa sân này?' 
            : 'Bạn có chắc muốn kích hoạt sân này?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.orange : Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.put('Courts/$courtId/status', { 'isActive': !currentStatus });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cập nhật trạng thái sân thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      _loadCourts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditDialog(Map<String, dynamic>? court) {
    final nameController = TextEditingController(text: court?['name'] ?? '');
    final priceController = TextEditingController(text: court?['pricePerHour']?.toString() ?? '');
    final descController = TextEditingController(text: court?['description'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              court == null ? Icons.add_circle : Icons.edit,
              color: Colors.green,
            ),
            const SizedBox(width: 10),
            Text(court == null ? 'Thêm Sân Mới' : 'Chỉnh Sửa Sân'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên sân *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.sports_tennis),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên sân';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Giá/giờ (VNĐ) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập giá';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Giá phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                    filled: true,
                    fillColor: Colors.grey[50],
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final data = {
                'id': court?['id'] ?? 0,
                'name': nameController.text.trim(),
                'pricePerHour': double.parse(priceController.text),
                'description': descController.text.trim(),
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
                  SnackBar(
                    content: Text(court == null ? 'Thêm sân thành công' : 'Cập nhật thành công'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _loadCourts();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Sân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, size: 24),
              ),
              onPressed: () => _showEditDialog(null),
              tooltip: 'Thêm sân mới',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải dữ liệu...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : _courts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_tennis, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có sân nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showEditDialog(null),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm sân đầu tiên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCourts,
                  color: Colors.green,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _courts.length,
                    itemBuilder: (ctx, i) {
                      final court = _courts[i];
                      final isActive = court['isActive'] ?? false;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: isActive
                                  ? [Colors.white, Colors.green.withOpacity(0.05)]
                                  : [Colors.white, Colors.grey.withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isActive
                                      ? [Colors.green[400]!, Colors.green[700]!]
                                      : [Colors.grey[400]!, Colors.grey[600]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isActive ? Colors.green : Colors.grey).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isActive ? Icons.sports_tennis : Icons.block,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              court['name'] ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${court['pricePerHour']} VNĐ/giờ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (court['description'] != null && court['description'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    court['description'],
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isActive ? 'Đang hoạt động' : 'Không hoạt động',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? Colors.green[700] : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  ),
                                  onPressed: () => _showEditDialog(court),
                                  tooltip: 'Chỉnh sửa',
                                ),
                                Switch(
                                  value: isActive,
                                  onChanged: (val) => _toggleCourtStatus(court['id'], isActive),
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
