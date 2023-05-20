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

  group('grab', () {
    testWidgets(
      'With non-ValueListenable, listenable itself is returned',
      (tester) async {
        Object? value;
        await tester.pumpWidget(
          StatefulWithMixin(
            funcCalledInBuild: (context) {
              value = context.grab(changeNotifier);
            },
          ),
        );
        expect(value, equals(changeNotifier));
      },
    );

    testWidgets(
      'With ValueListenable, its value is returned',
      (tester) async {
        Object? value;
        await tester.pumpWidget(
          StatefulWithMixin(
            funcCalledInBuild: (context) {
              value = context.grab(valueNotifier);
            },
          ),
        );
        expect(value, equals(valueNotifier.value));
      },
    );

    testWidgets(
      'Rebuilds widget whenever non-ValueListenable notifies',
      (tester) async {
        var intValue = 0;
        var stringValue = '';

        await tester.pumpWidget(
          StatefulWithMixin(
            funcCalledInBuild: (context) {
              context.grab<TestChangeNotifier>(changeNotifier);
              intValue = changeNotifier.intValue;
              stringValue = changeNotifier.stringValue;
            },
          ),
        );

        changeNotifier.updateIntValue(10);
        await tester.pump();
        expect(intValue, equals(10));
        expect(stringValue, equals(''));

        intValue = 0;

        changeNotifier.updateStringValue('abc');
        await tester.pump();
        expect(intValue, equals(10));
        expect(stringValue, equals('abc'));
      },
    );

    testWidgets(
      'Rebuilds widget when any property of ValueListenable value is updated',
      (tester) async {
        var state = const TestState();

        await tester.pumpWidget(
          StatefulWithMixin(
            funcCalledInBuild: (context) {
              state = context.grab(valueNotifier);
            },
          ),
        );

        valueNotifier.updateIntValue(10);
        await tester.pump();
        expect(state.intValue, equals(10));
        expect(state.stringValue, isEmpty);

        state = const TestState();

        valueNotifier.updateStringValue('abc');
        await tester.pump();
        expect(state.intValue, equals(10));
        expect(state.stringValue, equals('abc'));
      },
    );
  });
}
