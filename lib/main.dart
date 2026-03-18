import 'package:flutter/material.dart';
import 'screens/auth/register_screen.dart'; // تأكد من صحة المسار

void main() {
  runApp(const AksabTestApp());
}

class AksabTestApp extends StatelessWidget {
  const AksabTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aksab Logistics Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      // هنا بنجبر التطبيق يفتح على صفحة التسجيل مباشرة
      home: const RegisterScreen(), 
    );
  }
}

