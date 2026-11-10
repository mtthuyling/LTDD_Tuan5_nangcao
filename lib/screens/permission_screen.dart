import 'package:flutter/material.dart';
import '../models/permission_item.dart';
import '../services/permission_service.dart';
import '../widgets/permission_dialog.dart';
import '../widgets/smartphone_frame.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Màn hình chính điều phối luồng xin cấp 3 quyền (Location -> Notification -> Camera)
/// với nền là LoginScreen phủ lớp tối và hiển thị PermissionDialog ở chính giữa.
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();

  int _currentStepIndex = 0;
  bool _isFlowCompleted = false;
  bool _isRequesting = false;

  /// Lưu trạng thái thực tế của từng quyền
  Map<AppPermissionType, AppPermissionResult> _permissionResults = {
    AppPermissionType.location: AppPermissionResult.notRequested,
    AppPermissionType.notification: AppPermissionResult.notRequested,
    AppPermissionType.camera: AppPermissionResult.notRequested,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshSystemPermissionStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Khi người dùng quay lại ứng dụng từ màn hình Settings của hệ điều hành,
  /// tự động kiểm tra lại trạng thái quyền thực tế.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSystemPermissionStatuses();
    }
  }

  Future<void> _refreshSystemPermissionStatuses() async {
    final updated = await _permissionService.checkAllStatuses(
      _permissionResults,
    );
    if (!mounted) return;
    setState(() {
      _permissionResults = updated;
    });
  }

  /// Xử lý khi người dùng nhấn nút chính ("Allow" hoặc "Turn on")
  Future<void> _handlePrimaryButtonPressed() async {
    if (_isRequesting) return;

    final currentConfig = PermissionStepConfig.steps[_currentStepIndex];

    // Kiểm tra trạng thái hiện tại trước khi gửi request
    final preCheckStatus = await _permissionService.checkPermissionStatus(
      currentConfig.type,
    );

    // Nếu người dùng đã từ chối vĩnh viễn trước đó, không tự động gửi request lại
    // mà hiển thị hướng dẫn mở Settings
    if (preCheckStatus == AppPermissionResult.permanentlyDenied) {
      if (!mounted) return;
      setState(() {
        _permissionResults[currentConfig.type] =
            AppPermissionResult.permanentlyDenied;
      });
      _showFeedbackSnackBar(
        'Quyền ${currentConfig.title} đã bị từ chối vĩnh viễn. Hãy nhấn "Mở Cài đặt" để cấp quyền.',
        isWarning: true,
      );
      return;
    }

    setState(() {
      _isRequesting = true;
    });

    // Gửi yêu cầu cấp quyền thực tế đến hệ điều hành Android / iOS
    final result = await _permissionService.requestDevicePermission(
      currentConfig.type,
    );

    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _permissionResults[currentConfig.type] = result;
    });

    if (result == AppPermissionResult.granted) {
      _showFeedbackSnackBar(
        'Đã cấp quyền ${currentConfig.title} (Granted).',
        isWarning: false,
      );
      _advanceToNextStep();
    } else if (result == AppPermissionResult.permanentlyDenied) {
      _showFeedbackSnackBar(
        'Quyền ${currentConfig.title} bị từ chối vĩnh viễn. Bạn có thể mở Settings hoặc nhấn Skip for now.',
        isWarning: true,
      );
    } else {
      _showFeedbackSnackBar(
        'Người dùng đã từ chối quyền ${currentConfig.title} (Denied). Đang chuyển sang bước tiếp theo...',
        isWarning: true,
      );
      _advanceToNextStep();
    }
  }

  /// Xử lý khi người dùng nhấn nút phụ ("Skip for now")
  void _handleSkipPressed() {
    if (_isRequesting) return;

    final currentConfig = PermissionStepConfig.steps[_currentStepIndex];

    setState(() {
      // Nếu quyền chưa được cấp trước đó thì đánh dấu là Skipped
      if (_permissionResults[currentConfig.type] !=
          AppPermissionResult.granted) {
        _permissionResults[currentConfig.type] = AppPermissionResult.skipped;
      }
    });

    _advanceToNextStep();
  }

  /// Chuyển sang màn hình quyền tiếp theo hoặc màn hình hoàn tất (HomeScreen)
  void _advanceToNextStep() {
    if (_currentStepIndex < PermissionStepConfig.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      setState(() {
        _isFlowCompleted = true;
      });
    }
  }

  /// Mở màn hình Cài đặt hệ thống khi quyền bị từ chối vĩnh viễn
  Future<void> _handleOpenSettings() async {
    final opened = await _permissionService.openSystemAppSettings();
    if (!mounted) return;
    if (!opened) {
      _showFeedbackSnackBar(
        'Chỉ có thể mở App Settings trực tiếp trên thiết bị Android / iOS.',
        isWarning: true,
      );
    }
  }

  /// Cho phép kiểm thử lại từng bước cụ thể từ màn hình hoàn tất
  void _jumpToStep(int stepIndex) {
    setState(() {
      _currentStepIndex = stepIndex;
      _isFlowCompleted = false;
    });
  }

  /// Đặt lại toàn bộ luồng về bước 1 (Location Permission)
  void _restartFlow() {
    setState(() {
      _currentStepIndex = 0;
      _isFlowCompleted = false;
    });
    _refreshSystemPermissionStatuses();
  }

  void _showFeedbackSnackBar(String message, {required bool isWarning}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isWarning
            ? const Color(0xFFE65100)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = PermissionStepConfig.steps[_currentStepIndex];
    final currentStatus =
        _permissionResults[currentConfig.type] ??
        AppPermissionResult.notRequested;

    return SmartphoneFrame(
      statusBarIconColor: _isFlowCompleted
          ? const Color(0xFF1F2937)
          : Colors.white,
      child: _isFlowCompleted
          ? HomeScreen(
              permissionResults: _permissionResults,
              permissionService: _permissionService,
              onRestartFlow: _restartFlow,
              onReviewStep: _jumpToStep,
              onRefreshStatuses: _refreshSystemPermissionStatuses,
            )
          : Stack(
              children: [
                // 1. Background là màn hình đăng nhập (Login Screen)
                const Positioned.fill(
                  child: LoginScreen(),
                ),

                // 2. Lớp phủ màu đen trong suốt tạo hiệu ứng tối khi hiển thị hộp thoại
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.56),
                  ),
                ),

                // 3. Thanh điều hướng nhanh phía trên để giảng viên/người dùng dễ kiểm thử từng màn hình
                Positioned(
                  top: 46,
                  left: 16,
                  right: 16,
                  child: _buildStepSelectorBar(),
                ),

                // 4. Hộp thoại xin cấp quyền (Permission Dialog) ở chính giữa màn hình
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.94,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: PermissionDialog(
                        key: ValueKey<AppPermissionType>(currentConfig.type),
                        stepConfig: currentConfig,
                        currentStepIndex: _currentStepIndex,
                        totalSteps: PermissionStepConfig.steps.length,
                        currentStatus: currentStatus,
                        isRequesting: _isRequesting,
                        onPrimaryPressed: _handlePrimaryButtonPressed,
                        onSecondaryPressed: _handleSkipPressed,
                        onOpenSettingsPressed: _handleOpenSettings,
                        onStepSelected: (index) {
                          setState(() {
                            _currentStepIndex = index;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Thanh chuyển nhanh giữa 3 màn hình (1. Location | 2. Notification | 3. Camera)
  Widget _buildStepSelectorBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: List.generate(PermissionStepConfig.steps.length, (index) {
          final step = PermissionStepConfig.steps[index];
          final bool isSelected = index == _currentStepIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isRequesting) {
                  setState(() {
                    _currentStepIndex = index;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF5722)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${index + 1}. ${step.title}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
