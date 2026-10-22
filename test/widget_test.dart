import 'package:flutter_test/flutter_test.dart';
import 'package:paranormal_lens/main.dart';

void main() {
  testWidgets('ParanormalLens smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ParanormalLensApp());
    expect(find.byType(ParanormalLensApp), findsOneWidget);
  });
}
