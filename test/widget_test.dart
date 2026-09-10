import 'package:flutter_test/flutter_test.dart';

import 'package:blog_forum_assessment/main.dart';

void main() {
  testWidgets('missing Supabase config screen renders',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MissingSupabaseConfigApp());

    expect(find.text('Supabase config is missing'), findsOneWidget);
  });
}
