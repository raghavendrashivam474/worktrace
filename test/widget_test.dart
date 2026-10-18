import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/app/app.dart';

void main() {
  testWidgets('WorktraceApp launches and shows branded shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorktraceApp()));

    // Verify brand identity
    expect(find.text('Worktrace'), findsWidgets);
    expect(find.text('Keep your work traceable'), findsOneWidget);

    // Verify feature placeholders
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Snippets'), findsOneWidget);

    // Verify "Soon" chips
    expect(find.text('Soon'), findsNWidgets(2));
  });
}
