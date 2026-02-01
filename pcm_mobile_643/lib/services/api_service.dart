import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import '../screens/login_screen.dart';

class ApiService {
  // Logic tự động chọn URL dựa trên môi trường chạy (Web, Android Emulator, iOS/Windows)
  static String get baseUrl {
    // Để deploy lên VPS, ta dùng IP của VPS
    return 'http://103.77.172.159:5299'; 
    
    // Chạy Local (Máy thật Android cùng Wifi)
    // return 'http://192.168.31.132:5282'; 
    
    // Logic tự động
    // if (kIsWeb) {
    //   return 'http://localhost:5282'; 
    // } else if (defaultTargetPlatform == TargetPlatform.android) {
    //   // Khi chạy máy thật Android, thay 10.0.2.2 bằng IP thật của máy tính/server
    //   // Ví dụ: return 'http://192.168.1.5:5282'; 
    //   return 'http://10.0.2.2:5282';
    // } else {
    //   return 'http://localhost:5282';
    // }
  }

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      "Content-Type": "application/json",
      "Accept": "*/*",
    },
  ));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          print("🚨 401 Unauthorized detected. Redirecting to Login...");
          // Auto Logout
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()), 
            (route) => false
          );
        }
        return handler.next(e);
      },
    ));
  }

  // Hàm Đăng ký
  Future<bool> register(String email, String password) async {
    try {
      final response = await _dio.post('/register', data: {
        'email': email,
        'password': password,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Lỗi Register: $e");
      return false;
    }
  }

  // Hàm Đăng nhập
  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      return response.data['accessToken'];
    } catch (e) {
      print("❌ Lỗi Login: $e");
      if (e is DioException) {
        print("🔍 DioError Type: ${e.type}");
        print("🔍 DioError Message: ${e.message}");
        print("🔍 DioError Response: ${e.response}");
      }
      return null;
    }
  }

  // Hàm lấy Profile (đã có thêm Token)
  Future<Map<String, dynamic>?> getMemberProfile(String token) async {
    try {
      print("🔍 [getMemberProfile] Calling with token: ${token.substring(0, 20)}...");
      final response = await _dio.get(
        '/api/Members/profile', 
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      print("✅ [getMemberProfile] Success: ${response.data}");
      return response.data;
    } catch (e) {
      print("❌ [getMemberProfile] Error: $e");
      if (e is DioException) {
        print("🔍 Status Code: ${e.response?.statusCode}");
        print("🔍 Response Data: ${e.response?.data}");
        print("🔍 Request Path: ${e.requestOptions.path}");
      }
      return null;
    }
  }

  // Hàm lấy lịch sử Rank
  Future<List<dynamic>?> getRankHistory(String token) async {
    try {
      final response = await _dio.get(
        '/api/Members/rank-history',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return response.data; // List of maps
      }
      return [];
    } catch (e) {
      print("❌ GetRankHistory Error: $e");
      return [];
    }
  }

  // --- Static Helpers for Generic Usage (Admin screens) ---

  // Lấy token hiện tại
  static Future<String?> _getToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'jwt_token');
  }

  // Generic GET
  static Future<Response> get(String endpoint) async {
    final token = await _getToken();
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
    return await dio.get('/api/$endpoint');
  }

  // Generic PUT
  static Future<Response> put(String endpoint, dynamic data) async {
    final token = await _getToken();
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
    return await dio.put('/api/$endpoint', data: data);
  }

  // Generic POST
  static Future<Response> post(String endpoint, dynamic data) async {
    final token = await _getToken();
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
    return await dio.post('/api/$endpoint', data: data);
  }

  // POST with Multipart (for file uploads)
  static Future<Response> postMultipart(String endpoint, FormData formData) async {
    final token = await _getToken();
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
    return await dio.post('/api/$endpoint', data: formData);
  }
  // Generic DELETE
  static Future<Response> delete(String endpoint) async {
    final token = await _getToken();
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
    return await dio.delete('/api/$endpoint');
  }
}