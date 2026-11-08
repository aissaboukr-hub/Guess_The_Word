import 'package:flutter_test/flutter_test.dart';
import 'package:guess_the_word/main.dart';

void main() {
  testWidgets('Home screen displays game title', (tester) async {
    await tester.pumpWidget(const GuessTheWordApp());
    expect(find.text('GUESS THE WORD'), findsOneWidget);
    expect(find.text('Créer une salle Wi-Fi'), findsOneWidget);
  });
}
