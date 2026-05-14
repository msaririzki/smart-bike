import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_user/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login screen when no session exists', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SmartBikeUserApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump();

    expect(find.text('Ride Smooth. Track Smart.'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
