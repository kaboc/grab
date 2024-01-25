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

  group('grabAt', () {
    testWidgets(
      'With non-ValueListenable, listenable itself is passed to selector',
      (tester) async {
        Object? selectorValue;
        await tester.pumpWidget(
          Grab(
            child: TestStatelessWidget(
              funcCalledInBuild: (context) {
                changeNotifier.grabAt(context, (n) => selectorValue = n);
              },
            ),
          ),
        );
        expect(selectorValue, same(changeNotifier));
      },
    );

    testWidgets(
      'With ValueListenable, its value is passed to selector',
      (tester) async {
        valueNotifier.updateIntValue(10);

        Object? selectorValue;
        await tester.pumpWidget(
          Grab(
            child: TestStatelessWidget(
              funcCalledInBuild: (context) {
                valueNotifier.grabAt(context, (s) => selectorValue = s);
              },
            ),
          ),
        );
        expect(selectorValue, same(valueNotifier.value));
      },
    );

    testWidgets('Returns selected value', (tester) async {
      valueNotifier.updateIntValue(10);

      int? value;
      await tester.pumpWidget(
        Grab(
          child: TestStatelessWidget(
            funcCalledInBuild: (context) {
              value = valueNotifier.grabAt(context, (s) => s.intValue);
            },
          ),
        ),
      );
      expect(value, 10);
    });

    testWidgets(
      'Rebuilds widget and returns latest value when listenable is updated',
      (tester) async {
        valueNotifier.updateIntValue(10);

        int? value;
        await tester.pumpWidget(
          Grab(
            child: TestStatelessWidget(
              funcCalledInBuild: (context) {
                value = valueNotifier.grabAt(context, (s) => s.intValue);
              },
            ),
          ),
        );

        valueNotifier.updateIntValue(20);
        await tester.pump();
        expect(value, 20);
      },
    );

    testWidgets(
      'Rebuilds widget only when listenable is non-ValueListenable and '
      'property chosen by selector is updated',
      (tester) async {
        int? value1;
        String? value2;
        var buildCount1 = 0;
        var buildCount2 = 0;

        await tester.pumpWidget(
          Grab(
            child: Column(
              children: [
                TestStatelessWidget(
                  funcCalledInBuild: (context) {
                    value1 = changeNotifier.grabAt(
                      context,
                      (TestChangeNotifier n) => n.intValue,
                    );
                    buildCount1++;
                  },
                ),
                TestStatelessWidget(
                  funcCalledInBuild: (context) {
                    value2 = changeNotifier.grabAt(
                      context,
                      (TestChangeNotifier n) => n.stringValue,
                    );
                    buildCount2++;
                  },
                ),
              ],
            ),
          ),
        );

        changeNotifier.updateIntValue(10);
        await tester.pump();
        expect(value1, 10);
        expect(value2, '');
        expect(buildCount1, 2);
        expect(buildCount2, 1);

        changeNotifier.updateStringValue('abc');
        await tester.pump();
        expect(value1, 10);
        expect(value2, 'abc');
        expect(buildCount1, 2);
        expect(buildCount2, 2);

        changeNotifier.updateIntValue(20);
        await tester.pump();
        expect(value1, 20);
        expect(value2, 'abc');
        expect(buildCount1, 3);
        expect(buildCount2, 2);
      },
    );

    testWidgets(
      'Rebuilds widget only when listenable is ValueListenable and '
      'property chosen by selector is updated',
      (tester) async {
        int? value1;
        String? value2;
        var buildCount1 = 0;
        var buildCount2 = 0;

        await tester.pumpWidget(
          Grab(
            child: Column(
              children: [
                TestStatelessWidget(
                  funcCalledInBuild: (context) {
                    value1 = valueNotifier.grabAt(context, (s) => s.intValue);
                    buildCount1++;
                  },
                ),
                TestStatelessWidget(
                  funcCalledInBuild: (context) {
                    value2 =
                        valueNotifier.grabAt(context, (s) => s.stringValue);
                    buildCount2++;
                  },
                ),
              ],
            ),
          ),
        );

        valueNotifier.updateIntValue(10);
        await tester.pump();
        expect(value1, 10);
        expect(value2, '');
        expect(buildCount1, 2);
        expect(buildCount2, 1);

        valueNotifier.updateStringValue('abc');
        await tester.pump();
        expect(value1, 10);
        expect(value2, 'abc');
        expect(buildCount1, 2);
        expect(buildCount2, 2);

        valueNotifier.updateIntValue(20);
        await tester.pump();
        expect(value1, 20);
        expect(value2, 'abc');
        expect(buildCount1, 3);
        expect(buildCount2, 2);
      },
    );

    testWidgets(
      'Rebuilds widget whenever listenable notifies '
      'if listenable itself is returned from selector',
      (tester) async {
        int? value1;
        String? value2;
        var buildCount1 = 0;
        var buildCount2 = 0;

        await tester.pumpWidget(
          Grab(
            child: Column(
              children: [
                TestStatelessWidget(
                  funcCalledInBuild: (context) {
                    final notifier = changeNotifier.grabAt(
                      context,
                      (TestChangeNotifier n) => n,
                    );
                    value1 = notifier.intValue;
                    buildCount1++;
                  },
                ),
                TestStatelessWidget(
                  funcCalledInBuild: (context) {
                    final notifier = changeNotifier.grabAt(
                      context,
                      (TestChangeNotifier n) => n,
                    );
                    value2 = notifier.stringValue;
                    buildCount2++;
                  },
                ),
              ],
            ),
          ),
        );

        changeNotifier.updateIntValue(10);
        await tester.pump();
        expect(value1, 10);
        expect(value2, '');
        expect(buildCount1, 2);
        expect(buildCount2, 2);

        changeNotifier.updateStringValue('abc');
        await tester.pump();
        expect(value1, 10);
        expect(value2, 'abc');
        expect(buildCount1, 3);
        expect(buildCount2, 3);
      },
    );

    testWidgets(
      'Returns new value on rebuild by causes other than listenable update too',
      (tester) async {
        valueNotifier.updateIntValue(10);
        var multiplier = 2;

        int? value;
        await tester.pumpWidget(
          Grab(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: StatefulBuilder(
                builder: (_, setState) => Column(
                  children: [
                    TestStatelessWidget(
                      funcCalledInBuild: (context) {
                        value = valueNotifier.grabAt(
                          context,
                          (s) => s.intValue * multiplier,
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => multiplier = 3),
                      child: const Text('test'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(value, 20);

        final buttonFinder = find.byType(ElevatedButton).first;
        await tester.tap(buttonFinder);
        await tester.pump();
        expect(value, 30);
      },
    );
  });
}
