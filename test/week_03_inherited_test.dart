import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/learning/week_03/inherited_demo.dart';

void main() {
  testWidgets('InheritedWidget notifies its dependent after add and remove', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InheritedDemo()));
    expect(find.text('В списке: 0'), findsOneWidget);
    await tester.tap(find.text('Добавить'));
    await tester.pump();
    expect(find.text('В списке: 1'), findsOneWidget);
    await tester.tap(find.text('Удалить'));
    await tester.pump();
    expect(find.text('В списке: 0'), findsOneWidget);
  });
}
