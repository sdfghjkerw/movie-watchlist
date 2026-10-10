
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/main.dart';

void main() {
  testWidgets('App displays the home screen', (tester) async {
    await tester.pumpWidget(const MovieWatchlistApp());

    expect(find.text('movie watchlist'), findsOneWidget);
    expect(find.text('Выбрали для тебя'), findsOneWidget);
  });
}
