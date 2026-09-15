// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:Entry_43/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FriendsApp());

    // Basic check that the app builds without crashing.
    // Since it starts with a loading indicator or login screen,
    // we just check for the presence of the MaterialApp/FriendsApp.
    expect(find.byType(FriendsApp), findsOneWidget);
  });
}
