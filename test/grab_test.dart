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

  group('grab', () {
    testWidgets(
      'With non-ValueListenable, listenable itself is returned',
      (tester) async {
        Object? value;
        await tester.pumpWidget(
          Grab(
            child: TestStatelessWidget(
              funcCalledInBuild: (context) {
                value = changeNotifier.grab(context);
              },
            ),
          ),
        );
        expect(value, same(changeNotifier));
      },
    );

    testWidgets(
      'With ValueListenable, its value is returned',
      (tester) async {
        Object? value;
        await tester.pumpWidget(
          Grab(
            child: TestStatelessWidget(
              funcCalledInBuild: (context) {
                value = valueNotifier.grab(context);
              },
            ),
          ),
        );
        expect(value, same(valueNotifier.value));
      },
    );

    testWidgets(
      'Rebuilds widget whenever non-ValueListenable notifies',
      (tester) async {
        var intValue = 0;
        var stringValue = '';

        await tester.pumpWidget(
          Grab(
            child: TestStatelessWidget(
              funcCalledInBuild: (context) {
                changeNotifier.grab(context);
                intValue = changeNotifier.intValue;
                stringValue = changeNotifier.stringValue;
              },
            ),
          ),
        );

        changeNotifier.updateIntValue(10);
        await tester.pump();
        expect(intValue, 10);
        expect(stringValue, '');

        intValue = 0;

        changeNotifier.updateStringValue('abc');
        await tester.pump();
        expect(intValue, 10);
        expect(stringValue, 'abc');
      },
    );

    testWidgets(
      'Rebuilds widget when any property of ValueListenable value is updated',
      (tester) async {
        var state = const TestState();

        await tester.pumpWidget(
          Grab(
            child: TestStatelessWidget(
              funcCalledInBuild: (context) {
                state = valueNotifier.grab(context);
              },
            ),
          ),
        );

        valueNotifier.updateIntValue(10);
        await tester.pump();
        expect(state.intValue, 10);
        expect(state.stringValue, isEmpty);

        state = const TestState();

        valueNotifier.updateStringValue('abc');
        await tester.pump();
        expect(state.intValue, 10);
        expect(state.stringValue, 'abc');
      },
    );
  });
}
