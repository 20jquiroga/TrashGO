import 'package:flutter_test/flutter_test.dart';
import 'package:trashgo/main.dart';

void main() {
  testWidgets('TrashGo smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TrashGoApp());
  });
}
