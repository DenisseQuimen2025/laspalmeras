import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// 👇 importa tu app desde el package; confirma que en pubspec.yaml el name sea "app_eval2"
import 'package:app_eval2/main.dart';

void main() {
  testWidgets('smoke test: app builds', (WidgetTester tester) async {
    // Construye tu app
    await tester.pumpWidget(const LasPalmerasApp());

    // Verifica que la pantalla de login aparece
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Inicio de sesión'), findsOneWidget);
  });
}

