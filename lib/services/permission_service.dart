import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/permission_item.dart';

/// Dịch vụ quản lý kiểm tra và gửi yêu cầu cấp quyền thực tế đến hệ điều hành
class PermissionService {
  /// Kiểm tra nền tảng có hỗ trợ permission_handler trực tiếp hay không
  bool get isNativePermissionSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Chuyển đổi PermissionStatus của hệ điều hành sang AppPermissionResult
  AppPermissionResult mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return AppPermissionResult.granted;
    }
    if (status.isPermanentlyDenied) {
      return AppPermissionResult.permanentlyDenied;
    }
    if (status.isRestricted) {
      return AppPermissionResult.restricted;
    }
    return AppPermissionResult.denied;
  }

  /// Kiểm tra trạng thái hiện tại của một quyền cụ thể mà không bật hộp thoại
  Future<AppPermissionResult> checkPermissionStatus(
    AppPermissionType type,
  ) async {
    if (!isNativePermissionSupported) {
      if (type == AppPermissionType.location) {
        try {
          final geoPerm = await Geolocator.checkPermission();
          if (geoPerm == LocationPermission.always ||
              geoPerm == LocationPermission.whileInUse) {
            return AppPermissionResult.granted;
          }
          if (geoPerm == LocationPermission.deniedForever) {
            return AppPermissionResult.permanentlyDenied;
          }
        } catch (_) {}
      }
      return AppPermissionResult.notRequested;
    }

    final permission = _getSystemPermission(type);
    final status = await permission.status;
    return mapStatus(status);
  }

  /// Kiểm tra trạng thái của toàn bộ 3 quyền (dùng khi khởi động hoặc quay lại từ Settings)
  Future<Map<AppPermissionType, AppPermissionResult>> checkAllStatuses(
    Map<AppPermissionType, AppPermissionResult> currentMap,
  ) async {
    final updated = Map<AppPermissionType, AppPermissionResult>.from(
      currentMap,
    );
    for (final step in PermissionStepConfig.steps) {
      final status = await checkPermissionStatus(step.type);
      // Nếu quyền đã được cấp hoặc bị từ chối vĩnh viễn trên OS, cập nhật ngay
      if (status == AppPermissionResult.granted ||
          status == AppPermissionResult.permanentlyDenied ||
          status == AppPermissionResult.restricted) {
        updated[step.type] = status;
      } else if (updated[step.type] == AppPermissionResult.granted &&
          status == AppPermissionResult.denied) {
        // Trường hợp người dùng vừa tắt quyền trong Settings
        updated[step.type] = AppPermissionResult.denied;
      }
    }
    return updated;
  }

  /// Gửi yêu cầu cấp quyền thực tế đến hệ điều hành Android / iOS
  /// - Kiểm tra trạng thái trước khi gửi request.
  /// - Không tự động gọi request() nếu đã bị từ chối vĩnh viễn (permanentlyDenied).
  Future<AppPermissionResult> requestDevicePermission(
    AppPermissionType type,
  ) async {
    if (!isNativePermissionSupported) {
      // Trên Windows/Web, thử dùng Geolocator cho Location nếu khả dụng
      if (type == AppPermissionType.location) {
        try {
          LocationPermission geoPerm = await Geolocator.checkPermission();
          if (geoPerm == LocationPermission.deniedForever) {
            return AppPermissionResult.permanentlyDenied;
          }
          geoPerm = await Geolocator.requestPermission();
          if (geoPerm == LocationPermission.always ||
              geoPerm == LocationPermission.whileInUse) {
            return AppPermissionResult.granted;
          }
          if (geoPerm == LocationPermission.deniedForever) {
            return AppPermissionResult.permanentlyDenied;
          }
          return AppPermissionResult.denied;
        } catch (_) {
          return AppPermissionResult.denied;
        }
      }
      return AppPermissionResult.denied;
    }

    final permission = _getSystemPermission(type);

    // Bước 1: Kiểm tra trạng thái hiện tại trước khi gửi request
    final currentStatus = await permission.status;

    if (currentStatus.isGranted ||
        currentStatus.isLimited ||
        currentStatus.isProvisional) {
      return AppPermissionResult.granted;
    }

    if (currentStatus.isRestricted) {
      return AppPermissionResult.restricted;
    }

    // Không tự động gửi lại request nếu người dùng đã từ chối vĩnh viễn trước đó
    if (currentStatus.isPermanentlyDenied) {
      return AppPermissionResult.permanentlyDenied;
    }

    // Bước 2: Gửi request thực tế để hệ điều hành Android/iOS hiển thị hộp thoại hệ thống
    final newStatus = await permission.request();
    return mapStatus(newStatus);
  }

  /// Mở màn hình Cài đặt ứng dụng (App Settings) của hệ điều hành
  Future<bool> openSystemAppSettings() async {
    if (!isNativePermissionSupported) {
      return false;
    }
    return await openAppSettings();
  }

  /// Lấy tọa độ GPS thực tế sau khi quyền Location được cấp
  Future<Position?> getCurrentLocationIfGranted() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
      }
    } catch (_) {}
    return null;
  }

  Permission _getSystemPermission(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.location:
        return Permission.locationWhenInUse;
      case AppPermissionType.notification:
        return Permission.notification;
      case AppPermissionType.camera:
        return Permission.camera;
    }
  }

  /// Nhãn hiển thị trạng thái quyền bằng tiếng Việt rõ ràng
  static String getStatusLabel(AppPermissionResult result) {
    switch (result) {
      case AppPermissionResult.notRequested:
        return 'Chưa yêu cầu (Not Requested)';
      case AppPermissionResult.granted:
        return 'Đã cấp quyền (Granted)';
      case AppPermissionResult.denied:
        return 'Từ chối (Denied)';
      case AppPermissionResult.permanentlyDenied:
        return 'Từ chối vĩnh viễn (Permanently Denied)';
      case AppPermissionResult.restricted:
        return 'Bị giới hạn bởi hệ thống (Restricted)';
      case AppPermissionResult.skipped:
        return 'Đã bỏ qua (Skipped for now)';
    }
  }
}
