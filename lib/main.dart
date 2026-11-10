import 'package:flutter/material.dart';
import 'screens/permission_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UthPermissionApp());
}

/// Ứng dụng xin cấp quyền truy cập thiết bị (Location, Notification, Camera)
/// Toàn bộ giao diện được đặt bên trong khung Smartphone duy nhất ở chính giữa màn hình.
class UthPermissionApp extends StatelessWidget {
  const UthPermissionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UTH Device Permissions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          primary: const Color(0xFFFF5722),
        ),
        scaffoldBackgroundColor: const Color(0xFFE5E7EB),
      ),
      home: const PermissionScreen(),
    );
  }
}
