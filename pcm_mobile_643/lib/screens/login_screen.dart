import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_643.dart';
import 'main_layout.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../services/biometric_service.dart'; // Đảm bảo đã có file này

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Bộ điều khiển để lấy dữ liệu từ ô nhập
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    // Kiểm tra dữ liệu trống trước khi gọi API
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Email và Mật khẩu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Gọi hàm login từ bộ não AuthProvider643
    final authProvider = Provider.of<AuthProvider643>(context, listen: false);
    bool success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // Kiểm tra xem Widget còn trên màn hình không (Sửa lỗi async gaps)
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success)                // Đăng nhập thành công -> Chuyển sang MainLayout
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainLayout()),
                );else {
      // Sai tài khoản hoặc lỗi server
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thất bại. Vui lòng kiểm tra lại!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo CLB Vợt Thủ Phố Núi
              const Icon(Icons.sports_tennis, size: 100, color: Colors.green),
              const SizedBox(height: 10),
              const Text(
                'VỢT THỦ PHỐ NÚI',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const Text('Hệ thống quản lý Hội viên - 643', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // Ô nhập Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Ô nhập Mật khẩu
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),

              // Nút Đăng nhập
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              // Nút Đăng nhập Vân tay
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    bool authenticated = await BiometricService.authenticate();
                    if (authenticated) {
                      // TODO: Logic login bằng token lưu trong storage
                      // Ở đây demo success luôn
                       Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainLayout()),
                      );
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Xác thực vân tay thất bại')),
                      );
                    }
                  },
                  icon: const Icon(Icons.fingerprint, size: 30),
                  label: const Text("Đăng nhập bằng Vân tay", style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),

              const SizedBox(height: 10),

              // Dòng chữ chuyển sang trang Đăng ký
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?'),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Đăng ký ngay', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}