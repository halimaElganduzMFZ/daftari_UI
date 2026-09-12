import 'package:employee_affairs/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login screen loads', (tester) async {
    await tester.pumpWidget(const DaftariApp());
    expect(find.textContaining('موظف'), findsWidgets);
  });
}
