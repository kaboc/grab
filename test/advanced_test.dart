import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grab/grab.dart';

import 'common/notifiers.dart';
import 'common/widgets.dart';

void main() {
  late TestChangeNotifier changeNotifier;
  late TestValueNotifier valueNotifier;

  setUp(() {
    changeNotifier = TestChangeNotifier();
    valueNotifier = TestValueNotifier();
  });
  tearDown(() {
    changeNotifier.dispose();
    valueNotifier.dispose();
  });

  testWidgets(
    'The furthest Grab is used without error if there is more than one',
    (tester) async {
      BuildContext? targetContext;
      int? value;

      final grab2 = Grab(
        child: TestStatelessWidget(
          funcCalledInBuild: (context) {
            targetContext = context;
            value = valueNotifier.grabAt(context, (n) => n.intValue);
          },
        ),
      );
      final grab1 = Grab(child: grab2);
      await tester.pumpWidget(grab1);

      expect(Grab.stateOf(targetContext!)!.widget, same(grab1));

      valueNotifier.updateIntValue(10);
      await tester.pump();
      expect(value, 10);
    },
  );

  testWidgets(
    'Only the widget associated with the provided BuildContext is rebuilt',
    (tester) async {
      var parentBuildCount = 0;
      var targetBuildContext = 0;

      await tester.pumpWidget(
        Grab(
          child: TestStatelessWidget(
            funcCalledInBuild: (context) => parentBuildCount++,
            child: Builder(
              builder: (context) {
                targetBuildContext++;
                valueNotifier.grab(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(parentBuildCount, 1);
      expect(targetBuildContext, 1);

      valueNotifier.updateStringValue('abc');
      await tester.pump();
      expect(parentBuildCount, 1);
      expect(targetBuildContext, 2);
    },
  );

  testWidgets(
    'Updating multiple Listenables in a frame triggers a single rebuild',
    (tester) async {
      changeNotifier.updateIntValue(10);
      valueNotifier.updateIntValue(20);

      int? value1;
      int? value2;
      var buildCount = 0;

      await tester.pumpWidget(
        Grab(
          child: TestStatelessWidget(
            funcCalledInBuild: (context) {
              value1 = changeNotifier.grabAt(
                context,
                (TestChangeNotifier n) => n.intValue,
              );
              value2 = valueNotifier.grabAt(context, (s) => s.intValue);
              buildCount++;
            },
          ),
        ),
      );

      expect(value1, 10);
      expect(value2, 20);
      expect(buildCount, 1);

      changeNotifier.updateIntValue(11);
      valueNotifier.updateIntValue(12);
      await tester.pump();
      expect(value1, 11);
      expect(value2, 12);
      expect(buildCount, 2);
    },
  );

  testWidgets(
    "Switching order of grab method calls doesn't affect its behaviour",
    (tester) async {
      valueNotifier
        ..updateIntValue(10)
        ..updateStringValue('abc');

      final swapNotifier = ValueNotifier(false);
      addTearDown(swapNotifier.dispose);

      int? value1;
      String? value2;
      bool? isSwapped;
      var buildCount = 0;

      await tester.pumpWidget(
        Grab(
          child: ValueListenableBuilder<bool>(
            valueListenable: swapNotifier,
            builder: (_, swapped, __) => TestStatelessWidget(
              funcCalledInBuild: swapped
                  ? (context) {
                      value2 =
                          valueNotifier.grabAt(context, (s) => s.stringValue);
                      value1 = valueNotifier.grabAt(context, (s) => s.intValue);
                      isSwapped = true;
                      buildCount++;
                    }
                  : (context) {
                      value1 = valueNotifier.grabAt(context, (s) => s.intValue);
                      value2 =
                          valueNotifier.grabAt(context, (s) => s.stringValue);
                      isSwapped = false;
                      buildCount++;
                    },
            ),
          ),
        ),
      );

      expect(value1, 10);
      expect(value2, 'abc');
      expect(isSwapped, isFalse);
      expect(buildCount, 1);

      valueNotifier.updateIntValue(20);
      swapNotifier.value = true;
      await tester.pump();

      expect(value1, 20);
      expect(value2, 'abc');
      expect(isSwapped, isTrue);
      expect(buildCount, 2);

      valueNotifier.updateStringValue('def');
      swapNotifier.value = false;
      await tester.pump();

      expect(value1, 20);
      expect(value2, 'def');
      expect(isSwapped, isFalse);
      expect(buildCount, 3);
    },
  );

  testWidgets(
    'No error is thrown when notifier notifies after a widget that was '
    'listening to the notifier is removed',
    (tester) async {
      var visible = true;
      int? value;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Grab(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    TestStatelessWidget(
                      funcCalledInBuild: (context) {
                        value =
                            valueNotifier.grabAt(context, (n) => n.intValue);
                      },
                    ),
                    if (visible)
                      TestStatelessWidget(
                        funcCalledInBuild: (context) {
                          valueNotifier.grab(context);
                        },
                      ),
                    ElevatedButton(
                      onPressed: () => setState(() => visible = !visible),
                      child: const Text('Button'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(TestStatelessWidget), findsNWidgets(2));

      final buttonFinder = find.byType(ElevatedButton).first;
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.byType(TestStatelessWidget), findsOneWidget);

      valueNotifier.updateIntValue(10);
      await tester.pump();

      expect(find.byType(TestStatelessWidget), findsOneWidget);
      expect(value, 10);
    },
  );
}
