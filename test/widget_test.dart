import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/main.dart';

void main() {
  testWidgets('Kiểm tra luồng chuyển đổi giữa 3 màn hình xin cấp quyền', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UthPermissionApp());

    // Màn hình 1: Location Permission
    expect(find.text('Location'), findsOneWidget);
    expect(
      find.text('Allow maps to access your location while you use the app?'),
      findsOneWidget,
    );
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);

    // Nhấn Skip for now để sang màn hình 2: Notification Permission
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('Notification'), findsOneWidget);
    expect(
      find.text('Please enable notifications to receive updates and reminders.'),
      findsOneWidget,
    );
    expect(find.text('Turn on'), findsOneWidget);

    // Nhấn Skip for now để sang màn hình 3: Camera Permission
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('Camera'), findsOneWidget);
    expect(
      find.text('We need access to your camera to scan QR codes.'),
      findsOneWidget,
    );
    expect(find.text('Turn on'), findsOneWidget);
  });
}
