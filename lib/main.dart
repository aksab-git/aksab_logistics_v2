import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
// استورد الصفحات الرئيسية (تأكد من وجود الملفات في هذه المسارات)
// import 'screens/home/rep_home.dart'; 
// import 'screens/admin/admin_dashboard.dart';

void main() {
  runApp(const AksabTestApp());
}

class AksabTestApp extends StatelessWidget {
  const AksabTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أكسب للمبيعات - منظومة العهدة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFB21F2D),
        useMaterial3: true,
        fontFamily: 'Cairo', // لو مستخدم خط القاهرة
      ),
      // 1. البداية من صفحة اللوج إن
      home: const LoginScreen(),
      
      // 2. تعريف السكك (Routes)
      routes: {
        '/login': (context) => const LoginScreen(),
        // السكك دي هي اللي الـ LoginView بينادي عليها بعد النجاح
        '/rep_home': (context) => const PlaceholderScreen(title: 'الصفحة الرئيسية للمندوب'), 
        '/admin_dashboard': (context) => const PlaceholderScreen(title: 'لوحة تحكم المشرفين'),
      },
    );
  }
}

// صفحة مؤقتة لحين التأكد من ملفات الـ Home
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFFB21F2D)),
      body: Center(child: Text('جاري تجهيز بيانات العهدة لـ $title...')),
    );
  }
}
