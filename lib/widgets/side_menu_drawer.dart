import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SideMenuDrawer extends StatelessWidget {
  const SideMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        color: AppColors.brownLight, // สีจากไฟล์ constants
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              "เมนู",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white38, thickness: 1),
            
            // รายการเมนู
            _buildDrawerItem(Icons.person_outline, "ชื่อผู้ใช้(ข้อมูลผู้ใช้)", () {
              // TODO: Navigate to Profile
            }),
            _buildDrawerItem(Icons.book_outlined, "คู่มือการใช้งาน", () {}),
            _buildDrawerItem(Icons.language, "เปลี่ยนภาษา", () {}),
            
            const Spacer(),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear(); // ล้างทุกอย่างที่จำไว้
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false, // เงื่อนไขนี้ทำให้กดย้อนกลับไม่ได้
                    );
                },
                child: const Text("ออกจากระบบ",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
      onTap: onTap,
    );
  }
}