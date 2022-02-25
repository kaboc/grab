import 'package:flutter_test/flutter_test.dart';

import '../common/notifiers.dart';
import '../common/stateful_widgets.dart';

void main() {
  late TestChangeNotifier changeNotifier;
  late TestValueNotifier valueNotifier;
  late FlagNotifier flagNotifier;

  setUp(() {
    changeNotifier = TestChangeNotifier();
    valueNotifier = TestValueNotifier();
    flagNotifier = FlagNotifier();
  });
  tearDown(() {
    changeNotifier.dispose();
    valueNotifier.dispose();
    flagNotifier.dispose();
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
          MultiListenablesStateful(
            listenable1: changeNotifier,
            listenable2: valueNotifier,
            selector1: (TestChangeNotifier notifier) => notifier.intValue,
            selector2: (TestState state) => state.intValue,
            onBuild: (int? v1, int? v2) {
              value1 = v1;
              value2 = v2;
              buildCount++;
            },
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

        int? value1;
        String? value2;
        bool? flag;

        await tester.pumpWidget(
          SwitchingOrderStateful(
            listenable: valueNotifier,
            flagNotifier: flagNotifier,
            selector1: (TestState state) => state.intValue,
            selector2: (TestState state) => state.stringValue,
            onBuild: (int? v1, String? v2, bool f) {
              value1 = v1;
              value2 = v2;
              flag = f;
            },
          ),
        );

        expect(value1, equals(10));
        expect(value2, equals('abc'));
        expect(flag, isFalse);

        valueNotifier.updateIntValue(20);
        flagNotifier.toggle();
        await tester.pump();
        expect(value1, equals(20));
        expect(value2, equals('abc'));
        expect(flag, isTrue);

        valueNotifier.updateStringValue('def');
        flagNotifier.toggle();
        await tester.pump();
        expect(value1, equals(20));
        expect(value2, equals('def'));
        expect(flag, isFalse);
      },
    );
  });
}
