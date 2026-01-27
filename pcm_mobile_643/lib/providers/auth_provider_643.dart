import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/member_643.dart';
import '../services/api_service.dart';

class AuthProvider643 extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String? _token;
  Member643? _member;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Member643? get member => _member;

  // Khởi tạo: Đọc token từ storage (nếu có)
  Future<void> init() async {
    _token = await _storage.read(key: 'jwt_token');
    if (_token != null) {
      await getProfile();
    }
  }

  // Xử lý đăng nhập
  Future<bool> login(String email, String password) async {
    final token = await _apiService.login(email, password);
    if (token != null) {
      _token = token;
      // LƯU TOKEN VÀO STORAGE (Quan trọng!)
      await _storage.write(key: 'jwt_token', value: token);
      
      // Đăng nhập xong, gọi ngay lệnh lấy thông tin chi tiết
      await getProfile(); 
      return true;
    }
    return false;
  }

  // Lấy thông tin cá nhân từ Server thông qua Token
  Future<void> getProfile() async {
    if (_token == null) return;
    
    final data = await _apiService.getMemberProfile(_token!);
    if (data != null) {
      _member = Member643.fromJson(data);
      // Lệnh này cực quan trọng để cập nhật lại giao diện (Home/Wallet)
      notifyListeners(); 
    }
  }

  Future<void> logout() async {
    _token = null;
    _member = null;
    await _storage.delete(key: 'jwt_token');
    notifyListeners();
  }
}