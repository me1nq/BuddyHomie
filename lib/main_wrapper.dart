import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'widgets/side_menu_drawer.dart'; 

// Import หน้าต่างๆ ให้ครบ
import 'screens/home.dart';
import 'screens/billing.dart'; 
import 'screens/repair.dart';   
import 'screens/chatbot.dart'; 
// import 'screens/adminnews.dart'; // หน้านี้เราเข้าผ่านปุ่มลับใน Home ไม่ต้องใส่ใน Tab

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  
  // Key สำหรับ Scaffold (ใช้สำหรับหน้า Home ที่ไม่มี Scaffold ของตัวเอง)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- แก้ไขตรงนี้: เรียกใช้หน้าจริงแทน Text ---
  final List<Widget> _pages = [
    const HomeScreen(),       // Index 0: หน้าหลัก
    const BillingPage(),      // Index 1: หน้าบิล (เรียกไฟล์ billing.dart)
    const RepairPage(),       // Index 2: หน้าแจ้งซ่อม (เรียกไฟล์ repair.dart)
    const ChatbotScreen(),    // Index 3: หน้าแชท (เรียกไฟล์ chatbot.dart)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, 
      backgroundColor: AppColors.cream,
      
      // Drawer นี้จะทำงานเมื่ออยู่ในหน้า Home (เพราะ Home ไม่มี Scaffold)
      // ส่วนหน้าอื่น (Repair, Billing) มันมี Scaffold ของตัวเอง มันจะใช้ Drawer ของตัวมันเอง
      endDrawer: const SideMenuDrawer(), 

      body: SafeArea(
        // ใช้ IndexedStack เพื่อให้เปลี่ยนหน้าแล้วค่าไม่หาย (เช่น พิมพ์แชทค้างไว้)
        // หรือจะใช้ _pages[_selectedIndex] เฉยๆ ก็ได้ แต่ IndexedStack ดีกว่าสำหรับแอปแบบนี้
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.brownDark,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 30), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long, size: 30), label: 'Invoice'),
          BottomNavigationBarItem(icon: Icon(Icons.build, size: 30), label: 'Repair'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline, size: 30), label: 'Chat'),
        ],
      ),
    );
  }
}