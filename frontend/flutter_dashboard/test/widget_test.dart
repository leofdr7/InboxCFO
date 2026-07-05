// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:inboxcfo_dashboard/main.dart';

void main() {
  testWidgets('shows Supabase setup screen when not configured', (tester) async {
    await tester.pumpWidget(const InboxCfoApp());
    await tester.pumpAndSettle();

    expect(find.text('Supabase no está configurado'), findsOneWidget);
    expect(find.textContaining('--dart-define=SUPABASE_URL'), findsOneWidget);
  });
}
