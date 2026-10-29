import 'package:alarmx/camera_object_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('camera object picker counts and saves selections',
      (WidgetTester tester) async {
    List<String>? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.push<List<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraObjectSelectionScreen(),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('0 selected'), findsOneWidget);

    await tester.tap(find.text('Bottle'));
    await tester.tap(find.text('Shoes'));
    await tester.pump();

    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.text('Save Selected Objects'));
    await tester.pumpAndSettle();

    expect(saved, unorderedEquals(['Bottle', 'Shoes']));
  });

  testWidgets('saving with nothing selected is refused',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CameraObjectSelectionScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Selected Objects'));
    await tester.pump();

    expect(find.text('Please select at least one object.'), findsOneWidget);
  });
}
