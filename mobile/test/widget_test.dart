import 'package:flutter_test/flutter_test.dart';
import 'package:sportsync/app.dart';

void main() {
  testWidgets('App initializes test', (WidgetTester tester) async {
    await tester.pumpWidget(const SportSyncApp());
    expect(find.byType(SportSyncApp), findsOneWidget);
  });
}
