import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/app.dart';

void main() {
  testWidgets('shows register page', (WidgetTester tester) async {
    await tester.pumpWidget(const TaFeitoApp());

    expect(find.text('Crie sua conta'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('CPF/CNPJ'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
  });

  testWidgets('validates required fields', (WidgetTester tester) async {
    await tester.pumpWidget(const TaFeitoApp());

    await tester.ensureVisible(find.text('Criar'));
    await tester.tap(find.text('Criar'));
    await tester.pump();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(find.text('Informe seu CPF ou CNPJ.'), findsOneWidget);
    expect(find.text('Informe seu email.'), findsOneWidget);
    expect(find.text('Informe uma senha.'), findsOneWidget);
  });

  testWidgets('navigates from register to login', (WidgetTester tester) async {
    await tester.pumpWidget(const TaFeitoApp());

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar na conta'), findsOneWidget);
    expect(find.text('Acessar'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
  });
}
