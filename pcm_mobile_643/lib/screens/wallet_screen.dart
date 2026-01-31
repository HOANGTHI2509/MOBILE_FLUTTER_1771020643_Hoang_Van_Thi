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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 25, left: 20, right: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Container(
                     height: 5, width: 40,
                     margin: const EdgeInsets.only(bottom: 20, left: 150, right: 150),
                     decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                   ),
                   const Text('Nạp tiền vào Ví', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                   const SizedBox(height: 20),

                   TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Nhập số tiền (VNĐ)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                      filled: true,
                      fillColor: Colors.grey.shade50
                    ),
                    onChanged: (value) {
                      if (_qrUrl != null) {
                         setModalState(() { _qrUrl = null; });
                      }
                    },
                  ),
                  const SizedBox(height: 15),

                  if (_qrUrl == null)
                    ElevatedButton.icon(
                      onPressed: () {
                         final double? amount = double.tryParse(amountController.text);
                         if (amount == null || amount < 10000) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tối thiểu 10.000đ')));
                           return;
                         }
                         final memberId = context.read<AuthProvider643>().member?.id ?? "USER";
                         final url = "https://img.vietqr.io/image/MB-0333666999-compact.png?amount=${amount.toInt()}&addInfo=NAP TIEN $memberId";
                         setModalState(() { _qrUrl = url; });
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('TẠO MÃ QR CHUYỂN KHOẢN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50, 
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),

                  if (_qrUrl != null) ...[
                    const SizedBox(height: 15),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade100),
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10)]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          _qrUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, loading) => loading == null ? child : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (ctx, err, _) => const Center(child: Icon(Icons.error, color: Colors.red)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Quét mã QR bằng App Ngân hàng', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                  ],

                  const Divider(height: 40),

                  const Text("Xác nhận chuyển khoản", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) setModalState(() => _image = image);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: _image != null ? Colors.green.shade50 : Colors.grey.shade50,
                        border: Border.all(color: _image != null ? Colors.green : Colors.grey.shade300, style: BorderStyle.none), // Simplified border style
                        borderRadius: BorderRadius.circular(15),
                      ),
                       // Added Dashed Border simulation via separate Painter or just simplified solid border for now
                      child: _image == null 
                          ? Column(
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.green.shade300),
                                const SizedBox(height: 10),
                                Text('Tải ảnh bằng chứng', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : Column(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 40),
                                const SizedBox(height: 10),
                                Text('Đã chọn: ${_image!.name}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                         final double? amount = double.tryParse(amountController.text);
                         if (amount == null || amount <= 0) return;

                         try {
                            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                            final Map<String, dynamic> formMap = {'Amount': amount};
                            if (_image != null) {
                              final bytes = await _image!.readAsBytes();
                              formMap['Image'] = import_dio.MultipartFile.fromBytes(bytes, filename: _image!.name);
                            }
                            final formData = import_dio.FormData.fromMap(formMap);
                            await ApiService.postMultipart('Members/deposit', formData);

                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Gửi yêu cầu thành công!'), backgroundColor: Colors.green));
                              context.read<WalletProvider>().refresh();
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
                          }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: Colors.green.withOpacity(0.4)
                      ),
                      child: const Text('GỬI YÊU CẦU DUYỆT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
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
     final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
     
     if (member == null) return const SizedBox.shrink();

     double current = member.totalSpent;
     double nextTarget = 0;
     String nextTier = "";
     Color nextColor = Colors.grey;

     if (current < 2000000) {
       nextTarget = 2000000;
       nextTier = "BẠC";
       nextColor = Colors.blueGrey;
     } else if (current < 10000000) {
       nextTarget = 10000000;
       nextTier = "VÀNG";
       nextColor = Colors.amber;
     } else if (current < 30000000) {
       nextTarget = 30000000;
       nextTier = "KIM CƯƠNG";
       nextColor = Colors.cyan;
     } else {
       return Container(
         margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
           gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
           borderRadius: BorderRadius.circular(20),
           boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
         ),
         child: const Row(
           children: [
             Icon(Icons.diamond_outlined, color: Colors.white, size: 40),
             SizedBox(width: 15),
             Expanded(child: Text("Đẳng cấp KIM CƯƠNG\nBạn đang hưởng mọi đặc quyền!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
           ],
         ),
       );
     }

     double percent = (current / nextTarget).clamp(0.0, 1.0);

     return Container(
       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tiến độ thăng hạng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: nextColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(nextTier, style: TextStyle(color: nextColor, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 15),
            Stack(
              children: [
                Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5))),
                FractionallySizedBox(
                  widthFactor: percent, 
                  child: Container(
                    height: 8, 
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [nextColor.withOpacity(0.7), nextColor]),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [BoxShadow(color: nextColor.withOpacity(0.4), blurRadius: 5)]
                    )
                  )
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Đã chi: ${currencyFormat.format(current)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text("Còn thiếu: ${currencyFormat.format(nextTarget - current)}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.redAccent)),
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
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Ví Điện Tử', style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Balance Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                   BoxShadow(color: const Color(0xFF11998e).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tổng số dư khả dụng', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            member != null ? currencyFormat.format(member.walletBalance) : currencyFormat.format(0), 
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDepositDialog(context), 
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF11998e)),
                      label: const Text('NẠP TIỀN NGAY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF11998e),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            _buildVipProgress(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Lịch sử giao dịch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800))
              ),
            ),

            walletProvider.isLoading 
              ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: walletProvider.transactions.length,
                  itemBuilder: (ctx, i) {
                    final trans = walletProvider.transactions[i];
                    final type = trans['type']; 
                    final status = trans['status']; 
                    final bool isPlus = (type == 1 && status == 1) || type == 2 || type == 4;
                    final double amount = (trans['amount'] ?? 0).toDouble();
                    
                    Color color = Colors.grey;
                    IconData icon = Icons.history;
                    
                    if (type == 1) { // Deposit
                      if (status == 0) { color = Colors.orange; icon = Icons.pending; }
                      else if (status == 1) { color = Colors.green; icon = Icons.arrow_downward; }
                      else if (status == 2) { color = Colors.red; icon = Icons.block; }
                    } else if (type == 0) { // Payment
                       color = Colors.redAccent; icon = Icons.arrow_upward;
                    } else if (type == 3) { // Refund
                       color = Colors.blue; icon = Icons.refresh;
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        title: Text(trans['description'] ?? 'Giao dịch', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(trans['createdDate'] != null ? DateFormat('dd/MM HH:mm').format(DateTime.parse(trans['createdDate'])) : '', 
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        trailing: Text(
                          '${isPlus ? '+' : ''}${currencyFormat.format(amount)}',
                          style: TextStyle(color: isPlus ? Colors.green : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    );
                  },
                ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
