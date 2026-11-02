import 'package:flutter_test/flutter_test.dart';

import 'package:gestor_pessoal/main.dart';

void main() {
  testWidgets('Aplicativo inicia corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const GestorPessoalApp());

    expect(find.text('Olá! 👋'), findsOneWidget);
  });
}
