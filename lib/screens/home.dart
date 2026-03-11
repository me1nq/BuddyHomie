import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_header.dart';
import 'adminnews.dart'; // เรียกใช้หน้า Admin

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ฟังก์ชันดึงข้อมูลจากตาราง 'home'
  Future<List<Map<String, dynamic>>> _fetchNews() async {
    final response = await Supabase.instance.client
        .from('home')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. ส่วนหัว (Header) - ใส่ตรงนี้เพื่อให้ติดด้านบนตลอด
        const CustomHeader(),

        // 2. ส่วนเนื้อหา (Scroll ได้)
        Expanded(
          // 👈 1. ครอบด้วย RefreshIndicator
          child: RefreshIndicator(
            color: AppColors.brownDark,
            onRefresh: () async {
              // 👈 2. เมื่อปัดลง สั่งให้หน้าจอ Build ใหม่เพื่อดึง _fetchNews() อีกรอบ
              setState(() {});
            },
            child: SingleChildScrollView(
              // 👈 3. ใส่ physics นี้สำคัญมาก ไม่งั้นถ้าข่าวมีน้อยจะปัดลงไม่ได้!
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อข่าวสาร
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      "ข่าวสาร",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDark, // ใช้สีธีม
                      ),
                    ),
                  ),

                  // รายการข่าวสาร (ดึงจาก Database)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchNews(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brownDark,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"),
                        );
                      }

                      final newsList = snapshot.data ?? [];

                      if (newsList.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              "ยังไม่มีข่าวสารใหม่",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets
                            .zero, // ลบ padding บนล่างออกเพื่อให้ชิดขอบ
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // ให้ Scroll ตาม Parent
                        itemCount: newsList.length,
                        itemBuilder: (context, index) {
                          final item = newsList[index];
                          return _buildNewsCard(
                            "ประกาศจากหอพัก",
                            item['news'] ?? '',
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ปุ่ม Admin (สำหรับ Dev เท่านั้น)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminNewsPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        "จัดการข่าวสาร (Admin Mode)",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40), // เผื่อพื้นที่ด้านล่าง
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget สำหรับสร้าง Card ข่าวสาร
  Widget _buildNewsCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ไอคอนโทรโข่ง
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brownLight.withOpacity(0.2), // พื้นหลังไอคอนจางๆ
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign,
              color: AppColors.brownDark,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.brownDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  // maxLines: 3, // ถ้าอยากให้แสดงยาวๆ ก็ปิดบรรทัดนี้ได้
                  // overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
