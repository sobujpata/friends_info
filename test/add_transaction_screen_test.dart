import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Friends_info/screens/add_transaction_screen.dart';

void main() {
  testWidgets('Add Transaction form shows transaction controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AddTransactionScreen(ownerPersonnelNo: '12345')),
    );

    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('Transaction Type'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Tags (Optional)'), findsOneWidget);
  });

  testWidgets('Add Transaction validates required values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AddTransactionScreen(ownerPersonnelNo: '12345')),
    );

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Add Transaction'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add Transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
  });
}
