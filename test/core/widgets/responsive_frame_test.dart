import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/core/widgets/responsive_frame.dart';

void main() {
  Future<double> layoutWidthAt(WidgetTester tester, double screenWidth) async {
    tester.view.physicalSize = Size(screenWidth, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late double seen;
    await tester.pumpWidget(MaterialApp(
      home: ResponsiveFrame(
        child: Builder(builder: (context) {
          seen = MediaQuery.sizeOf(context).width;
          return const SizedBox.expand();
        }),
      ),
    ));
    return seen;
  }

  testWidgets('phones use the full width', (tester) async {
    expect(await layoutWidthAt(tester, 400), 400);
  });

  testWidgets('wide screens get a centred column the app sees as its width',
      (tester) async {
    expect(await layoutWidthAt(tester, 1400), ResponsiveFrame.maxWidth);
  });
}
