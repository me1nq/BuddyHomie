import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/side_menu_drawer.dart';

class AdminPaymentPage extends StatefulWidget {
  const AdminPaymentPage({super.key});

  @override
  State<AdminPaymentPage> createState() => _AdminPaymentPageState();
}

class _AdminPaymentPageState extends State<AdminPaymentPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _bills = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingBills();
  }

  // 1. ดึงข้อมูลบิลทั้งหมดที่ยังไม่ได้ยืนยันการชำระ
  Future<void> _fetchPendingBills() async {
    setState(() => _isLoading = true);
    try {
      // ดึงบิลที่สถานะไม่ใช่ 'ชำระแล้ว' (เช่น 'รอชำระ' หรือ 'รอตรวจสอบ')
      final data = await _supabase
          .from('bills')
          .select()
          .neq('status', 'ชำระแล้ว')
          .order('id', ascending: false);

      if (mounted) {
        setState(() {
          _bills = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching bills: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. ฟังก์ชันกดยืนยันการชำระเงิน
  Future<void> _confirmPayment(int billId, int roomId) async {
    // โชว์ Dialog ถามเพื่อความแน่ใจก่อนกดยืนยัน
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text(
          "ยืนยันการชำระเงิน?",
          style: TextStyle(
            color: AppColors.brownDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "คุณต้องการยืนยันว่าห้อง $roomId ชำระเงินเรียบร้อยแล้วใช่หรือไม่?",
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
              try {
                // อัปเดตสถานะใน Supabase เป็น 'ชำระแล้ว'
                await _supabase
                    .from('bills')
                    .update({'status': 'ชำระแล้ว'})
                    .eq('id', billId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ยืนยันการชำระเงินเรียบร้อยแล้ว!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _fetchPendingBills(); // รีเฟรชรายการใหม่
              } catch (e) {
                debugPrint("Update error: $e");
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
          "ตรวจสอบการชำระเงิน",
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
          : _bills.isEmpty
          ? const Center(
              child: Text(
                "ไม่มีรายการรอตรวจสอบ 🎉",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchPendingBills,
              color: AppColors.brownDark,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _bills.length,
                itemBuilder: (context, index) {
                  final bill = _bills[index];
                  final roomId = bill['user_id'] ?? 0;
                  final total = bill['total'] ?? 0;
                  // สมมติว่ามีรอบบิล หรือเอา created_at มาโชว์
                  final billingCycle = bill['billing_cycle'] ?? 'ไม่ระบุเดือน';
                  final status = bill['status'] ?? 'รอชำระ';

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // ไอคอนห้องพัก
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.brownLight.withOpacity(
                              0.2,
                            ),
                            child: const Icon(
                              Icons.meeting_room,
                              color: AppColors.brownDark,
                            ),
                          ),
                          const SizedBox(width: 15),

                          // ข้อมูลบิล
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ห้อง: $roomId",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brownDark,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "รอบบิล: $billingCycle",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "ยอดสุทธิ: $total ฿",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "สถานะ: $status",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ปุ่มยืนยัน
                          ElevatedButton(
                            onPressed: () =>
                                _confirmPayment(bill['id'], roomId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brownDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "ยืนยัน",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
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
