import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ นำเข้า SharedPreferences
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/side_menu_drawer.dart';

class RepairPage extends StatefulWidget {
  const RepairPage({super.key});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  int? _currentUserId; // ✅ ตัวแปรเก็บ ID ห้องของผู้ใช้

  @override
  void initState() {
    super.initState();
    _loadUserId(); // ✅ โหลด ID ทันทีที่เปิดหน้านี้
  }

  // ฟังก์ชันดึง ID จากเครื่อง
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId'); // เช่น 101, 102, 109
    });
  }

  // ฟังก์ชันเลือกรูปภาพ
  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  // ฟังก์ชันส่งข้อมูลแจ้งซ่อม
  Future<void> _submitRepair() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาระบุหัวข้อปัญหา')));
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาล็อกอินใหม่ ไม่พบข้อมูลผู้ใช้')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imagePath;

      // 1. Upload รูป (ของจริง)
      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage
            .from('repair_images')
            .upload(fileName, _imageFile!);
        imagePath = _supabase.storage
            .from('repair_images')
            .getPublicUrl(fileName);
      }

      // 2. Insert ลง Table 'repair' พร้อมแนบ user_id ✅
      await _supabase.from('repair').insert({
        'user_id': _currentUserId, // 👈 ส่ง ID แจ้งซ่อม
        'issue_title': _titleController.text,
        'issue_detail': _detailController.text,
        'image_path': imagePath,
        'status': 'กำลังดำเนินการ',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Clear ค่าหลังส่งเสร็จ
      _titleController.clear();
      _detailController.clear();
      setState(() {
        _imageFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งแจ้งซ่อมเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Stream ดึงประวัติ (แบบกรอง ID แล้ว ✅)
  Stream<List<Map<String, dynamic>>> _getRepairHistory() {
    if (_currentUserId == null)
      return Stream.value([]); // ถ้ายังไม่มี ID ให้คืนค่าว่างก่อน

    return _supabase
        .from('repair')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId!) // 👈 กรองเฉพาะของห้องเราเท่านั้น
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => e as Map<String, dynamic>).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.cream,
      endDrawer: const SideMenuDrawer(),

      body: Column(
        children: [
          // 1. Header (Custom)
          const CustomHeader(),

          // 2. เนื้อหา (Scroll ได้)
          Expanded(
            // 👈 1. ครอบด้วย RefreshIndicator
            child: RefreshIndicator(
              color: AppColors.brownDark,
              onRefresh: () async {
                // หน้าเราเป็น Stream อยู่แล้ว แค่สั่ง setState ให้แอนิเมชันหมุนทำงานก็พอครับ
                setState(() {});
              },
              child: SingleChildScrollView(
                // 👈 2. ใส่ physics เพื่อให้ปัดจอลงได้เสมอ แม้ข้อมูลจะมีนิดเดียว
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'แจ้งปัญหา',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- ส่วนกรอกข้อมูล ---
                    _buildLabel('หัวข้อปัญหา'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      _titleController,
                      'เช่น หลอดไฟดับ, ท่อน้ำรั่ว',
                      height: 50,
                    ),

                    const SizedBox(height: 16),
                    _buildLabel('รายละเอียด'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      _detailController,
                      'อธิบายรายละเอียดเพิ่มเติม...',
                      maxLines: 5,
                      height: 120,
                    ),

                    const SizedBox(height: 16),
                    _buildLabel('รูปภาพประกอบ'),
                    const SizedBox(height: 8),

                    // กล่องเลือกรูปภาพ
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade300),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: AppColors.brownLight,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'แตะเพื่อถ่ายหรือเลือกรูป',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ปุ่มส่งข้อมูล
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitRepair,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brownDark,
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text(
                          'ส่งแจ้งซ่อม',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),

                    // --- ส่วนประวัติ ---
                    const Text(
                      'ประวัติการแจ้งปัญหา',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // รายการประวัติ
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _getRepairHistory(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.brownDark,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.center,
                            child: const Text(
                              'ยังไม่มีประวัติการแจ้งซ่อม',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        final repairs = snapshot.data!;
                        return ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: repairs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = repairs[index];
                            final date = DateTime.parse(item['created_at']);
                            final status = item['status'] ?? 'รอดำเนินการ';
                            final isDone = status == 'ซ่อมเสร็จแล้ว';

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: isDone
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  child: Icon(
                                    isDone
                                        ? Icons.check_circle
                                        : Icons.access_time_filled,
                                    color: isDone
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                title: Text(
                                  item['issue_title'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brownDark,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(date),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget: ป้ายหัวข้อ (Capsule Style)
  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brownLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget: ช่องกรอกข้อมูล
  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    double? height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                  onPressed: () => controller.clear(),
                )
              : null,
        ),
      ),
    );
  }
}
