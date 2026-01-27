import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  List<dynamic> _transactions = [];
  bool _isLoading = false;

  List<dynamic> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('Wallet/transactions');
      _transactions = response.data;
    } catch (e) {
      print('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Gọi sau khi đặt sân, hủy sân, nạp tiền
  void refresh() {
    fetchTransactions();
  }
}
