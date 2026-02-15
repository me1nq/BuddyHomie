import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_header.dart';     // 1. เรียก Header
import '../../widgets/side_menu_drawer.dart';  // 2. เรียก Drawer

/* =======================
   MODEL
======================= */
class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

/* =======================
   SCREEN
======================= */
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // Key สำหรับสั่งเปิด Drawer (เพราะหน้านี้เราใช้ CustomHeader)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<ChatMessage> messages = [];
  final TextEditingController controller = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      'สวัสดีครับ! ผมคือ Chatbot ผู้ช่วยหอพัก 🏠\nมีอะไรให้ช่วยไหมครับ?',
    );
  }

  /* =======================
      BOT LOGIC
  ======================= */
  String botReply(String input) {
    input = input.toLowerCase();

    if (input.contains('ชำระ') || input.contains('จ่าย') || input.contains('โอน')) {
      return 'สามารถชำระได้ที่เมนู "รายการที่ต้องชำระ" (รูปบิล)\nโดยกดปุ่มสร้าง QR Code เพื่อสแกนจ่ายได้เลยครับ';
    } else if (input.contains('ค่าน้ำ') || input.contains('ค่าไฟ')) {
      return 'ค่าน้ำและค่าไฟจะถูกคำนวณตามมิเตอร์ และรวมอยู่ในบิลแต่ละเดือนครับ';
    } else if (input.contains('ซ่อม') || input.contains('พัง') || input.contains('เสีย')) {
      return 'หากมีอุปกรณ์ชำรุด สามารถแจ้งซ่อมได้ที่เมนู "แจ้งซ่อม" (รูปไขควง) พร้อมถ่ายรูปแนบมาได้เลยครับ';
    } else if (input.contains('ติดต่อ') || input.contains('โทร')) {
      return 'ติดต่อเจ้าหน้าที่หอพักได้ที่เบอร์\n📞 081-234-5678 (ป้าพร)\nหรือติดต่อที่ออฟฟิศชั้น 1 ครับ';
    } else {
      return 'ขออภัยครับ ผมยังไม่เข้าใจคำถามนี้\nลองเลือกหัวข้อจากปุ่มด้านบน หรือติดต่อเจ้าหน้าที่โดยตรงได้เลยครับ';
    }
  }

  Future<void> saveMessageToSupabase(String text) async {
    try {
      await supabase.from('Chatbot').insert({'message': text});
    } catch (e) {
      debugPrint('❌ Supabase error: $e');
    }
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true, time: _timeNow());
    setState(() {
      messages.add(userMessage);
    });

    controller.clear();
    await saveMessageToSupabase('USER: $text');

    Future.delayed(const Duration(milliseconds: 600), () async {
      final reply = botReply(text);
      final botMessage = ChatMessage(text: reply, isUser: false, time: _timeNow());

      if (mounted) {
        setState(() {
          messages.add(botMessage);
        });
      }
      await saveMessageToSupabase('BOT: $reply');
    });
  }

  void _addBotMessage(String text) {
    final botMessage = ChatMessage(text: text, isUser: false, time: _timeNow());
    setState(() {
      messages.add(botMessage);
    });
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /* =======================
      UI (แก้ไขใหม่)
  ======================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // 1. ผูก Key
      backgroundColor: AppColors.cream,
      endDrawer: const SideMenuDrawer(), // 2. ใส่ Drawer

      // 3. ใช้ Column แทนการใช้ AppBar
      body: Column(
        children: [
          // ส่วนหัว Custom Header
          const CustomHeader(),

          // ส่วนเนื้อหา Chat (ต้องใช้ Expanded เพื่อให้เต็มพื้นที่ที่เหลือ)
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // หัวข้อหน้า (มาแทน Title ของ AppBar เดิม)
                const Text(
                  'Chatbot ผู้ช่วย',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold, 
                    color: AppColors.brownDark
                  ),
                ),
                const Text(
                  'ตอบคำถามอัตโนมัติ 24 ชม.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                // ปุ่มทางลัด
                _quickButtons(),

                // รายการแชท
                Expanded(child: _chatList()),

                // ช่องพิมพ์ข้อความ
                _inputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _quickButton('💸 วิธีชำระเงิน'),
            const SizedBox(width: 8),
            _quickButton('🛠️ แจ้งซ่อม'),
            const SizedBox(width: 8),
            _quickButton('📞 ติดต่อเจ้าหน้าที่'),
          ],
        ),
      ),
    );
  }

  Widget _quickButton(String text) {
    return ElevatedButton(
      onPressed: () => sendMessage(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brownDark,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.brownLight, width: 1),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _chatList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: msg.isUser ? AppColors.brownDark : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
                bottomRight: Radius.circular(msg.isUser ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    color: msg.isUser ? Colors.white : AppColors.brownDark,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    msg.time,
                    style: TextStyle(
                      fontSize: 10,
                      color: msg.isUser ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'พิมพ์ข้อความสอบถาม...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: AppColors.brownDark,
            radius: 22,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => sendMessage(controller.text),
            ),
          ),
        ],
      ),
    );
  }
}