import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/permission_item.dart';
import '../services/permission_service.dart';
import '../widgets/permission_button.dart';

/// Màn hình hoàn tất (Home Screen) sau khi thực hiện xong 3 bước xin cấp quyền.
/// Cho phép xem trạng thái từng quyền, kiểm tra GPS / Camera thực tế hoặc mở lại từng bước.
class HomeScreen extends StatefulWidget {
  final Map<AppPermissionType, AppPermissionResult> permissionResults;
  final PermissionService permissionService;
  final VoidCallback onRestartFlow;
  final ValueChanged<int> onReviewStep;
  final Future<void> Function() onRefreshStatuses;

  const HomeScreen({
    super.key,
    required this.permissionResults,
    required this.permissionService,
    required this.onRestartFlow,
    required this.onReviewStep,
    required this.onRefreshStatuses,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _cameraInfoMessage;
  CameraController? _cameraController;
  bool _isCameraPreviewOpen = false;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Thử lấy tọa độ GPS thực tế nếu quyền Location đã được cấp
  Future<void> _fetchGpsCoordinates() async {
    setState(() {
      _isLoadingLocation = true;
    });
    final pos = await widget.permissionService.getCurrentLocationIfGranted();
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = false;
      _currentPosition = pos;
    });
  }

  /// Thử khởi tạo Camera thực tế nếu quyền Camera đã được cấp
  Future<void> _testDeviceCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraInfoMessage =
              'Đã cấp quyền Camera, nhưng thiết bị/giả lập không có phần cứng Camera khả dụng.';
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController?.dispose();
        _cameraController = controller;
        _isCameraPreviewOpen = true;
        _cameraInfoMessage = 'Đang hiển thị Camera: ${cameras.first.name}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraInfoMessage = 'Không thể khởi tạo Camera: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int grantedCount = widget.permissionResults.values
        .where((e) => e == AppPermissionResult.granted)
        .length;

    return Container(
      color: const Color(0xFFF9FAFB),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header trạng thái tổng hợp
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8008), Color(0xFFFF3D00)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trạng thái quyền thiết bị',
                          style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Đã cấp $grantedCount / 3 quyền truy cập',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kiểm tra lại trạng thái OS',
                    onPressed: widget.onRefreshStatuses,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFFFF5722),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Danh sách chi tiết 3 quyền và kết quả thực tế
              Expanded(
                child: ListView(
                  children: [
                    ...List.generate(PermissionStepConfig.steps.length, (idx) {
                      final step = PermissionStepConfig.steps[idx];
                      final status =
                          widget.permissionResults[step.type] ??
                          AppPermissionResult.notRequested;
                      return _buildPermissionSummaryCard(step, idx, status);
                    }),

                    // Hiển thị tọa độ GPS thực tế nếu người dùng kiểm tra
                    if (_currentPosition != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.my_location_rounded,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tọa độ GPS thực tế:\nLat: ${_currentPosition!.latitude.toStringAsFixed(5)}, '
                                'Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Hiển thị Camera Preview thực tế nếu người dùng mở
                    if (_cameraInfoMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cameraInfoMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            if (_isCameraPreviewOpen &&
                                _cameraController != null &&
                                _cameraController!.value.isInitialized) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 140,
                                  width: double.infinity,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              PermissionPrimaryButton(
                label: 'Xem lại luồng 3 màn hình từ đầu',
                icon: Icons.replay_rounded,
                onPressed: widget.onRestartFlow,
              ),
              const SizedBox(height: 8),
              PermissionSecondaryButton(
                label: 'Mở Cài đặt hệ thống (App Settings)',
                onPressed: () {
                  widget.permissionService.openSystemAppSettings();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionSummaryCard(
    PermissionStepConfig step,
    int stepIndex,
    AppPermissionResult status,
  ) {
    final bool isGranted = status == AppPermissionResult.granted;
    final bool isPermanentlyDenied =
        status == AppPermissionResult.permanentlyDenied;

    Color statusColor;
    if (isGranted) {
      statusColor = const Color(0xFF2E7D32);
    } else if (isPermanentlyDenied) {
      statusColor = const Color(0xFFC62828);
    } else if (status == AppPermissionResult.denied) {
      statusColor = const Color(0xFFEF6C00);
    } else {
      statusColor = const Color(0xFF6B7280);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? const Color(0xFFA5D6A7)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: step.accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, color: step.accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stepIndex + 1}. ${step.title} Permission',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PermissionService.getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => widget.onReviewStep(stepIndex),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5722),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(50, 32),
                ),
                child: const Text(
                  'Mở Dialog',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          // Nếu Location đã cấp quyền, hiển thị nút lấy GPS thực tế
          if (step.type == AppPermissionType.location && isGranted) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _fetchGpsCoordinates,
                icon: const Icon(Icons.gps_fixed_rounded, size: 15),
                label: Text(
                  _isLoadingLocation
                      ? 'Đang lấy tọa độ GPS...'
                      : 'Lấy vị trí GPS thực tế (Geolocator)',
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            ),
          ],

          // Nếu Camera đã cấp quyền, hiển thị nút mở Camera thực tế
          if (step.type == AppPermissionType.camera && isGranted) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: OutlinedButton.icon(
                onPressed: _testDeviceCamera,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
                label: const Text(
                  'Kiểm tra Camera thực tế',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
            ),
          ],

          // Nếu bị từ chối vĩnh viễn, hiển thị nút mở Settings ngay tại thẻ
          if (isPermanentlyDenied) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: OutlinedButton.icon(
                onPressed: () =>
                    widget.permissionService.openSystemAppSettings(),
                icon: const Icon(Icons.settings_rounded, size: 15),
                label: const Text(
                  'Mở Settings để cấp quyền',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
