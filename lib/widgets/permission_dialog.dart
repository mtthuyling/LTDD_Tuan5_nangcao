import 'package:flutter/material.dart';
import '../models/permission_item.dart';
import '../services/permission_service.dart';
import 'permission_button.dart';

/// Hộp thoại xin cấp quyền (Permission Dialog) màu trắng, bo góc 24px,
/// hiển thị biểu tượng minh họa lớn, tiêu đề, mô tả và 2 nút hành động.
class PermissionDialog extends StatelessWidget {
  final PermissionStepConfig stepConfig;
  final int currentStepIndex;
  final int totalSteps;
  final AppPermissionResult currentStatus;
  final bool isRequesting;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  final VoidCallback onOpenSettingsPressed;
  final ValueChanged<int>? onStepSelected;

  const PermissionDialog({
    super.key,
    required this.stepConfig,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.currentStatus,
    required this.isRequesting,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    required this.onOpenSettingsPressed,
    this.onStepSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPermanentlyDenied =
        currentStatus == AppPermissionResult.permanentlyDenied;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh chấm tròn chuyển đổi / hiển thị tiến trình 3 màn hình (1/3, 2/3, 3/3)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final bool isActive = index == currentStepIndex;
              return GestureDetector(
                onTap: onStepSelected != null
                    ? () => onStepSelected!(index)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFF5722)
                        : const Color(0xFFFFCCBC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),

          // Biểu tượng minh họa lớn đặt chính giữa phía trên
          _buildIllustrationBadge(),
          const SizedBox(height: 22),

          // Tiêu đề in đậm, màu đen (Location / Notification / Camera)
          Text(
            stepConfig.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),

          // Nội dung mô tả màu xám, căn giữa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              stepConfig.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // Hiển thị trạng thái quyền hiện tại nếu đã có tương tác
          if (currentStatus != AppPermissionResult.notRequested) ...[
            const SizedBox(height: 14),
            _buildStatusBadge(),
          ],

          // Hướng dẫn mở Settings khi người dùng đã từ chối vĩnh viễn (Permanently Denied)
          if (isPermanentlyDenied) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Quyền này đã bị từ chối vĩnh viễn. Vui lòng mở Cài đặt hệ thống (App Settings) để cấp quyền thủ công.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE65100),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: TextButton.icon(
                      onPressed: onOpenSettingsPressed,
                      icon: const Icon(
                        Icons.settings_rounded,
                        size: 16,
                        color: Color(0xFFE65100),
                      ),
                      label: const Text(
                        'Mở Cài đặt (Open Settings)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Button chính: "Allow" hoặc "Turn on" (Gradient cam – đỏ)
          PermissionPrimaryButton(
            label: stepConfig.primaryButtonText,
            isLoading: isRequesting,
            onPressed: onPrimaryPressed,
          ),
          const SizedBox(height: 12),

          // Button phụ: "Skip for now" (Nền trắng, viền cam, chữ cam)
          PermissionSecondaryButton(
            label: stepConfig.secondaryButtonText,
            onPressed: isRequesting ? null : onSecondaryPressed,
          ),
        ],
      ),
    );
  }

  /// Minh họa biểu tượng lớn ở trung tâm phía trên hộp thoại
  Widget _buildIllustrationBadge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Vòng tròn hào quang ngoài cùng
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stepConfig.accentColor.withValues(alpha: 0.08),
          ),
        ),
        // Vòng tròn trung gian
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stepConfig.accentColor.withValues(alpha: 0.16),
          ),
        ),
        // Các chấm tròn trang trí xung quanh giống thiết kế mẫu
        Positioned(
          top: 10,
          right: 14,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF8A65),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 14,
          left: 12,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFFAB40),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Vòng tròn chính chứa Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF8008),
                Color(0xFFFF3D00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: stepConfig.accentColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            stepConfig.icon,
            size: 32,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    IconData iconData;

    switch (currentStatus) {
      case AppPermissionResult.granted:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        iconData = Icons.check_circle_rounded;
        break;
      case AppPermissionResult.permanentlyDenied:
      case AppPermissionResult.restricted:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        iconData = Icons.error_rounded;
        break;
      case AppPermissionResult.denied:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        iconData = Icons.warning_amber_rounded;
        break;
      case AppPermissionResult.skipped:
      case AppPermissionResult.notRequested:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF4B5563);
        iconData = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 15, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              PermissionService.getStatusLabel(currentStatus),
              style: TextStyle(
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
