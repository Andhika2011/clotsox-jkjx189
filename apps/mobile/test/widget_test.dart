import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clotso_x/main.dart';

void main() {
  testWidgets('LicenseGate renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ClotsoApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
