import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart'; // เรียกใช้สีธีม
import '../../widgets/custom_header.dart';   // เรียกใช้ Header
import '../../widgets/side_menu_drawer.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  // Key สำหรับเปิด Drawer (เพราะหน้านี้เราใช้ CustomHeader)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  double rent = 0, electric = 0, water = 0, total = 0;
  String qrUrl = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      // ดึงข้อมูลบิล (ตอนนี้ดึงแค่อันแรกมาโชว์ก่อน)
      final data = await Supabase.instance.client
          .from('bills')
          .select()
          .limit(1)
          .single();
          
      if (mounted) {
        setState(() {
          rent = (data['rent_fee'] ?? 0).toDouble();
          electric = (data['electricity_fee'] ?? 0).toDouble();
          water = (data['water_fee'] ?? 0).toDouble();
          total = (data['total'] ?? 0).toDouble();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("Error fetching bill: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // ผูก Key
      backgroundColor: AppColors.cream, // สีพื้นหลังครีม
      
      // เรียกใช้ Drawer กลาง (ถ้าใช้ MainWrapper แล้ว อาจไม่ต้องใส่บรรทัดนี้ก็ได้ 
      // แต่ใส่ไว้กันเหนียวเผื่อเรียกหน้านี้เดี่ยวๆ)
      endDrawer: const SideMenuDrawer(), 

      body: Column(
        children: [
          // 1. ส่วนหัว (Header)
          CustomHeader(), // ส่ง key ไปให้ปุ่มเมนูทำงาน

          // 2. ส่วนเนื้อหา (Scroll ได้)
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brownDark))
                : SingleChildScrollView(
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
                        const SizedBox(height: 5),
                        Text(
                          "รอบบิล : 16 มกราคม 2026", // อนาคตอาจดึงจาก DB
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 15),

                        // Card รายการปัจจุบัน
                        _buildCurrentBillCard(),

                        const SizedBox(height: 25),
                        
                        // ปุ่มสร้าง QR
                        _buildPayButton(),

                        // ส่วนแสดง QR Code
                        if (qrUrl.isNotEmpty) _buildQRCodeSection(),

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
                        
                        // รายการประวัติ (Mockup)
                        _buildHistoryItem("ธันวาคม 2025", "10,500", "ชำระแล้ว"),
                        _buildHistoryItem("พฤศจิกายน 2025", "10,800", "ชำระแล้ว"),
                        _buildHistoryItem("ตุลาคม 2025", "9,900", "ชำระแล้ว"),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget: Card รายการปัจจุบัน
  Widget _buildCurrentBillCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow("ค่าเช่า", rent),
          _buildDetailRow("ค่าไฟฟ้า", electric),
          _buildDetailRow("ค่าน้ำ", water),
          const Divider(height: 30, color: AppColors.cream, thickness: 2),
          _buildTotalRow(total),
        ],
      ),
    );
  }

  // Widget: ปุ่มจ่ายเงิน
  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          // สร้าง URL พร้อม timestamp เพื่อไม่ให้ cache รูปเก่า
          qrUrl = "https://promptpay.io/0812345678/${total.toInt()}.png?t=${DateTime.now().millisecondsSinceEpoch}";
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brownDark,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code, color: Colors.white),
          SizedBox(width: 10),
          Text(
            "สร้าง QR Code ชำระเงิน",
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Widget: ประวัติการชำระ (Item)
  Widget _buildHistoryItem(String month, String amount, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              key: UniqueKey(), // บังคับให้โหลดรูปใหม่เสมอ
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 200, 
                  width: 200, 
                  child: Center(child: CircularProgressIndicator())
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
          const SizedBox(height: 10),
          const Text(
            "สแกน QR Code เพื่อชำระเงิน",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}