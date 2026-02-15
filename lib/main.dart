import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/supabase_config.dart'; // ไฟล์ config ที่จะสร้าง
import 'main_wrapper.dart'; // เรียก Wrapper แทน Home
import 'screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เรียกใช้ Config จากไฟล์ services
  await SupabaseConfig.initialize();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(DormitoryApp(isLoggedIn: isLoggedIn));
}

class DormitoryApp extends StatelessWidget {
  // 3. [แก้ตรงนี้] ประกาศตัวแปรรับค่า
  final bool isLoggedIn;

  const DormitoryApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dorm App',
      theme: ThemeData(
        fontFamily: 'Prompt', 
        primaryColor: const Color(0xFF6D4C41),
      ),
      
      // --- แก้ตรงนี้ครับ ---
      // เช็คว่า "มีผู้ใช้ปัจจุบันไหม?" (currentUser != null คือมีคนล็อกอินอยู่)
      home: isLoggedIn
          ? const MainWrapper()  // ถ้ามี -> ไปหน้า Home เลย
          : const LoginPage(),   // ถ้าไม่มี -> ไปหน้า Login
    );
  }
}