import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Loại quyền truy cập thiết bị trong chuỗi 3 bước
enum AppPermissionType {
  location,
  notification,
  camera,
}

/// Trạng thái xử lý quyền của từng bước trong ứng dụng
enum AppPermissionResult {
  notRequested,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  skipped,
}

/// Model mô tả thông tin giao diện và cấu hình của từng màn hình xin quyền
class PermissionStepConfig {
  final AppPermissionType type;
  final String title;
  final String description;
  final String primaryButtonText;
  final String secondaryButtonText;
  final IconData icon;
  final Color accentColor;
  final Permission systemPermission;

  const PermissionStepConfig({
    required this.type,
    required this.title,
    required this.description,
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.icon,
    required this.accentColor,
    required this.systemPermission,
  });

  /// Danh sách 3 màn hình xin cấp quyền theo đúng thiết kế mẫu
  static const List<PermissionStepConfig> steps = [
    PermissionStepConfig(
      type: AppPermissionType.location,
      title: 'Location',
      description: 'Allow maps to access your location while you use the app?',
      primaryButtonText: 'Allow',
      secondaryButtonText: 'Skip for now',
      icon: Icons.location_on_rounded,
      accentColor: Color(0xFFFF5722),
      systemPermission: Permission.locationWhenInUse,
    ),
    PermissionStepConfig(
      type: AppPermissionType.notification,
      title: 'Notification',
      description:
          'Please enable notifications to receive updates and reminders.',
      primaryButtonText: 'Turn on',
      secondaryButtonText: 'Skip for now',
      icon: Icons.notifications_active_rounded,
      accentColor: Color(0xFFFF6D00),
      systemPermission: Permission.notification,
    ),
    PermissionStepConfig(
      type: AppPermissionType.camera,
      title: 'Camera',
      description: 'We need access to your camera to scan QR codes.',
      primaryButtonText: 'Turn on',
      secondaryButtonText: 'Skip for now',
      icon: Icons.camera_alt_rounded,
      accentColor: Color(0xFFFF3D00),
      systemPermission: Permission.camera,
    ),
  ];
}
