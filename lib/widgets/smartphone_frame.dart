import 'package:flutter/material.dart';

/// Khung Smartphone Android đặt chính giữa màn hình với tỷ lệ chuẩn,
/// bao gồm viền bezel, camera trước, Status Bar (giờ, sóng, Wi-Fi, pin) và thanh điều hướng đáy.
class SmartphoneFrame extends StatelessWidget {
  final Widget child;
  final Color statusBarIconColor;

  const SmartphoneFrame({
    super.key,
    required this.child,
    this.statusBarIconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB), // Nền trung tính xám nhạt bên ngoài
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Giữ nguyên tỷ lệ smartphone (9 : 19.5) và co giãn responsive theo cửa sổ
          final double availableHeight = constraints.maxHeight;
          final double availableWidth = constraints.maxWidth;

          final double verticalPadding = availableHeight > 760 ? 24.0 : 8.0;
          final double maxPhoneHeight = (availableHeight - verticalPadding * 2)
              .clamp(480.0, 860.0);
          const double targetAspectRatio = 9.0 / 19.5;
          double phoneHeight = maxPhoneHeight;
          double phoneWidth = phoneHeight * targetAspectRatio;

          if (phoneWidth > availableWidth - 24) {
            phoneWidth = (availableWidth - 24).clamp(280.0, 430.0);
            phoneHeight = phoneWidth / targetAspectRatio;
          }

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 390,
                height: 844,
                child: _buildPhoneBody(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneBody() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Nút cứng bên cạnh phải (Nút tăng/giảm âm lượng & nút nguồn)
        Positioned(
          right: 0,
          top: 170,
          child: Container(
            width: 4,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFF2D3139),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 245,
          child: Container(
            width: 4,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF2D3139),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
            ),
          ),
        ),
        // Thân vỏ điện thoại (Bezel)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            borderRadius: BorderRadius.circular(48),
            border: Border.all(
              color: const Color(0xFF3A3F4B),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // Vùng hiển thị màn hình bên trong smartphone
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // Nội dung chính của ứng dụng
                  Positioned.fill(
                    child: MediaQuery(
                      data: const MediaQueryData(
                        size: Size(364, 820),
                        padding: EdgeInsets.only(top: 44, bottom: 20),
                      ),
                      child: child,
                    ),
                  ),

                  // Status Bar Android phía trên (Giờ, Camera đục lỗ, Sóng, Wi-Fi, Pin)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _AndroidStatusBar(iconColor: statusBarIconColor),
                  ),

                  // Thanh cử chỉ điều hướng dưới đáy màn hình Android
                  Positioned(
                    bottom: 7,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 124,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Thanh trạng thái (Status Bar) bên trong màn hình Smartphone
class _AndroidStatusBar extends StatelessWidget {
  final Color iconColor;

  const _AndroidStatusBar({required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final String formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return IgnorePointer(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Hiển thị giờ
            Text(
              formattedTime,
              style: TextStyle(
                color: iconColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),

            // Cụm camera trước đục lỗ (Punch-hole camera) ở chính giữa
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF111318),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2B303C),
                  width: 1.5,
                ),
              ),
            ),

            // Biểu tượng sóng di động, Wi-Fi và Pin
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.signal_cellular_alt_rounded,
                  size: 16,
                  color: iconColor,
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.wifi_rounded,
                  size: 16,
                  color: iconColor,
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.battery_full_rounded,
                  size: 18,
                  color: iconColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
