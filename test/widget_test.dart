// ไฟล์: test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// เปลี่ยน dormapp เป็นชื่อ package ตามใน pubspec.yaml ของมึงนะ
// ปกติถ้าสร้างใหม่ๆ มันน่าจะชื่อเดิม ถ้า error ให้แก้ตรงนี้
import 'package:dormapp/main.dart'; 

void main() {
  testWidgets('App start smoke test', (WidgetTester tester) async {
    // 1. สร้าง Widget ขึ้นมาจำลอง (เปลี่ยนจาก MyApp เป็น DormitoryApp)
    await tester.pumpWidget(const DormitoryApp(isLoggedIn: true));

    // 2. รอให้มันวาดหน้าจอเสร็จ
    await tester.pump();

    // 3. ตรวจสอบว่าเจอคำว่า "ข่าวสาร" หรือไม่ (เพราะเราใส่ไว้ในหน้า Home)
    expect(find.text('ข่าวสาร'), findsOneWidget);

    // 4. ตรวจสอบว่าต้อง "ไม่เจอ" เลข 0 (ของเก่า)
    expect(find.text('0'), findsNothing);
  });
}