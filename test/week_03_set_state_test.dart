import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/learning/week_03/set_state_demo.dart';

void main() {
  testWidgets('setState adds and removes the same movie', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SetStateDemo()));
    expect(find.text('В списке: 0'), findsOneWidget);
    await tester.tap(find.text('Добавить'));
    await tester.pump();
    expect(find.text('В списке: 1'), findsOneWidget);
    await tester.tap(find.text('Удалить'));
    await tester.pump();
    expect(find.text('В списке: 0'), findsOneWidget);
  });
}
