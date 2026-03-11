import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/side_menu_drawer.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? currentBill; // บิลเดือนปัจจุบันที่ยังไม่จ่าย
  List<Map<String, dynamic>> historyBills = []; // ประวัติที่จ่ายแล้ว

  String qrUrl = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // ฟังก์ชันดึงข้อมูลบิลทั้งหมดของห้องตัวเอง
  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? myId = prefs.getInt('userId');

      if (myId == null) return;

      // ดึงบิลทั้งหมดที่เป็นของ ID ห้องนี้เรียงจากใหม่ไปเก่า
      final data = await Supabase.instance.client
          .from('bills')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          // 1. หาบิลที่ "ยังไม่จ่าย" หรือ "รอตรวจสอบ" (เอาใบล่าสุดมาแสดงเป็นบิลปัจจุบัน)
          try {
            currentBill = data.firstWhere(
              (element) => element['status'] != 'ชำระแล้ว',
            );
          } catch (e) {
            currentBill = null; // ถ้าหาไม่เจอแปลว่าจ่ายครบหมดแล้ว
          }

          // 2. หาบิลที่ "ชำระแล้ว" เอาไปใส่ในประวัติ
          historyBills = data
              .where((element) => element['status'] == 'ชำระแล้ว')
              .toList();

          qrUrl = ""; // รีเซ็ต QR ทุกครั้งที่โหลดใหม่
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("Error fetching bill: $e");
    }
  }

  // ฟังก์ชันแจ้งว่าโอนเงินแล้ว
  Future<void> _notifyPayment() async {
    if (currentBill == null) return;

    setState(() => isLoading = true);
    try {
      // อัปเดตสถานะบิลเป็น 'รอตรวจสอบ'
      await Supabase.instance.client
          .from('bills')
          .update({'status': 'รอตรวจสอบ'})
          .eq('id', currentBill!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('แจ้งชำระเงินแล้ว รอแอดมินตรวจสอบ'),
            backgroundColor: Colors.green,
          ),
        );
      }
      fetchData(); // ดึงข้อมูลใหม่เพื่อรีเฟรชหน้าจอ
    } catch (e) {
      print("Update error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.cream,
      endDrawer: const SideMenuDrawer(),
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brownDark,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchData,
                    color: AppColors.brownDark,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "รายการที่ต้องชำระ",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brownDark,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // --- แสดงบิลปัจจุบัน ---
                          _buildCurrentBillSection(),

                          const SizedBox(height: 30),

                          // --- ประวัติการชำระ ---
                          const Text(
                            "ประวัติการชำระ",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brownDark,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // แสดงรายการประวัติที่จ่ายแล้ว
                          historyBills.isEmpty
                              ? const Center(
                                  child: Text(
                                    "ยังไม่มีประวัติการชำระเงิน",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : Column(
                                  children: historyBills.map((bill) {
                                    return _buildHistoryItem(
                                      bill['billing_cycle'] ?? 'ไม่ระบุเดือน',
                                      (bill['total'] ?? 0).toString(),
                                      bill['status'] ?? 'ชำระแล้ว',
                                    );
                                  }).toList(),
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

  // Widget: ส่วนแสดงบิลปัจจุบัน + ปุ่มต่างๆ
  Widget _buildCurrentBillSection() {
    if (currentBill == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text(
              "ไม่มียอดค้างชำระ 🎉",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    double rent = (currentBill!['rent_fee'] ?? 0).toDouble();
    double electric = (currentBill!['electricity_fee'] ?? 0).toDouble();
    double water = (currentBill!['water_fee'] ?? 0).toDouble();
    double total = (currentBill!['total'] ?? 0).toDouble();
    String status = currentBill!['status'] ?? 'รอชำระ';
    String billingCycle = currentBill!['billing_cycle'] ?? 'ไม่ระบุเดือน';

    return Column(
      children: [
        // การ์ดบิล
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "รอบบิล : $billingCycle",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildDetailRow("ค่าเช่า", rent),
              _buildDetailRow("ค่าไฟฟ้า", electric),
              _buildDetailRow("ค่าน้ำ", water),
              const Divider(height: 30, color: AppColors.cream, thickness: 2),
              _buildTotalRow(total),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // เช็คสถานะ: ถ้ารอตรวจสอบ ให้โชว์ป้ายสถานะ ไม่ต้องโชว์ปุ่มจ่ายเงิน
        if (status == 'รอตรวจสอบ')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time_filled, color: Colors.orange),
                SizedBox(width: 10),
                Text(
                  "กำลังรอแอดมินตรวจสอบยอดเงิน",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // ปุ่มสร้าง QR (แสดงเมื่อยังไม่กดแจ้งชำระ)
          ElevatedButton(
            onPressed: () {
              setState(() {
                qrUrl =
                    "https://promptpay.io/0812345678/${total.toInt()}.png?t=${DateTime.now().millisecondsSinceEpoch}";
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brownDark,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "สร้าง QR Code ชำระเงิน",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (qrUrl.isNotEmpty) ...[
            _buildQRCodeSection(),
            const SizedBox(height: 15),
            // ปุ่มยืนยันการโอน
            ElevatedButton(
              onPressed: _notifyPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "แจ้งว่าโอนเงินแล้ว",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildHistoryItem(String month, String amount, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, color: AppColors.brownDark),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "ยอดชำระ: ฿$amount",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            "฿${value.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "ยอดรวมทั้งหมด",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          "฿${value.toStringAsFixed(0)}",
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Image.network(
              qrUrl,
              height: 200,
              key: UniqueKey(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 200,
                  width: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (c, e, s) => const Column(
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  Text("ไม่สามารถโหลด QR Code ได้"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
