import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart'; // ดึงสีธีมมาใช้
import '../../main_wrapper.dart'; // เพื่อลิงก์ไปหน้าหลัก
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. ตรวจสอบรหัสผ่านจาก Supabase (Table: auth)
      // หมายเหตุ: การเช็ค Password แบบ Plain text ไม่แนะนำสำหรับ Production 
      // แต่สำหรับโปรเจกต์เรียน/ส่งงาน ถือว่าโอเคครับ
      final data = await Supabase.instance.client
          .from('auth')
          .select()
          .eq('password', password) // เช็คว่ารหัสตรงไหม (ควรเช็ค username คู่กันด้วยในอนาคต)
          .maybeSingle();

      if (data != null) {
        // 2. Update Username (ตาม Logic เดิมของมึง)
        await Supabase.instance.client
            .from('auth')
            .update({'username': username})
            .eq('id', data['id']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', username); // จำชื่อไว้โชว์ด้วยก็ได้

      if (data['id'] == 0) {
        //
        if (mounted) {
          _showSnackBar('ยินดีต้อนรับผู้ดูแลระบบ (Admin) 🔐');
          // ไปหน้า Admin ทันที (ไม่ต้อง Update Username)
          Navigator.pushReplacementNamed(context, '/admin');
        }
        return;
      }

        if (mounted) {
          // *** เปลี่ยนหน้าไป MainWrapper (หน้าหลัก) ***
          // ใช้ pushReplacement เพื่อไม่ให้กด Back กลับมาหน้า Login ได้
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainWrapper()),
          );
        }
      } else {
        _showSnackBar('รหัสผ่านไม่ถูกต้อง');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg), 
          backgroundColor: AppColors.brownDark, // ปรับสีให้เข้าธีม
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // ปรับ Gradient เป็นโทนน้ำตาล-ครีม ให้เข้ากับแอป
          gradient: LinearGradient(
            colors: [
              AppColors.brownDark,
              AppColors.brownLight,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 100),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'เข้าสู่ระบบ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'หอพักคุณเจจวย ยินดีต้อนรับ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // กล่องสีขาวด้านล่าง
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(40, 50, 40, 20),
                decoration: const BoxDecoration(
                  color: AppColors.cream, // พื้นหลังสีครีม
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField("ชื่อผู้ใช้", "กรอก User ID หรือ Email", false, _usernameController),
                      const SizedBox(height: 30),
                      _buildInputField("รหัสผ่าน", "กรอกรหัสผ่าน", true, _passwordController),

                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'ลืมรหัสผ่าน?',
                            style: TextStyle(
                              color: AppColors.brownDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      
                      // ปุ่ม Sign In
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brownDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint, bool isPassword, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.brownDark,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.brownDark, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}