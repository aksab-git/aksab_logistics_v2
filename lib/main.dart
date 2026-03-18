import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

// --- استيراد الشاشات ---
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/rep/sales_rep_home_screen.dart';
import 'screens/rep/visit_screen.dart';
import 'screens/rep/add_new_customer.dart';

// --- شاشات الإدارة (Admin) ---
import 'screens/admin/sales_management_dashboard.dart';
import 'screens/admin/live_monitoring_screen.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/admin/sales_orders_report_screen.dart';
import 'screens/admin/performance_dashboard_screen.dart';
import 'screens/admin/customers_report_screen.dart';
import 'screens/admin/offers_screen.dart';

void main() {
  // ✅ التأكد من تهيئة الـ Widgets بدون فايربيز
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⛔ تم حذف Firebase.initializeApp تماماً
  
  runApp(const AksabLogisticsApp());
}

class AksabLogisticsApp extends StatelessWidget {
  const AksabLogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Aksab Logistics v2', // تم تحديث الاسم
          debugShowCheckedModeBanner: false,
          
          // ✅ الحفاظ على اتجاه النص العربي (RTL)
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          
          theme: ThemeData(
            primarySwatch: Colors.green,
            fontFamily: 'Cairo', 
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF43B97F),
              primary: const Color(0xFF43B97F),
            ),
          ),
          
          // البداية من شاشة اللوجن
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/rep_home': (context) => const SalesRepHomeScreen(),
            '/visits': (context) => const VisitScreen(),
            '/add_customer': (context) => const AddNewCustomerScreen(),
            
            // --- مسارات الإدارة ---
            '/admin_dashboard': (context) => const SalesManagementDashboard(),
            '/live_monitoring': (context) => const LiveMonitoringScreen(),
            '/manage_users': (context) => const ManageUsersScreen(),
            '/sales_report': (context) => const SalesOrdersReportScreen(),
            '/customers_report': (context) => const CustomersReportScreen(),
            '/offers': (context) => const OffersScreen(),
            
            '/performance_dashboard': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return PerformanceDashboardScreen(
                targetDocId: args?['targetDocId'] ?? '',
                targetType: args?['targetType'] ?? 'rep',
                targetName: args?['targetName'] ?? 'المستخدم',
                repCode: args?['repCode'],
              );
            },
          },
        );
      },
    );
  }
}

