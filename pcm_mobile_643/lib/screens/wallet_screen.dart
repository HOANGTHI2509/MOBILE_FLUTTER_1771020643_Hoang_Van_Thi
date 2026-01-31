import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as import_dio;
import 'dart:io';
import '../providers/auth_provider_643.dart';
import '../providers/wallet_provider.dart';
import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    // Load transactions khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchTransactions();
    });
  }

  Future<void> _showDepositDialog(BuildContext context) async {
    final TextEditingController amountController = TextEditingController();
    XFile? _image;
    String? _qrUrl;
    
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const Text('Nạp tiền vào Ví', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                   const SizedBox(height: 15),

                   // 1. Nhập tiền trước
                   TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nhập số tiền cần nạp (VNĐ)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'VD: 100000'
                    ),
                    onChanged: (value) {
                      // Reset QR khi sửa tiền
                      if (_qrUrl != null) {
                         setModalState(() { _qrUrl = null; });
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. Nút Tạo QR Invoice
                  if (_qrUrl == null)
                    ElevatedButton.icon(
                      onPressed: () {
                         final double? amount = double.tryParse(amountController.text);
                         if (amount == null || amount < 10000) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền tối thiểu 10.000đ')));
                           return;
                         }
                         // Tạo link VietQR (BIDV demo, thay bằng bank của bạn nếu cần)
                         // Cú pháp: https://img.vietqr.io/image/<BANK>-<TK>-compact.png?amount=<TIEN>&addInfo=<NOIDUNG>
                         final memberId = context.read<AuthProvider643>().member?.id ?? "USER";
                         // Giả lập Bank Acc: MBBank - 0333666999
                         final url = "https://img.vietqr.io/image/MB-0333666999-compact.png?amount=${amount.toInt()}&addInfo=NAP TIEN $memberId";
                         
                         setModalState(() {
                           _qrUrl = url;
                         });
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('TẠO MÃ QR CHUYỂN KHOẢN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100, 
                        foregroundColor: Colors.blue.shade900
                      ),
                    ),

                  // 3. Hiển thị QR nếu đã tạo
                  if (_qrUrl != null) ...[
                    const SizedBox(height: 15),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _qrUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, loading) {
                            if (loading == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (ctx, err, _) => const Center(child: Icon(Icons.error, color: Colors.red)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Hãy quét mã trên bằng App Ngân hàng của bạn', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                  ],

                  const Divider(height: 30),

                  // 4. Upload bằng chứng (Giữ nguyên logic cũ)
                  const Text("Xác nhận đã chuyển khoản:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
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
                        color: _image != null ? Colors.green.shade50 : Colors.grey.shade100,
                        border: Border.all(color: _image != null ? Colors.green : Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _image == null 
                          ? const Column(
                              children: [
                                Icon(Icons.cloud_upload, color: Colors.grey),
                                Text('Tải lên ảnh màn hình chuyển khoản', style: TextStyle(color: Colors.grey)),
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
                  
                  // 5. Nút Gửi Yêu Cầu
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
                            // Show loading manual because we are in a modal
                            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                            final Map<String, dynamic> formMap = {
                              'Amount': amount,
                            };
                            
                            if (_image != null) {
                              final bytes = await _image!.readAsBytes();
                              formMap['Image'] = import_dio.MultipartFile.fromBytes(bytes, filename: _image!.name);
                            }

                            final formData = import_dio.FormData.fromMap(formMap);
                            await ApiService.postMultipart('Members/deposit', formData);

                            // Close loading
                            Navigator.pop(context);
                            // Close modal
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Đã gửi yêu cầu! Admin sẽ duyệt sớm.'), backgroundColor: Colors.green)
                            );
                            context.read<WalletProvider>().refresh();
                          } catch (e) {
                            Navigator.pop(context); // Close loading if error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red)
                            );
                          }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
                      child: const Text('GỬI YÊU CẦU DUYỆT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildVipProgress(BuildContext context) {
     final member = context.watch<AuthProvider643>().member;
     final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
     
     if (member == null) return const SizedBox.shrink();

     double current = member.totalSpent;
     double nextTarget = 0;
     String nextTier = "";
     Color nextColor = Colors.grey;

     if (current < 2000000) {
       nextTarget = 2000000;
       nextTier = "BẠC (SILVER)";
       nextColor = Colors.blueGrey;
     } else if (current < 10000000) {
       nextTarget = 10000000;
       nextTier = "VÀNG (GOLD)";
       nextColor = Colors.amber;
     } else if (current < 30000000) {
       nextTarget = 30000000;
       nextTier = "KIM CƯƠNG (DIAMOND)";
       nextColor = Colors.lightBlue.shade200;
     } else {
       return Container(
         padding: const EdgeInsets.all(16),
         margin: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           gradient: LinearGradient(colors: [Colors.purple.shade200, Colors.blue.shade200]),
           borderRadius: BorderRadius.circular(10)
         ),
         child: const Row(
           children: [
             Icon(Icons.diamond, color: Colors.white, size: 40),
             SizedBox(width: 15),
             Expanded(child: Text("Chúc mừng! Bạn đang ở hạng KIM CƯƠNG tối cao!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
           ],
         ),
       );
     }

     double percent = (current / nextTarget).clamp(0.0, 1.0);

     return Container(
       padding: const EdgeInsets.all(16),
       width: double.infinity,
       color: Colors.grey.shade50,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tiến độ thăng hạng", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Đã chi: ${currencyFormat.format(current)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.shade300,
              color: nextColor,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Mục tiêu kế tiếp: ", style: TextStyle(fontSize: 12)),
                Text(nextTier, style: TextStyle(color: nextColor, fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                Text("Còn thiếu: ${currencyFormat.format(nextTarget - current)}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            )
         ],
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider643>();
    final walletProvider = context.watch<WalletProvider>();
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
          
          _buildVipProgress(context),

          Expanded(
            child: walletProvider.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: walletProvider.transactions.length,
                  separatorBuilder: (ctx, i) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final trans = walletProvider.transactions[i];
                    final type = trans['type']; // 0: Payment, 1: Deposit, 2: Refund, 3: Reward
                    final status = trans['status']; // 0: Pending, 1: Completed, 2: Rejected, 3: Failed

                    final bool isPlus = (type == 1 && status == 1) || type == 2 || type == 4;
                    final double amount = (trans['amount'] ?? 0).toDouble();
                    
                    Color color = Colors.grey;
                    IconData icon = Icons.history;
                    String statusText = '';
                    
                    if (type == 1) { // Deposit
                      if (status == 0) { 
                        color = Colors.orange; 
                        icon = Icons.access_time; 
                        statusText = 'Đang chờ duyệt';
                      } else if (status == 1) { 
                        color = Colors.green; 
                        icon = Icons.check_circle; 
                        statusText = 'Nạp thành công';
                      } else if (status == 2) { 
                        color = Colors.red; 
                        icon = Icons.cancel; 
                        statusText = 'Bị từ chối';
                      } else { 
                        color = Colors.grey; 
                        icon = Icons.error; 
                        statusText = 'Thất bại';
                      }
                    } else if (type == 0) { // Payment
                       color = Colors.red; 
                       icon = Icons.arrow_upward;
                       statusText = 'Thanh toán';
                    } else if (type == 3) { // Refund
                       color = Colors.blue; 
                       icon = Icons.refresh;
                       statusText = 'Hoàn tiền';
                    } else if (type == 4) { // Reward
                       color = Colors.amber; 
                       icon = Icons.emoji_events;
                       statusText = 'Thưởng';
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(trans['description'] ?? 'Giao dịch'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trans['createdDate'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(trans['createdDate'])) : ''),
                          if (statusText.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
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
