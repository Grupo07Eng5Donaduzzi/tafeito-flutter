import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/app.dart';
import 'package:tafeito_flutter/src/features/auth/data/datasources/auth_local_data_source.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      TaFeitoApp(authLocalDataSource: InMemoryAuthLocalDataSource()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows login page when there is no session', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Entrar na conta'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Acessar'), findsOneWidget);
  });

  testWidgets('validates required login fields', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Acessar'));
    await tester.pump();

    expect(find.text('Informe seu email.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('navigates from login to register', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.ensureVisible(find.text('Registre-se'));
    await tester.tap(find.text('Registre-se'));
    await tester.pumpAndSettle();

    expect(find.text('Crie sua conta'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('CPF/CNPJ'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
  });

  testWidgets('opens password recovery from login',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Esqueceu a senha?'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar senha'), findsOneWidget);
    expect(find.text('Email de cadastro'), findsOneWidget);
    expect(find.text('Enviar codigo'), findsOneWidget);
  });
}
