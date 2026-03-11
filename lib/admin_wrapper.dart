import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';

// Import หน้าของ Admin
import 'screens/adminnews.dart';
import 'screens/admin_payment.dart';
import 'screens/admin_create_bill.dart';
import 'screens/admin_repair.dart'; // 👈 นำเข้าไฟล์แจ้งซ่อม

class AdminWrapper extends StatefulWidget {
  const AdminWrapper({super.key});

  @override
  State<AdminWrapper> createState() => _AdminWrapperState();
}

class _AdminWrapperState extends State<AdminWrapper> {
  int _selectedIndex = 0;

  // รายการหน้าจอของ Admin
  final List<Widget> _pages = [
    const AdminNewsPage(), // Index 0
    const AdminPaymentPage(), // Index 1
    const AdminCreateBillPage(), // Index 2
    const AdminRepairPage(), // 👈 Index 3: เปลี่ยนจาก Text('กำลังพัฒนา') เป็นอันนี้
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.brownDark,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true, // เปิดให้เห็นตัวหนังสือ
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign, size: 30),
            label: 'ข่าวสาร',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, size: 30),
            label: 'ตรวจบิล',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create, size: 30),
            label: 'สร้างบิล',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build, size: 30),
            label: 'แจ้งซ่อม',
          ),
        ],
      ),
    );
  }
}
