import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/side_menu_drawer.dart';

class AdminRepairPage extends StatefulWidget {
  const AdminRepairPage({super.key});

  @override
  State<AdminRepairPage> createState() => _AdminRepairPageState();
}

class _AdminRepairPageState extends State<AdminRepairPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _repairs = [];

  @override
  void initState() {
    super.initState();
    _fetchAllRepairs();
  }

  // ดึงข้อมูลแจ้งซ่อมของ *ทุกห้อง*
  Future<void> _fetchAllRepairs() async {
    setState(() => _isLoading = true);
    try {
      // ดึงข้อมูลแจ้งซ่อมทั้งหมด เรียงตามเวลาล่าสุด
      final data = await _supabase
          .from('repair')
          .select()
          .order('created_at', ascending: false);

      // นำมาจัดเรียงใหม่ในแอป: ให้ 'ซ่อมเสร็จแล้ว' ไปอยู่ข้างล่างสุด
      List<dynamic> sortedData = List.from(data);
      sortedData.sort((a, b) {
        bool aDone = a['status'] == 'ซ่อมเสร็จแล้ว';
        bool bDone = b['status'] == 'ซ่อมเสร็จแล้ว';

        if (aDone && !bDone) return 1; // ให้ a ร่วงไปข้างล่าง
        if (!aDone && bDone) return -1; // ให้ b ร่วงไปข้างล่าง

        // ถ้าสถานะเหมือนกัน (เช่น ยังไม่เสร็จทั้งคู่) ให้เรียงตามเวลา (ใหม่ไปเก่า)
        DateTime dateA = DateTime.parse(a['created_at']);
        DateTime dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _repairs = sortedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching repairs: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันยืนยันซ่อมเสร็จ
  Future<void> _confirmRepair(int repairId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text(
          "ยืนยันการซ่อม?",
          style: TextStyle(
            color: AppColors.brownDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "คุณต้องการเปลี่ยนสถานะเป็น 'ซ่อมเสร็จแล้ว' ใช่หรือไม่?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context); // ปิดหน้าต่าง
              setState(() => _isLoading = true);
              try {
                // อัปเดตตาราง
                await _supabase
                    .from('repair')
                    .update({'status': 'ซ่อมเสร็จแล้ว'})
                    .eq('id', repairId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('อัปเดตสถานะสำเร็จ!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                // ดึงข้อมูลใหม่เพื่อจัดเรียงการ์ดใหม่
                _fetchAllRepairs();
              } catch (e) {
                debugPrint("Update error: $e");
                setState(() => _isLoading = false);
              }
            },
            child: const Text("ยืนยัน", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      endDrawer: const SideMenuDrawer(),
      appBar: AppBar(
        title: const Text(
          "จัดการแจ้งซ่อม (Admin)",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.brownDark,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brownDark),
            )
          : _repairs.isEmpty
          ? const Center(
              child: Text(
                "ไม่มีรายการแจ้งซ่อม 🎉",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          // ใส่ RefreshIndicator เพื่อให้แอดมินดึงหน้าจอลงมาอัปเดตข้อมูลได้
          : RefreshIndicator(
              onRefresh: _fetchAllRepairs,
              color: AppColors.brownDark,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _repairs.length,
                itemBuilder: (context, index) {
                  final item = _repairs[index];
                  final date = DateTime.parse(item['created_at']);
                  final isDone = item['status'] == 'ซ่อมเสร็จแล้ว';
                  final roomId = item['user_id'] ?? 'ไม่ระบุ';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: isDone ? 1 : 4, // งานที่เสร็จแล้วการ์ดจะแบนลง
                    color: isDone
                        ? Colors.grey.shade100
                        : Colors.white, // พื้นหลังจางลงเมื่อเสร็จ
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ป้ายบอกเลขห้อง
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? Colors.grey
                                      : AppColors.brownDark,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "ห้อง $roomId",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              // ป้ายสถานะ
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDone ? Colors.green : Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  item['status'] ?? 'รอดำเนินการ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['issue_title'] ?? 'ไม่ระบุหัวข้อ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDone ? Colors.grey : AppColors.brownDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "รายละเอียด: ${item['issue_detail'] ?? '-'}",
                            style: TextStyle(
                              color: isDone ? Colors.grey : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "แจ้งเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),

                          if (item['image_path'] != null) ...[
                            const SizedBox(height: 10),
                            Opacity(
                              opacity: isDone
                                  ? 0.6
                                  : 1.0, // ถ้ารูปเสร็จแล้วให้รูปจางลงหน่อย
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item['image_path'],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Text(
                                    "ไม่สามารถโหลดรูปภาพได้",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          if (!isDone) ...[
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _confirmRepair(item['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "ยืนยันว่าซ่อมเสร็จแล้ว",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
