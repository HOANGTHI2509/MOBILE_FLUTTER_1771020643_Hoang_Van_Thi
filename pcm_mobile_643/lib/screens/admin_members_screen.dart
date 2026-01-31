import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  List<dynamic> _members = [];
  List<dynamic> _filteredMembers = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _filterStatus = "all"; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final endpoint = _searchQuery.isEmpty ? "members" : "members?search=$_searchQuery";
      final response = await ApiService.get(endpoint);
      setState(() {
        _members = response.data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
    }
  }

  void _applyFilters() {
    _filteredMembers = _members.where((m) {
      if (_filterStatus == "active") return m['isActive'] == true;
      if (_filterStatus == "inactive") return m['isActive'] == false;
      return true;
    }).toList();
  }

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(currentStatus 
            ? 'Bạn có chắc muốn vô hiệu hóa thành viên này?' 
            : 'Bạn có chắc muốn kích hoạt thành viên này?'),
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
      await ApiService.put("members/$id/status", { 'isActive': !currentStatus });
      _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showMemberDetail(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[400]!, Colors.purple[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          member['fullName'][0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        member['fullName'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          member['isActive'] ? 'Đang hoạt động' : 'Không hoạt động',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(Icons.email, 'Email', member['email'] ?? 'N/A'),
                      const Divider(height: 20),
                      _buildDetailRow(Icons.phone, 'Số điện thoại', member['phoneNumber'] ?? 'N/A'),
                      const Divider(height: 20),
                      _buildDetailRow(Icons.account_balance_wallet, 'Số dư ví', '${member['walletBalance'] ?? 0}đ'),
                      const Divider(height: 20),
                      _buildDetailRow(Icons.military_tech, 'Rank Level', '${member['rankLevel'] ?? 0}'),
                      const Divider(height: 20),
                      _buildDetailRow(Icons.stars, 'Tier', member['tier'] ?? 'N/A'),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.purple[700], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _members.where((m) => m['isActive'] == true).length;
    final inactiveCount = _members.length - activeCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý Thành viên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Statistics Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[50]!, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Tổng số',
                        '${_members.length}',
                        Icons.people,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Hoạt động',
                        '$activeCount',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Không hoạt động',
                        '$inactiveCount',
                        Icons.block,
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm thành viên...',
                    prefixIcon: const Icon(Icons.search, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                    _loadMembers();
                  },
                ),
                const SizedBox(height: 12),
                // Filter Chips
                Row(
                  children: [
                    const Text(
                      'Lọc: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('Tất cả', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Hoạt động', 'active'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Không hoạt động', 'inactive'),
                  ],
                ),
              ],
            ),
          ),
          // Members List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[700]!),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đang tải dữ liệu...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : _filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy thành viên',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        color: Colors.purple,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            final m = _filteredMembers[index];
                            final bool isActive = m['isActive'] ?? true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shadowColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isActive ? Colors.purple.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _showMemberDetail(m),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: isActive
                                          ? [Colors.white, Colors.purple.withOpacity(0.05)]
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
                                              ? [Colors.purple[400]!, Colors.purple[700]!]
                                              : [Colors.grey[400]!, Colors.grey[600]!],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isActive ? Colors.purple : Colors.grey).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          m['fullName'][0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      m['fullName'],
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
                                            Icon(Icons.military_tech, size: 14, color: Colors.amber[700]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Rank: ${m['rankLevel']}',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(Icons.stars, size: 14, color: Colors.blue[700]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Tier: ${m['tier']}',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.account_balance_wallet, size: 14, color: Colors.green[700]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${m['walletBalance'] ?? 0}đ',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
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
                                    trailing: Switch(
                                      value: isActive,
                                      activeColor: Colors.purple,
                                      onChanged: (val) => _toggleStatus(m['id'], isActive),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
          _applyFilters();
        });
      },
      selectedColor: Colors.purple.withOpacity(0.2),
      checkmarkColor: Colors.purple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.purple[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
}
