import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// تم الإبقاء على مكتبة المراسلة لاستخدامها في التهيئة لاحقاً أو إزالتها إذا لم تكن هناك حاجة لـ FirebaseMessaging داخل الـ main حالياً
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'screens/auth/login_screen.dart';
import 'screens/home/rep_home.dart';

void main() async {
  // التأكد من تهيئة أدوات فلاتر قبل أي كود برمجي
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تشغيل الفايربيز
  try {
    await Firebase.initializeApp();
    // طلب إذن الإشعارات هنا يجعل الـ import مستخدماً ويحل مشكلة الـ Unused Import
    await FirebaseMessaging.instance.requestPermission();
    debugPrint("✅ Firebase Initialized & Permissions Requested");
  } catch (e) {
    debugPrint("❌ Firebase Initialization Failed: $e");
  }

  runApp(const AksabERP());
}

class AksabERP extends StatelessWidget {
  const AksabERP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أكسب ERP - منظومة العهدة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFB21F2D),
        useMaterial3: true,
        // إعدادات الخط والألوان الصريحة للنظام
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB21F2D)),
      ),
      // البداية من اللوج إن لضمان الأمان
      home: const LoginScreen(),
      // تعريف المسارات (Routes) الحقيقية
      routes: {
        '/login': (context) => const LoginScreen(),
        '/rep_home': (context) => const RepHomeScreen(), // صفحة المندوب الصريحة
        '/admin_dashboard': (context) => const AdminDashboardPlaceholder(),
      },
    );
  }
}

// مؤقت للمديرين لحين بناء لوحتهم
class AdminDashboardPlaceholder extends StatelessWidget {
  const AdminDashboardPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة'),
        backgroundColor: const Color(0xFF1A2C3D),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('جاري مزامنة بيانات المشرفين والمديرين...')),
    );
  }
}

