import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/supabase_config.dart';

import 'screens/login.dart';
import 'main_wrapper.dart';
import 'admin_wrapper.dart'; // 👈 อย่าลืมนำเข้า AdminWrapper

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  // ดึงข้อมูลที่จำไว้ในเครื่อง
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final int userId = prefs.getInt('userId') ?? -1; // 👈 ดึง ID มาเช็คด้วย

  runApp(DormitoryApp(isLoggedIn: isLoggedIn, userId: userId));
}

class DormitoryApp extends StatelessWidget {
  final bool isLoggedIn;
  final int userId; // 👈 รับค่า ID เข้ามา

  const DormitoryApp({
    super.key,
    required this.isLoggedIn,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // โลจิกตรวจสอบ: ถ้าเคยจำการล็อกอินไว้ ให้กระโดดไปหน้าไหน?
    Widget initialPage = const LoginPage(); // ค่าเริ่มต้นคือหน้า Login

    if (isLoggedIn) {
      if (userId == 0) {
        initialPage = const AdminWrapper(); // ถ้า ID = 0 ให้เปิดมาหน้าแอดมินเลย
      } else if (userId > 0) {
        initialPage = const MainWrapper(); // ถ้า ID ห้องทั่วไป ให้เปิดหน้า Home
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buddy Homie', // ชื่อโปรเจกต์ของคุณ
      theme: ThemeData(
        fontFamily: 'Prompt',
        primaryColor: const Color(0xFF6D4C41),
      ),
      routes: {
        '/admin_wrapper': (context) => const AdminWrapper(),
        // (คุณสามารถใส่ Route อื่นๆ เพิ่มที่นี่ได้ถ้าจำเป็น)
      },
      home: initialPage, // 👈 ใช้ตัวแปรหน้าที่เราคัดกรองไว้ด้านบน
    );
  }
}
