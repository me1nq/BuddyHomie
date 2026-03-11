import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/side_menu_drawer.dart';

class AdminCreateBillPage extends StatefulWidget {
  const AdminCreateBillPage({super.key});

  @override
  State<AdminCreateBillPage> createState() => _AdminCreateBillPageState();
}

class _AdminCreateBillPageState extends State<AdminCreateBillPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isLoadingRooms = true; // เอาไว้เช็คตอนโหลดรายชื่อห้อง

  // 1. เปลี่ยนตัวแปรห้องเป็นค่าว่าง เพื่อรอรับจาก Database
  int? _selectedRoom;
  List<int> _rooms = [];

  // 2. เปลี่ยนรอบบิลเป็นค่าว่าง เพื่อสร้างอัตโนมัติตามเดือนปัจจุบัน
  String? _selectedCycle;
  List<String> _cycles = [];

  final _rentController = TextEditingController();
  final _waterController = TextEditingController();
  final _electricController = TextEditingController();
  final _totalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateBillingCycles(); // สร้างรอบบิลอัตโนมัติ
    _fetchRoomsFromDatabase(); // ดึงรายชื่อห้องจาก Supabase

    _rentController.addListener(_calculateTotal);
    _waterController.addListener(_calculateTotal);
    _electricController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _rentController.dispose();
    _waterController.dispose();
    _electricController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  // --- 🌟 ฟังก์ชันใหม่: ดึงรายชื่อห้องจาก Database ---
  Future<void> _fetchRoomsFromDatabase() async {
    try {
      // ดึง ID จากตาราง auth โดยไม่เอา ID 0 (Admin) และเรียงลำดับจากน้อยไปมาก
      final data = await _supabase
          .from('auth')
          .select('id')
          .neq('id', 0)
          .order('id', ascending: true);

      if (mounted) {
        setState(() {
          // แปลงข้อมูลที่ได้มาเก็บลงใน List<int>
          _rooms = (data as List).map((e) => e['id'] as int).toList();
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching rooms: $e");
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  // --- 🌟 ฟังก์ชันใหม่: สร้างเดือนและปีอัตโนมัติ (Scalable) ---
  void _generateBillingCycles() {
    final thaiMonths = [
      "",
      "มกราคม",
      "กุมภาพันธ์",
      "มีนาคม",
      "เมษายน",
      "พฤษภาคม",
      "มิถุนายน",
      "กรกฎาคม",
      "สิงหาคม",
      "กันยายน",
      "ตุลาคม",
      "พฤศจิกายน",
      "ธันวาคม",
    ];
    DateTime now = DateTime.now();
    List<String> generatedCycles = [];

    // สร้างย้อนหลัง 1 เดือน และล่วงหน้า 5 เดือน (ปรับแก้ได้ตามต้องการ)
    for (int i = -1; i <= 5; i++) {
      DateTime d = DateTime(now.year, now.month + i, 1);
      generatedCycles.add("${thaiMonths[d.month]} ${d.year}");
    }

    setState(() {
      _cycles = generatedCycles;
      _selectedCycle = generatedCycles[1]; // ตั้งค่าเริ่มต้นเป็นเดือนปัจจุบัน
    });
  }

  void _calculateTotal() {
    double rent = double.tryParse(_rentController.text) ?? 0;
    double water = double.tryParse(_waterController.text) ?? 0;
    double electric = double.tryParse(_electricController.text) ?? 0;
    double total = rent + water + electric;
    _totalController.text = total.toStringAsFixed(0);
  }

  Future<void> _submitBill() async {
    if (_selectedRoom == null || _selectedCycle == null) {
      _showSnackBar('กรุณาเลือกห้องและรอบบิล', Colors.red);
      return;
    }

    if (_rentController.text.isEmpty || _totalController.text.isEmpty) {
      _showSnackBar('กรุณากรอกข้อมูลตัวเงินให้ครบ', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existing = await _supabase
          .from('bills')
          .select()
          .eq('user_id', _selectedRoom!)
          .eq('billing_cycle', _selectedCycle!)
          .maybeSingle();

      if (existing != null) {
        _showSnackBar(
          'ห้อง $_selectedRoom มีบิลรอบ $_selectedCycle แล้ว!',
          Colors.orange,
        );
        setState(() => _isLoading = false);
        return;
      }

      await _supabase.from('bills').insert({
        'user_id': _selectedRoom,
        'billing_cycle': _selectedCycle,
        'rent_fee': double.tryParse(_rentController.text) ?? 0,
        'water_fee': double.tryParse(_waterController.text) ?? 0,
        'electricity_fee': double.tryParse(_electricController.text) ?? 0,
        'total': double.tryParse(_totalController.text) ?? 0,
        'status': 'รอชำระ',
      });

      _showSnackBar('สร้างบิลห้อง $_selectedRoom สำเร็จ!', Colors.green);

      _rentController.clear();
      _waterController.clear();
      _electricController.clear();
      setState(() {
        _selectedRoom = null;
      });
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      endDrawer: const SideMenuDrawer(),
      appBar: AppBar(
        title: const Text(
          "ออกบิลค่าเช่า (Admin)",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.brownDark,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "เลือกรอบบิล",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.brownDark,
              ),
            ),
            const SizedBox(height: 8),
            _buildDropdownCycle(),

            const SizedBox(height: 20),
            const Text(
              "เลือกห้องพัก",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.brownDark,
              ),
            ),
            const SizedBox(height: 8),
            _buildDropdownRoom(),

            const SizedBox(height: 20),
            _buildInputRow("ค่าเช่าห้อง", _rentController),
            _buildInputRow("ค่าไฟฟ้า", _electricController),
            _buildInputRow("ค่าน้ำประปา", _waterController),

            const Divider(height: 40, thickness: 2),

            TextField(
              controller: _totalController,
              readOnly: true,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
              decoration: const InputDecoration(
                labelText: "ยอดรวมทั้งหมด (บาท)",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brownDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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
                    : const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  "บันทึกบิลส่งให้ผู้เช่า",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownCycle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("เลือกรอบบิล..."),
          value: _selectedCycle,
          items: _cycles.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (newValue) => setState(() => _selectedCycle = newValue),
        ),
      ),
    );
  }

  Widget _buildDropdownRoom() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _isLoadingRooms
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text(
                "กำลังโหลดรายชื่อห้อง...",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                hint: const Text("เลือกหมายเลขห้อง..."),
                value: _selectedRoom,
                items: _rooms.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      "ห้อง $value",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDark,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedRoom = newValue),
              ),
            ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: "บาท",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.brownDark, width: 2),
          ),
        ),
      ),
    );
  }
}
