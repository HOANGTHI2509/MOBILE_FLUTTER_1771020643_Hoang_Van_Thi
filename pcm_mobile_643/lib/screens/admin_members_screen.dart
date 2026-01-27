import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  List<dynamic> _members = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      // API members?search=...
      final endpoint = _searchQuery.isEmpty ? "members" : "members?search=$_searchQuery";
      final response = await ApiService.get(endpoint);
      setState(() {
        _members = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
    }
  }

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    try {
      await ApiService.put("members/$id/status", !currentStatus);
      _loadMembers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Thành viên')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm thành viên...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _loadMembers();
              },
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final m = _members[index];
                    final bool isActive = m['isActive'] ?? true;
                    
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(m['fullName'][0])),
                        title: Text(m['fullName']),
                        subtitle: Text("Rank: ${m['rankLevel']} - Tier: ${m['tier']}"),
                        trailing: Switch(
                          value: isActive,
                          activeColor: Colors.green,
                          onChanged: (val) => _toggleStatus(m['id'], isActive),
                        ),
                        onTap: () {
                          // TODO: Show Detail / Edit Rank Dialog
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
