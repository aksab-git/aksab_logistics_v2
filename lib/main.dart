import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/rep_home.dart'; // حننشأ الملف ده حالاً

void main() async {
  // التأكد من تهيئة أدوات فلاتر قبل أي كود برمجي
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. تشغيل الفايربيز (يقرأ google-services.json تلقائياً)
  try {
    await Firebase.initializeApp();
    print("✅ تم ربط Firebase بنجاح");
  } catch (e) {
    print("❌ فشل ربط Firebase: $e");
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
      // البداية دايماً من اللوج إن لضمان الأمان
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
      appBar: AppBar(title: const Text('لوحة تحكم الإدارة'), backgroundColor: const Color(0xFF1A2C3D), foregroundColor: Colors.white),
      body: const Center(child: Text('جاري مزامنة بيانات المشرفين والمديرين...')),
    );
  }
}
