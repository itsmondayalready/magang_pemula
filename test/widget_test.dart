// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loginfirebase/screens/infrastruktur_screen.dart';
import 'package:loginfirebase/screens/pendidikan_screen.dart';

void main() {
  testWidgets('basic material smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Hello'))),
    );
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('InfrastrukturScreen builds and shows title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InfrastrukturScreen()));
    // AppBar title text
    expect(find.text('Infrastruktur Desa'), findsOneWidget);
    // Tab labels exist
    expect(find.text('Pendidikan'), findsOneWidget);
    expect(find.text('Kesehatan'), findsOneWidget);
    expect(find.text('Transportasi'), findsOneWidget);
    expect(find.text('Komunikasi'), findsOneWidget);
    expect(find.text('Sanitasi'), findsOneWidget);
  });

  testWidgets('PendidikanScreen builds and shows tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PendidikanScreen()));
    // AppBar title
    expect(find.text('Pendidikan'), findsOneWidget);
    // Tab labels
    expect(find.text('Negeri'), findsOneWidget);
    expect(find.text('Swasta'), findsOneWidget);
    expect(find.text('LB & Keagamaan'), findsOneWidget);
  });
}
