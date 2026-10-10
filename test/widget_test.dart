import 'package:flutter_test/flutter_test.dart';
import 'package:sprintly/main.dart';

void main() {
  testWidgets('Sprintly application loads', (tester) async {
    await tester.pumpWidget(const SprintlyApp());

    expect(find.text('Welcome to Sprintly'), findsOneWidget);
  });
}