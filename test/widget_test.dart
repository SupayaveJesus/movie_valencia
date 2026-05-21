import 'package:flutter_test/flutter_test.dart';

import 'package:practico4_movies/main.dart';

void main() {
  testWidgets('renderiza la pantalla principal', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('The Movie Database'), findsOneWidget);
    expect(find.text('Buscar película'), findsOneWidget);
    expect(find.text('Historial de búsqueda'), findsOneWidget);
  });
}
