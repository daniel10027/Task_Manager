import 'package:flutter_test/flutter_test.dart';

/// Drains pending async work (Future chains, debounce timers, page-route
/// transitions) without using [WidgetTester.pumpAndSettle], which never
/// returns for widgets carrying an intentionally infinite/repeating
/// animation (e.g. the pulsing online-status dot).
Future<void> settle(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 100),
  int times = 10,
}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(step);
  }
}
