import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart'; // เรียกใช้ไฟล์สีของเรา
import '../../widgets/side_menu_drawer.dart'; // 👈 นำเข้า Drawer ของเรา

class AdminNewsPage extends StatefulWidget {
  const AdminNewsPage({super.key});

  @override
  State<AdminNewsPage> createState() => _AdminNewsPageState();
}

class _AdminNewsPageState extends State<AdminNewsPage> {
  final _newsController = TextEditingController();
  bool _isLoading = false;

  // 1. ดึงข้อมูลข่าวสาร
  Future<List<Map<String, dynamic>>> _fetchNews() async {
    final response = await Supabase.instance.client
        .from('home')
        .select()
        .order('created_at', ascending: false); // เรียงจากใหม่ไปเก่า
    return List<Map<String, dynamic>>.from(response);
  }

  // 2. ฟังก์ชันประกาศข่าวใหม่
  Future<void> _postNews() async {
    if (_newsController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('home').insert({
        'news': _newsController.text,
        // 'created_at': DateTime.now().toIso8601String(), // Supabase มักจะทำให้เอง แต่ถ้าต้องส่งก็เปิดบรรทัดนี้
      });
      _newsController.clear();
      setState(() {}); // รีเฟรชหน้าจอ
      _showSnackBar('ประกาศข่าวเรียบร้อยแล้ว');
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. ฟังก์ชันลบข่าวสาร
  Future<void> _deleteNews(int id) async {
    try {
      await Supabase.instance.client.from('home').delete().eq('id', id);
      setState(() {});
      _showSnackBar('ลบประกาศเรียบร้อยแล้ว');
    } catch (e) {
      _showSnackBar('ลบไม่สำเร็จ: $e');
    }
  }

  // 4. ฟังก์ชันแก้ไขข่าวสาร
  Future<void> _editNews(int id, String currentContent) async {
    final editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream, // พื้นหลัง Dialog สีครีม
        title: const Text(
          "แก้ไขประกาศ",
          style: TextStyle(
            color: AppColors.brownDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.brownDark),
            ),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brownDark,
            ),
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('home')
                    .update({'news': editController.text})
                    .eq('id', id);
                if (mounted) Navigator.pop(context);
                setState(() {}); // รีเฟรชหลังแก้เสร็จ
                _showSnackBar('แก้ไขเรียบร้อย');
              } catch (e) {
                _showSnackBar('แก้ไขไม่สำเร็จ: $e');
              }
            },
            child: const Text("บันทึก", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.brownDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream, // พื้นหลังแอปสีครีม
      endDrawer: const SideMenuDrawer(),
      appBar: AppBar(
        title: const Text(
          "จัดการข่าวสาร (Admin)",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.brownDark, // สีหัวเว็บตามธีม
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // ลูกศรย้อนกลับสีขาว
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- ส่วนฟอร์มเพิ่มข่าว ---
          Container(
            padding: const EdgeInsets.all(20.0),
            color: Colors.white, // ให้พื้นหลังส่วนกรอกข้อมูลเป็นสีขาวจะได้เด่น
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _newsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "พิมพ์ข่าวสารใหม่ที่นี่...",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.brownDark),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brownDark,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _postNews,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brownDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          "ประกาศข่าว",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "รายการประกาศทั้งหมด",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.brownDark,
                ),
              ),
            ),
          ),

          // --- ส่วนรายการข่าว ---
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brownDark,
              onRefresh: () async {
                setState(() {}); // ดึงข้อมูลจากฐานข้อมูลใหม่
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
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

                  // 👈 กรณีไม่มีข่าว ต้องใช้ ListView เพื่อให้มีพื้นที่ปัดลงได้
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        const Center(
                          child: Text(
                            "ยังไม่มีประกาศข่าว",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    );
                  }

                  final news = snapshot.data!;
                  return ListView.builder(
                    // 👈 ใส่ physics ตรงนี้ด้วย
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: news.length,
                    itemBuilder: (context, index) {
                      final item = news[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.brownLight.withOpacity(
                              0.2,
                            ),
                            child: const Icon(
                              Icons.campaign,
                              color: AppColors.brownDark,
                            ),
                          ),
                          title: Text(
                            item['news'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              "ID: ${item['id']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () =>
                                    _editNews(item['id'], item['news']),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteNews(item['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
