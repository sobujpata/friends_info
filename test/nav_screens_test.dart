// Widget tests for the new Instruction and About Owner pages.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Entry_43/screens/about_screen.dart';
import 'package:Entry_43/screens/instruction_screen.dart';

void main() {
  testWidgets('Instruction screen renders all steps', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InstructionScreen())),
    );

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Add a friend'), findsWidgets);
    expect(find.text('Search & favorites'), findsWidgets);

    // The remaining steps are below the fold in the lazy ListView.
    await tester.scrollUntilVisible(find.text('Call & WhatsApp'), 200);
    expect(find.text('Call & WhatsApp'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Edit or delete'), 200);
    expect(find.text('Edit or delete'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Backup & restore'), 200);
    expect(find.text('Backup & restore'), findsOneWidget);
  });

  testWidgets('About screen renders app and owner info',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AboutScreen())),
    );

    expect(find.text('Friends Info'), findsWidgets);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('About the owner'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('MD SALIM REZA'), findsOneWidget);
    expect(find.text('01739871705'), findsOneWidget);
  });
}