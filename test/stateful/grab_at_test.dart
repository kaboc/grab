import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grab/grab.dart';

import '../common/notifiers.dart';
import '../common/widgets.dart';

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
          StatefulWithMixin(
            funcCalledInBuild: (context) {
              context.grabAt(
                changeNotifier,
                (TestChangeNotifier n) => selectorValue = n,
              );
            },
          ),
        );
        expect(selectorValue, equals(changeNotifier));
      },
    );

    testWidgets(
      'With ValueListenable, its value is passed to selector',
      (tester) async {
        valueNotifier.updateIntValue(10);

        Object? selectorValue;
        await tester.pumpWidget(
          StatefulWithMixin(
            funcCalledInBuild: (context) {
              context.grabAt(
                valueNotifier,
                (TestState s) => selectorValue = s,
              );
            },
          ),
        );
        expect(selectorValue, equals(valueNotifier.value));
      },
    );

    testWidgets(
      'Returns selected value',
      (tester) async {
        valueNotifier.updateIntValue(10);

        int? value;
        await tester.pumpWidget(
          StatefulWithMixin(
            funcCalledInBuild: (context) {
              value = context.grabAt(
                valueNotifier,
                (TestState s) => s.intValue,
              );
            },
          ),
        );
        expect(value, equals(10));
      },
    );

    testWidgets(
      'Rebuilds widget and returns latest value when listenable is updated',
      (tester) async {
        valueNotifier.updateIntValue(10);

        int? value;
        await tester.pumpWidget(
          StatefulWithMixin(
            funcCalledInBuild: (context) {
              value = context.grabAt(
                valueNotifier,
                (TestState s) => s.intValue,
              );
            },
          ),
        );

        valueNotifier.updateIntValue(20);
        await tester.pump();
        expect(value, equals(20));
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
          Column(
            children: [
              StatefulWithMixin(
                funcCalledInBuild: (context) {
                  value1 = context.grabAt(
                    changeNotifier,
                    (TestChangeNotifier n) => n.intValue,
                  );
                  buildCount1++;
                },
              ),
              StatefulWithMixin(
                funcCalledInBuild: (context) {
                  value2 = context.grabAt(
                    changeNotifier,
                    (TestChangeNotifier n) => n.stringValue,
                  );
                  buildCount2++;
                },
              ),
            ],
          ),
        );

        changeNotifier.updateIntValue(10);
        await tester.pump();
        expect(value1, equals(10));
        expect(value2, equals(''));
        expect(buildCount1, equals(2));
        expect(buildCount2, equals(1));

        changeNotifier.updateStringValue('abc');
        await tester.pump();
        expect(value1, equals(10));
        expect(value2, equals('abc'));
        expect(buildCount1, equals(2));
        expect(buildCount2, equals(2));

        changeNotifier.updateIntValue(20);
        await tester.pump();
        expect(value1, equals(20));
        expect(value2, equals('abc'));
        expect(buildCount1, equals(3));
        expect(buildCount2, equals(2));
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
          Column(
            children: [
              StatefulWithMixin(
                funcCalledInBuild: (context) {
                  value1 = context.grabAt(
                    valueNotifier,
                    (TestState s) => s.intValue,
                  );
                  buildCount1++;
                },
              ),
              StatefulWithMixin(
                funcCalledInBuild: (context) {
                  value2 = context.grabAt(
                    valueNotifier,
                    (TestState s) => s.stringValue,
                  );
                  buildCount2++;
                },
              ),
            ],
          ),
        );

        valueNotifier.updateIntValue(10);
        await tester.pump();
        expect(value1, equals(10));
        expect(value2, equals(''));
        expect(buildCount1, equals(2));
        expect(buildCount2, equals(1));

        valueNotifier.updateStringValue('abc');
        await tester.pump();
        expect(value1, equals(10));
        expect(value2, equals('abc'));
        expect(buildCount1, equals(2));
        expect(buildCount2, equals(2));

        valueNotifier.updateIntValue(20);
        await tester.pump();
        expect(value1, equals(20));
        expect(value2, equals('abc'));
        expect(buildCount1, equals(3));
        expect(buildCount2, equals(2));
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
          Column(
            children: [
              StatefulWithMixin(
                funcCalledInBuild: (context) {
                  final notifier = context.grabAt(
                    changeNotifier,
                    (TestChangeNotifier n) => n,
                  );
                  value1 = notifier.intValue;
                  buildCount1++;
                },
              ),
              StatefulWithMixin(
                funcCalledInBuild: (context) {
                  final notifier = context.grabAt(
                    changeNotifier,
                    (TestChangeNotifier n) => n,
                  );
                  value2 = notifier.stringValue;
                  buildCount2++;
                },
              ),
            ],
          ),
        );

        changeNotifier.updateIntValue(10);
        await tester.pump();
        expect(value1, equals(10));
        expect(value2, equals(''));
        expect(buildCount1, equals(2));
        expect(buildCount2, equals(2));

        changeNotifier.updateStringValue('abc');
        await tester.pump();
        expect(value1, equals(10));
        expect(value2, equals('abc'));
        expect(buildCount1, equals(3));
        expect(buildCount2, equals(3));
      },
    );

    testWidgets(
      'Returns new value on rebuild by other causes than listenable update too',
      (tester) async {
        valueNotifier.updateIntValue(10);
        var multiplier = 2;

        int? value;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (_, setState) => Column(
                children: [
                  StatefulWithMixin(
                    funcCalledInBuild: (context) {
                      value = context.grabAt(
                        valueNotifier,
                        (TestState s) => s.intValue * multiplier,
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
        );
        expect(value, equals(20));

        final buttonFinder = find.byType(ElevatedButton).first;
        await tester.tap(buttonFinder);
        await tester.pump();
        expect(value, equals(30));
      },
    );
  });
}
