import 'package:flutter_test/flutter_test.dart';
import 'package:vocablens/main.dart';

void main() {
  testWidgets('VocabLensApp smoke test', (WidgetTester tester) async {
    // Build app widget
    await tester.pumpWidget(const VocabLensApp());

    // Verify app starts with VocabLens title in tree
    expect(find.byType(VocabLensApp), findsOneWidget);
  });
}
