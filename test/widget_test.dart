import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinobi_world/app/shinobi_app.dart';

void main() {
  testWidgets('shows loading state while config initializes', (tester) async {
    await tester.pumpWidget(const ShinobiApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
