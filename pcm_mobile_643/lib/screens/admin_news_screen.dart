import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  List<dynamic> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final response = await ApiService.get('News');
      setState(() {
        _newsList = response.data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading news: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNews(String title, String content, bool isPinned) async {
    try {
      final data = {
        'title': title,
        'content': content,
        'isPinned': isPinned,
        // imageUrl: null for now
      };
      await ApiService.post('News', data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng tin thành công'), backgroundColor: Colors.green),
        );
      }
      _loadNews();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteNews(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa tin tức này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.delete('News/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tin tức'), backgroundColor: Colors.green),
        );
      }
      _loadNews();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isPinned = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đăng Tin Mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Nội dung', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Ghim tin này'),
                  value: isPinned,
                  onChanged: (val) => setDialogState(() => isPinned = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  _createNews(titleController.text, contentController.text, isPinned);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Đăng'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Tin Tức'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _newsList.isEmpty
              ? const Center(child: Text("Chưa có tin tức nào"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _newsList.length,
                  itemBuilder: (ctx, i) {
                    final news = _newsList[i];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Icon(
                            news['isPinned'] == true ? Icons.push_pin : Icons.article,
                            color: Colors.purple,
                          ),
                        ),
                        title: Text(
                          news['title'] ?? 'Không tiêu đề',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              news['content'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              news['createdDate'] != null
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(news['createdDate']))
                                  : '',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNews(news['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
