import 'package:flutter_test/flutter_test.dart';

import '../common/notifiers.dart';
import '../common/stateful_widgets.dart';

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
      'With Non ValueListenable, listenable itself is passed to selector',
      (tester) async {
        Object? selectorValue;
        await tester.pumpWidget(
          GrabAtStateful(
            listenable: changeNotifier,
            selector: (value) => selectorValue = value,
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
          GrabAtStateful(
            listenable: valueNotifier,
            selector: (value) => selectorValue = value,
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
          GrabAtStateful(
            listenable: valueNotifier,
            selector: (TestState state) => state.intValue,
            onBuild: (int? v) => value = v,
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
          GrabAtStateful(
            listenable: valueNotifier,
            selector: (TestState state) => state.intValue,
            onBuild: (int? v) => value = v,
          ),
        );

        valueNotifier.updateIntValue(20);
        await tester.pump();
        expect(value, equals(20));
      },
    );

    testWidgets(
      'Rebuilds only widget that targets at updated value',
      (tester) async {
        int? value1;
        String? value2;
        var buildCount1 = 0;
        var buildCount2 = 0;

        await tester.pumpWidget(
          MultiGrabAtsStateful(
            listenable: valueNotifier,
            selector1: (TestState state) => state.intValue,
            selector2: (TestState state) => state.stringValue,
            onBuild1: (int? v) {
              value1 = v;
              buildCount1++;
            },
            onBuild2: (String? v) {
              value2 = v;
              buildCount2++;
            },
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
  });
}
