import 'package:flutter/widgets.dart';
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

  group('Advanced', () {
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
            child: TestStatefulWidget(
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

        expect(value1, equals(10));
        expect(value2, equals(20));
        expect(buildCount, equals(1));

        changeNotifier.updateIntValue(11);
        valueNotifier.updateIntValue(12);
        await tester.pump();
        expect(value1, equals(11));
        expect(value2, equals(12));
        expect(buildCount, equals(2));
      },
    );

    testWidgets(
      "Switching order of grabAt's doesn't affect behaviour",
      (tester) async {
        valueNotifier
          ..updateIntValue(10)
          ..updateStringValue('abc');

        final swapNotifier = ValueNotifier(false);

        int? value1;
        String? value2;
        bool? isSwapped;
        var buildCount = 0;

        await tester.pumpWidget(
          Grab(
            child: ValueListenableBuilder<bool>(
              valueListenable: swapNotifier,
              builder: (_, swapped, __) => TestStatefulWidget(
                funcCalledInBuild: swapped
                    ? (context) {
                        value2 =
                            valueNotifier.grabAt(context, (s) => s.stringValue);
                        value1 =
                            valueNotifier.grabAt(context, (s) => s.intValue);
                        isSwapped = true;
                        buildCount++;
                      }
                    : (context) {
                        value1 =
                            valueNotifier.grabAt(context, (s) => s.intValue);
                        value2 =
                            valueNotifier.grabAt(context, (s) => s.stringValue);
                        isSwapped = false;
                        buildCount++;
                      },
              ),
            ),
          ),
        );

        expect(value1, equals(10));
        expect(value2, equals('abc'));
        expect(isSwapped, isFalse);
        expect(buildCount, 1);

        valueNotifier.updateIntValue(20);
        swapNotifier.value = true;
        await tester.pump();

        expect(value1, equals(20));
        expect(value2, equals('abc'));
        expect(isSwapped, isTrue);
        expect(buildCount, 2);

        valueNotifier.updateStringValue('def');
        swapNotifier.value = false;
        await tester.pump();

        expect(value1, equals(20));
        expect(value2, equals('def'));
        expect(isSwapped, isFalse);
        expect(buildCount, 3);

        swapNotifier.dispose();
      },
    );
  });
}
