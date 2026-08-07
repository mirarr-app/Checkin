import 'package:flutter_test/flutter_test.dart';
import 'package:Checkin/main.dart';

void main() {
  testWidgets('App initializes test', (WidgetTester tester) async {
    expect(const Checkin(), isNotNull);
  });
}
