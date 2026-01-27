import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as import_dio;
import 'dart:io';
import '../providers/auth_provider_643.dart';
import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final response = await ApiService.get('Wallet/transactions');
      setState(() {
        _transactions = response.data;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDepositDialog(BuildContext context) async {
    final TextEditingController amountController = TextEditingController();
    XFile? _image;
    
    // ignore: use_build_context_synchronously
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nạp tiền vào Ví', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // QR Code
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset('assets/image.png', fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Icon(Icons.qr_code, size: 80, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text('Quét mã QR để chuyển khoản', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền nạp (VNĐ)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Image Picker
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setModalState(() {
                          _image = image;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _image == null 
                          ? const Column(
                              children: [
                                Icon(Icons.cloud_upload, color: Colors.grey),
                                Text('Tải lên ảnh chuyển khoản', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : Column(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                Text('Đã chọn: ${_image!.name}', style: const TextStyle(color: Colors.green)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                         final double? amount = double.tryParse(amountController.text);
                         if (amount == null || amount <= 0) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')));
                           return;
                         }

                         try {
                            print("🔍 [Deposit] Starting deposit request...");
                            print("🔍 [Deposit] Amount: $amount");
                            
                            final Map<String, dynamic> formMap = {
                              'Amount': amount,
                            };
                            
                            if (_image != null) {
                              final bytes = await _image!.readAsBytes();
                              formMap['Image'] = import_dio.MultipartFile.fromBytes(bytes, filename: _image!.name);
                              print("🔍 [Deposit] Image attached: ${_image!.name}");
                            }

                            final formData = import_dio.FormData.fromMap(formMap);
                            print("🔍 [Deposit] Calling API: Members/deposit");

                            final response = await ApiService.postMultipart('Members/deposit', formData);
                            print("✅ [Deposit] Success: ${response.data}");

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã gửi yêu cầu nạp tiền! Chờ Admin duyệt.'), backgroundColor: Colors.green)
                            );
                            _loadTransactions(); // Reload history
                          } catch (e) {
                            print("❌ [Deposit] Error: $e");
                            if (e is import_dio.DioException) {
                              print("🔍 Status Code: ${e.response?.statusCode}");
                              print("🔍 Response: ${e.response?.data}");
                              print("🔍 Request URL: ${e.requestOptions.uri}");
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red)
                            );
                          }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
                      child: const Text('GỬI YÊU CẦU', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider643>();
    final member = authProvider.member;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: const Text('Ví Điện Tử'), backgroundColor: Colors.green),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(30),
            color: Colors.green,
            width: double.infinity,
            child: Column(
              children: [
                const Text('Tổng số dư', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Text(
                  member != null ? currencyFormat.format(member.walletBalance) : currencyFormat.format(0), 
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showDepositDialog(context), 
                  icon: const Icon(Icons.add, color: Colors.green),
                  label: const Text('NẠP TIỀN', style: TextStyle(color: Colors.green)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                )
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: _transactions.length,
                  separatorBuilder: (ctx, i) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final trans = _transactions[i];
                    final type = trans['type']; // 0: Payment, 1: Deposit, 2: Refund
                    final status = trans['status']; // 0: Pending, 1: Completed, 2: Failed

                    final bool isPlus = (type == 1 && status == 1) || type == 2;
                    final double amount = (trans['amount'] ?? 0).toDouble();
                    
                    Color color = Colors.grey;
                    IconData icon = Icons.history;
                    
                    if (type == 1) { // Deposit
                      if (status == 0) { color = Colors.orange; icon = Icons.access_time; } // Pending
                      else if (status == 1) { color = Colors.green; icon = Icons.arrow_downward; }
                      else { color = Colors.red; icon = Icons.error; }
                    } else if (type == 0) { // Payment
                       color = Colors.red; icon = Icons.arrow_upward;
                    } else { // Refund
                       color = Colors.blue; icon = Icons.refresh;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(trans['description'] ?? 'Giao dịch'),
                      subtitle: Text(trans['createdDate'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(trans['createdDate'])) : ''),
                      trailing: Text(
                        '${isPlus ? '+' : ''}${currencyFormat.format(amount)}',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }
}
